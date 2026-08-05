-- BIOS Migration 006: Evidence & Provenance Foundation (DB-007 v1.4)

alter table bios_governance.audit_events drop constraint audit_resource_check;
alter table bios_governance.audit_events add constraint audit_resource_check check (resource_type ~ '^[a-z][a-z0-9_]*$' and resource_type in ('tenant','profile','tenant_membership','role','membership_role','platform','geography','geography_relationship','market','market_geography','market_group','market_group_member','language','market_language','domain','domain_node','domain_node_relationship','entity_type','entity','entity_alias','source','source_document','evidence','evidence_provenance'));

create table bios_knowledge.evidence (
 id uuid primary key default gen_random_uuid(),
 knowledge_scope text not null,
 tenant_id uuid references bios_core.tenants(id),
 evidence_text text not null,
 text_kind text not null,
 language_id uuid not null references bios_core.languages(id),
 access_classification text not null,
 valid_from timestamptz,
 valid_to timestamptz,
 supersedes_evidence_id uuid references bios_knowledge.evidence(id),
 status text not null default 'candidate',
 created_at timestamptz not null default transaction_timestamp(),
 updated_at timestamptz not null default transaction_timestamp(),
 activated_at timestamptz,
 superseded_at timestamptz,
 rejected_at timestamptz,
 archived_at timestamptz,
 constraint evidence_scope_check check (knowledge_scope in ('shared','tenant')),
 constraint evidence_tenant_check check ((knowledge_scope='shared' and tenant_id is null) or (knowledge_scope='tenant' and tenant_id is not null)),
 constraint evidence_text_check check (evidence_text=btrim(evidence_text) and char_length(evidence_text) between 1 and 2000),
 constraint evidence_text_kind_check check (text_kind in ('verbatim_excerpt','normalized_statement')),
 constraint evidence_access_check check (access_classification in ('public','licensed','tenant_confidential','restricted')),
 constraint evidence_validity_check check (valid_to is null or (valid_from is not null and valid_to>valid_from)),
 constraint evidence_self_successor_check check (supersedes_evidence_id is null or supersedes_evidence_id<>id),
 constraint evidence_status_check check (status in ('candidate','active','superseded','rejected','archived')),
 constraint evidence_lifecycle_check check (
  (status='candidate' and activated_at is null and superseded_at is null and rejected_at is null and archived_at is null) or
  (status='active' and activated_at is not null and superseded_at is null and rejected_at is null and archived_at is null) or
  (status='superseded' and activated_at is not null and superseded_at is not null and rejected_at is null and archived_at is null) or
  (status='rejected' and activated_at is null and superseded_at is null and rejected_at is not null and archived_at is null) or
  (status='archived' and superseded_at is null and rejected_at is null and archived_at is not null))
);
create unique index evidence_candidate_successor_uq on bios_knowledge.evidence(supersedes_evidence_id) where supersedes_evidence_id is not null and status='candidate';
create index evidence_scope_tenant_status_idx on bios_knowledge.evidence(knowledge_scope,tenant_id,status);
create index evidence_language_idx on bios_knowledge.evidence(language_id);

create table bios_knowledge.evidence_provenance (
 id uuid primary key default gen_random_uuid(),
 evidence_id uuid not null unique references bios_knowledge.evidence(id),
 source_document_id uuid not null references bios_knowledge.source_documents(id),
 anchor_kind text not null,
 page_start integer,
 page_end integer,
 section_label text,
 line_start integer,
 line_end integer,
 time_start_ms bigint,
 time_end_ms bigint,
 source_native_locator text,
 created_at timestamptz not null default transaction_timestamp(),
 constraint evidence_provenance_anchor_kind_check check (anchor_kind in ('document','page','section','line_range','time_range','source_native')),
 constraint evidence_provenance_anchor_check check (
  (anchor_kind='document' and page_start is null and page_end is null and section_label is null and line_start is null and line_end is null and time_start_ms is null and time_end_ms is null and source_native_locator is null) or
  (anchor_kind='page' and page_start>0 and (page_end is null or page_end>=page_start) and section_label is null and line_start is null and line_end is null and time_start_ms is null and time_end_ms is null and source_native_locator is null) or
  (anchor_kind='section' and section_label=btrim(section_label) and char_length(section_label) between 1 and 300 and page_start is null and page_end is null and line_start is null and line_end is null and time_start_ms is null and time_end_ms is null and source_native_locator is null) or
  (anchor_kind='line_range' and line_start>0 and line_end>=line_start and page_start is null and page_end is null and section_label is null and time_start_ms is null and time_end_ms is null and source_native_locator is null) or
  (anchor_kind='time_range' and time_start_ms>=0 and time_end_ms>time_start_ms and page_start is null and page_end is null and section_label is null and line_start is null and line_end is null and source_native_locator is null) or
  (anchor_kind='source_native' and source_native_locator=btrim(source_native_locator) and char_length(source_native_locator) between 1 and 500 and page_start is null and page_end is null and section_label is null and line_start is null and line_end is null and time_start_ms is null and time_end_ms is null))
);
create index evidence_provenance_document_idx on bios_knowledge.evidence_provenance(source_document_id);

create function bios_internal.guard_evidence_row() returns trigger language plpgsql set search_path='' as $$ begin
 if tg_op='DELETE' then raise exception 'Evidence foundation rows cannot be deleted'; end if;
 if new.id<>old.id or new.knowledge_scope<>old.knowledge_scope or new.tenant_id is distinct from old.tenant_id or new.supersedes_evidence_id is distinct from old.supersedes_evidence_id or new.created_at<>old.created_at then raise exception 'Evidence identity and ownership are immutable'; end if;
 if old.status<>'candidate' and (new.evidence_text<>old.evidence_text or new.text_kind<>old.text_kind or new.language_id<>old.language_id or new.access_classification<>old.access_classification or new.valid_from is distinct from old.valid_from or new.valid_to is distinct from old.valid_to) then raise exception 'active or historical Evidence material is immutable'; end if;
 new.updated_at=statement_timestamp(); return new;
end $$;
create trigger evidence_guard before update or delete on bios_knowledge.evidence for each row execute function bios_internal.guard_evidence_row();
create function bios_internal.guard_evidence_provenance_row() returns trigger language plpgsql set search_path='' as $$ begin raise exception 'Evidence provenance is immutable'; end $$;
create trigger evidence_provenance_guard before update or delete on bios_knowledge.evidence_provenance for each row execute function bios_internal.guard_evidence_provenance_row();

create function bios_internal.assert_evidence_context(p_actor_identifier text,p_correlation_id text,p_purpose text) returns void language plpgsql security definer set search_path='' as $$ begin
 if auth.role()<>'service_role' then raise exception 'trusted BIOS execution required'; end if;
 perform bios_internal.assert_reference_actor(p_actor_identifier);
 if p_correlation_id is null or p_correlation_id<>btrim(p_correlation_id) or char_length(p_correlation_id) not between 1 and 200 then raise exception 'invalid correlation_id'; end if;
 if p_purpose is null or p_purpose<>btrim(p_purpose) or char_length(p_purpose) not between 1 and 500 then raise exception 'invalid purpose'; end if;
end $$;

create function bios_internal.assert_evidence_provenance(p_source_document_id uuid,p_knowledge_scope text,p_target_tenant_id uuid,p_access_classification text,p_language_id uuid) returns void language plpgsql security definer set search_path='' as $$
declare d bios_knowledge.source_documents%rowtype; s bios_knowledge.sources%rowtype; begin
 select * into strict d from bios_knowledge.source_documents where id=p_source_document_id;
 select * into strict s from bios_knowledge.sources where id=d.source_id;
 if d.status<>'active' or s.status<>'active' then raise exception 'active Source and Source Document required'; end if;
 if not exists(select 1 from bios_core.languages where id=p_language_id and status='active') then raise exception 'active Language required'; end if;
 if d.knowledge_scope='shared' then
  if d.access_classification<>'public' then raise exception 'shared licensed or restricted provenance is not authorized'; end if;
  if p_knowledge_scope='shared' and p_target_tenant_id is not null then raise exception 'shared Evidence cannot have Tenant context'; end if;
  if p_knowledge_scope='tenant' and (p_target_tenant_id is null or not exists(select 1 from bios_core.tenants where id=p_target_tenant_id and status='active')) then raise exception 'active target Tenant required'; end if;
 elsif d.knowledge_scope='tenant' then
  if d.access_classification<>'tenant_confidential' or p_knowledge_scope<>'tenant' or p_target_tenant_id is null or p_target_tenant_id<>d.tenant_id then raise exception 'same-Tenant tenant-confidential provenance required'; end if;
 else raise exception 'unsupported Source Document scope'; end if;
 if (d.access_classification='public' and p_access_classification not in ('public','licensed','tenant_confidential','restricted')) or (d.access_classification='tenant_confidential' and p_access_classification not in ('tenant_confidential','restricted')) then raise exception 'Evidence cannot broaden provenance access'; end if;
 if p_knowledge_scope='shared' and p_access_classification not in ('public','restricted') then raise exception 'invalid shared Evidence classification'; end if;
end $$;

create function bios_internal.write_evidence_audit(p_tenant_id uuid,p_actor_identifier text,p_action text,p_resource_type text,p_resource_id uuid,p_metadata jsonb) returns void language plpgsql set search_path='' as $$ begin
 insert into bios_governance.audit_events(scope_type,tenant_id,actor_type,actor_identifier,action,resource_type,resource_id,outcome,correlation_id,metadata) values(case when p_tenant_id is null then 'platform' else 'tenant' end,p_tenant_id,'service',p_actor_identifier,p_action,p_resource_type,p_resource_id,'succeeded',gen_random_uuid(),p_metadata);
end $$;

create function bios_internal.create_evidence(
 p_knowledge_scope text,p_target_tenant_id uuid,p_evidence_text text,p_text_kind text,p_language_id uuid,p_access_classification text,p_valid_from timestamptz,p_valid_to timestamptz,p_supersedes_evidence_id uuid,
 p_source_document_id uuid,p_anchor_kind text,p_page_start integer,p_page_end integer,p_section_label text,p_line_start integer,p_line_end integer,p_time_start_ms bigint,p_time_end_ms bigint,p_source_native_locator text,
 p_actor_identifier text,p_correlation_id text,p_purpose text) returns uuid language plpgsql security definer set search_path='' as $$
declare v_id uuid; v_prov uuid; p bios_knowledge.evidence%rowtype; begin
 perform bios_internal.assert_evidence_context(p_actor_identifier,p_correlation_id,p_purpose);
 perform bios_internal.assert_evidence_provenance(p_source_document_id,p_knowledge_scope,p_target_tenant_id,p_access_classification,p_language_id);
 if p_supersedes_evidence_id is not null then
  perform pg_advisory_xact_lock(hashtextextended('bios_evidence_successor:'||p_supersedes_evidence_id::text,0));
  select * into strict p from bios_knowledge.evidence where id=p_supersedes_evidence_id for update;
  if p.status<>'active' or p.knowledge_scope<>p_knowledge_scope or p.tenant_id is distinct from p_target_tenant_id then raise exception 'incompatible active Evidence predecessor'; end if;
 end if;
 insert into bios_knowledge.evidence(knowledge_scope,tenant_id,evidence_text,text_kind,language_id,access_classification,valid_from,valid_to,supersedes_evidence_id)
 values(p_knowledge_scope,p_target_tenant_id,p_evidence_text,p_text_kind,p_language_id,p_access_classification,p_valid_from,p_valid_to,p_supersedes_evidence_id) returning id into v_id;
 insert into bios_knowledge.evidence_provenance(evidence_id,source_document_id,anchor_kind,page_start,page_end,section_label,line_start,line_end,time_start_ms,time_end_ms,source_native_locator)
 values(v_id,p_source_document_id,p_anchor_kind,p_page_start,p_page_end,p_section_label,p_line_start,p_line_end,p_time_start_ms,p_time_end_ms,p_source_native_locator) returning id into v_prov;
 perform bios_internal.write_evidence_audit(p_target_tenant_id,p_actor_identifier,'reference.created','evidence',v_id,jsonb_build_object('correlation_id',p_correlation_id,'purpose',p_purpose,'target_tenant_id',p_target_tenant_id,'supersedes_evidence_id',p_supersedes_evidence_id));
 perform bios_internal.write_evidence_audit(p_target_tenant_id,p_actor_identifier,'reference.created','evidence_provenance',v_prov,jsonb_build_object('correlation_id',p_correlation_id,'purpose',p_purpose,'target_tenant_id',p_target_tenant_id,'evidence_id',v_id,'source_document_id',p_source_document_id,'anchor_kind',p_anchor_kind));
 return v_id;
end $$;

create function bios_internal.update_evidence_candidate(p_id uuid,p_evidence_text text,p_text_kind text,p_language_id uuid,p_access_classification text,p_valid_from timestamptz,p_valid_to timestamptz,p_actor_identifier text,p_correlation_id text,p_purpose text) returns void language plpgsql security definer set search_path='' as $$
declare o bios_knowledge.evidence%rowtype; pr bios_knowledge.evidence_provenance%rowtype; c text[]; begin
 perform bios_internal.assert_evidence_context(p_actor_identifier,p_correlation_id,p_purpose);
 select * into strict o from bios_knowledge.evidence where id=p_id for update;
 if o.status<>'candidate' then raise exception 'only candidate Evidence is correctable'; end if;
 select * into strict pr from bios_knowledge.evidence_provenance where evidence_id=p_id;
 perform bios_internal.assert_evidence_provenance(pr.source_document_id,o.knowledge_scope,o.tenant_id,p_access_classification,p_language_id);
 c=array_remove(array[case when o.evidence_text<>p_evidence_text then 'evidence_text' end,case when o.text_kind<>p_text_kind then 'text_kind' end,case when o.language_id<>p_language_id then 'language_id' end,case when o.access_classification<>p_access_classification then 'access_classification' end,case when o.valid_from is distinct from p_valid_from then 'valid_from' end,case when o.valid_to is distinct from p_valid_to then 'valid_to' end],null);
 if cardinality(c)=0 then raise exception 'no Evidence correction'; end if;
 update bios_knowledge.evidence set evidence_text=p_evidence_text,text_kind=p_text_kind,language_id=p_language_id,access_classification=p_access_classification,valid_from=p_valid_from,valid_to=p_valid_to where id=p_id;
 perform bios_internal.write_evidence_audit(o.tenant_id,p_actor_identifier,'reference.metadata_updated','evidence',p_id,jsonb_build_object('correlation_id',p_correlation_id,'purpose',p_purpose,'target_tenant_id',o.tenant_id,'changed_fields',c));
end $$;

create function bios_internal.transition_evidence(p_id uuid,p_new_status text,p_actor_identifier text,p_correlation_id text,p_purpose text) returns void language plpgsql security definer set search_path='' as $$
declare o bios_knowledge.evidence%rowtype; pr bios_knowledge.evidence_provenance%rowtype; pred bios_knowledge.evidence%rowtype; now_at timestamptz=statement_timestamp(); begin
 perform bios_internal.assert_evidence_context(p_actor_identifier,p_correlation_id,p_purpose);
 select * into strict o from bios_knowledge.evidence where id=p_id;
 if o.supersedes_evidence_id is not null and p_new_status='active' then perform pg_advisory_xact_lock(hashtextextended('bios_evidence_successor:'||o.supersedes_evidence_id::text,0)); end if;
 select * into strict o from bios_knowledge.evidence where id=p_id for update;
 if not ((o.status='candidate' and p_new_status in ('active','rejected','archived')) or (o.status='active' and p_new_status='archived')) then raise exception 'invalid Evidence transition'; end if;
 if p_new_status='active' then select * into strict pr from bios_knowledge.evidence_provenance where evidence_id=p_id; perform bios_internal.assert_evidence_provenance(pr.source_document_id,o.knowledge_scope,o.tenant_id,o.access_classification,o.language_id); end if;
 update bios_knowledge.evidence set status=p_new_status,activated_at=case when p_new_status='active' then now_at else activated_at end,rejected_at=case when p_new_status='rejected' then now_at else rejected_at end,archived_at=case when p_new_status='archived' then now_at else archived_at end where id=p_id;
 perform bios_internal.write_evidence_audit(o.tenant_id,p_actor_identifier,'reference.status_changed','evidence',p_id,jsonb_build_object('correlation_id',p_correlation_id,'purpose',p_purpose,'target_tenant_id',o.tenant_id,'from_status',o.status,'to_status',p_new_status));
 if p_new_status='active' and o.supersedes_evidence_id is not null then
  select * into strict pred from bios_knowledge.evidence where id=o.supersedes_evidence_id for update;
  if pred.status<>'active' or pred.knowledge_scope<>o.knowledge_scope or pred.tenant_id is distinct from o.tenant_id then raise exception 'incompatible active Evidence predecessor'; end if;
  update bios_knowledge.evidence set status='superseded',superseded_at=now_at where id=pred.id;
  perform bios_internal.write_evidence_audit(pred.tenant_id,p_actor_identifier,'reference.status_changed','evidence',pred.id,jsonb_build_object('correlation_id',p_correlation_id,'purpose',p_purpose,'target_tenant_id',pred.tenant_id,'from_status','active','to_status','superseded','successor_evidence_id',p_id));
 end if;
end $$;

alter table bios_knowledge.evidence enable row level security;
alter table bios_knowledge.evidence_provenance enable row level security;
create policy evidence_authorized_read on bios_knowledge.evidence for select to authenticated using (
 status='active' and ((knowledge_scope='shared' and access_classification='public') or (knowledge_scope='tenant' and bios_internal.has_active_membership(tenant_id)))
 and exists(select 1 from bios_knowledge.evidence_provenance ep join bios_knowledge.source_documents d on d.id=ep.source_document_id where ep.evidence_id=evidence.id and d.status='active' and ((evidence.knowledge_scope='shared' and d.knowledge_scope='shared' and d.access_classification='public') or (evidence.knowledge_scope='tenant' and ((d.knowledge_scope='shared' and d.access_classification='public') or (d.knowledge_scope='tenant' and d.tenant_id=evidence.tenant_id and d.access_classification='tenant_confidential')))))
 or (knowledge_scope='tenant' and bios_internal.has_active_membership(tenant_id) and bios_internal.has_capability(tenant_id,'manage_memberships') and exists(select 1 from bios_knowledge.evidence_provenance ep join bios_knowledge.source_documents d on d.id=ep.source_document_id where ep.evidence_id=evidence.id and ((d.knowledge_scope='shared' and d.status='active' and d.access_classification='public') or (d.knowledge_scope='tenant' and d.tenant_id=evidence.tenant_id and d.status='active' and d.access_classification='tenant_confidential'))))
);
create policy evidence_provenance_authorized_read on bios_knowledge.evidence_provenance for select to authenticated using (exists(select 1 from bios_knowledge.evidence e where e.id=evidence_provenance.evidence_id));
grant usage on schema bios_knowledge to authenticated,service_role;
grant select on bios_knowledge.evidence,bios_knowledge.evidence_provenance to authenticated;
revoke all on all functions in schema bios_internal from public;
grant execute on function bios_internal.create_evidence(text,uuid,text,text,uuid,text,timestamptz,timestamptz,uuid,uuid,text,integer,integer,text,integer,integer,bigint,bigint,text,text,text,text),bios_internal.update_evidence_candidate(uuid,text,text,uuid,text,timestamptz,timestamptz,text,text,text),bios_internal.transition_evidence(uuid,text,text,text,text) to service_role;
