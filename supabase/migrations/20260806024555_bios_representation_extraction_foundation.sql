-- BIOS Migration 007: Representation & Extraction Foundation (DB-008 v1.2)
alter table bios_governance.audit_events drop constraint audit_resource_check;
alter table bios_governance.audit_events add constraint audit_resource_check check(resource_type ~ '^[a-z][a-z0-9_]*$' and resource_type in ('tenant','profile','tenant_membership','role','membership_role','platform','geography','geography_relationship','market','market_geography','market_group','market_group_member','language','market_language','domain','domain_node','domain_node_relationship','entity_type','entity','entity_alias','source','source_document','evidence','evidence_provenance','document_representation','processing_run'));

create function bios_internal.valid_processing_parameters(p jsonb) returns boolean language sql immutable set search_path='' as $$
 select jsonb_typeof(p)='object' and octet_length(p::text)<=8192 and not exists(select 1 from jsonb_each(p) e where char_length(e.key) not between 1 and 64 or e.key !~ '^[a-z][a-z0-9_]*$' or e.key in ('password','passwords','token','tokens','secret','secrets','credential','credentials','api_key','api_keys','authorization') or jsonb_typeof(e.value) not in ('string','number','boolean','null') or (jsonb_typeof(e.value)='string' and char_length(e.value#>>'{}')>500))
$$;

create table bios_knowledge.processing_runs(
 id uuid primary key default gen_random_uuid(), input_source_document_id uuid references bios_knowledge.source_documents(id), input_representation_id uuid,
 knowledge_scope text not null, tenant_id uuid references bios_core.tenants(id), operation_kind text not null,
 processor_identifier text not null, processor_version text not null, model_identifier text, model_version text, parameters jsonb not null default '{}',
 actor_identifier text not null, correlation_id text not null, purpose text not null, outcome text not null default 'running', error_code text, error_summary text,
 started_at timestamptz not null default transaction_timestamp(), completed_at timestamptz,
 constraint processing_runs_one_input_check check((input_source_document_id is null)<>(input_representation_id is null)),
 constraint processing_runs_scope_check check(knowledge_scope in ('shared','tenant')),
 constraint processing_runs_tenant_check check((knowledge_scope='shared' and tenant_id is null) or (knowledge_scope='tenant' and tenant_id is not null)),
 constraint processing_runs_operation_check check(operation_kind in ('extract_text','ocr','transcribe','normalize','translate')),
 constraint processing_runs_processor_check check(processor_identifier=btrim(processor_identifier) and char_length(processor_identifier) between 1 and 200 and processor_version=btrim(processor_version) and char_length(processor_version) between 1 and 100),
 constraint processing_runs_model_check check((model_identifier is null and model_version is null) or (model_identifier=btrim(model_identifier) and char_length(model_identifier) between 1 and 200 and model_version=btrim(model_version) and char_length(model_version) between 1 and 100)),
 constraint processing_runs_parameters_check check(bios_internal.valid_processing_parameters(parameters)),
 constraint processing_runs_context_check check(actor_identifier=btrim(actor_identifier) and char_length(actor_identifier) between 1 and 200 and correlation_id=btrim(correlation_id) and char_length(correlation_id) between 1 and 200 and purpose=btrim(purpose) and char_length(purpose) between 1 and 500),
 constraint processing_runs_outcome_check check(outcome in ('running','succeeded','failed','cancelled')),
 constraint processing_runs_lifecycle_check check((outcome='running' and completed_at is null and error_code is null and error_summary is null) or (outcome='succeeded' and completed_at is not null and error_code is null and error_summary is null) or (outcome='cancelled' and completed_at is not null and error_code is null and error_summary is null) or (outcome='failed' and completed_at is not null and error_code=btrim(error_code) and char_length(error_code) between 1 and 100 and (error_summary is null or (error_summary=btrim(error_summary) and char_length(error_summary) between 1 and 500))))
);

create table bios_knowledge.document_representations(
 id uuid primary key default gen_random_uuid(), source_document_id uuid not null references bios_knowledge.source_documents(id), parent_representation_id uuid references bios_knowledge.document_representations(id), producing_run_id uuid not null unique references bios_knowledge.processing_runs(id),
 knowledge_scope text not null, tenant_id uuid references bios_core.tenants(id), representation_kind text not null, language_id uuid not null references bios_core.languages(id), media_type text not null,
 content_text text not null, content_sha256 text not null, access_classification text not null, supersedes_representation_id uuid references bios_knowledge.document_representations(id), status text not null default 'candidate',
 created_at timestamptz not null default transaction_timestamp(), updated_at timestamptz not null default transaction_timestamp(), activated_at timestamptz, superseded_at timestamptz, archived_at timestamptz,
 constraint document_representations_scope_check check(knowledge_scope in ('shared','tenant')),
 constraint document_representations_tenant_check check((knowledge_scope='shared' and tenant_id is null) or (knowledge_scope='tenant' and tenant_id is not null)),
 constraint document_representations_kind_check check(representation_kind in ('extracted_text','ocr_text','transcript','normalized_text','translated_text')),
 constraint document_representations_media_check check(media_type in ('text/plain','text/markdown','text/html')),
 constraint document_representations_content_check check(octet_length(convert_to(content_text,'UTF8')) between 1 and 1048576),
 constraint document_representations_digest_check check(content_sha256 ~ '^[0-9a-f]{64}$' and content_sha256=encode(digest(convert_to(content_text,'UTF8'),'sha256'),'hex')),
 constraint document_representations_access_check check(access_classification in ('public','licensed','tenant_confidential','restricted') and not(knowledge_scope='shared' and access_classification='tenant_confidential')),
 constraint document_representations_self_check check(parent_representation_id is distinct from id and supersedes_representation_id is distinct from id),
 constraint document_representations_status_check check(status in ('candidate','active','superseded','archived')),
 constraint document_representations_lifecycle_check check((status='candidate' and activated_at is null and superseded_at is null and archived_at is null) or (status='active' and activated_at is not null and superseded_at is null and archived_at is null) or (status='superseded' and activated_at is not null and superseded_at is not null and archived_at is null) or (status='archived' and superseded_at is null and archived_at is not null))
);
alter table bios_knowledge.processing_runs add constraint processing_runs_input_representation_fk foreign key(input_representation_id) references bios_knowledge.document_representations(id);
create unique index document_representations_candidate_successor_uq on bios_knowledge.document_representations(supersedes_representation_id) where supersedes_representation_id is not null and status='candidate';
create index document_representations_root_idx on bios_knowledge.document_representations(source_document_id);
create index document_representations_parent_idx on bios_knowledge.document_representations(parent_representation_id);
create index document_representations_scope_status_idx on bios_knowledge.document_representations(knowledge_scope,tenant_id,status);
create index document_representations_language_idx on bios_knowledge.document_representations(language_id);
create index document_representations_digest_idx on bios_knowledge.document_representations(content_sha256);
create index processing_runs_source_input_idx on bios_knowledge.processing_runs(input_source_document_id);
create index processing_runs_representation_input_idx on bios_knowledge.processing_runs(input_representation_id);
create index processing_runs_scope_outcome_idx on bios_knowledge.processing_runs(knowledge_scope,tenant_id,outcome);

create function bios_internal.guard_processing_run() returns trigger language plpgsql set search_path='' as $$
begin
 if tg_op='DELETE' then raise exception 'Representation foundation rows cannot be deleted'; end if;
 if old.outcome<>'running' then raise exception 'terminal Processing Run is immutable'; end if;
 if new.id<>old.id or new.input_source_document_id is distinct from old.input_source_document_id or new.input_representation_id is distinct from old.input_representation_id or new.knowledge_scope<>old.knowledge_scope or new.tenant_id is distinct from old.tenant_id or new.operation_kind<>old.operation_kind or new.processor_identifier<>old.processor_identifier or new.processor_version<>old.processor_version or new.model_identifier is distinct from old.model_identifier or new.model_version is distinct from old.model_version or new.parameters<>old.parameters or new.actor_identifier<>old.actor_identifier or new.correlation_id<>old.correlation_id or new.purpose<>old.purpose or new.started_at<>old.started_at then raise exception 'Processing Run definition is immutable'; end if;
 return new;
end $$;
create trigger processing_runs_guard before update or delete on bios_knowledge.processing_runs for each row execute function bios_internal.guard_processing_run();

create function bios_internal.guard_document_representation() returns trigger language plpgsql set search_path='' as $$
begin
 if tg_op='DELETE' then raise exception 'Representation foundation rows cannot be deleted'; end if;
 if new.id<>old.id or new.source_document_id<>old.source_document_id or new.parent_representation_id is distinct from old.parent_representation_id or new.producing_run_id<>old.producing_run_id or new.knowledge_scope<>old.knowledge_scope or new.tenant_id is distinct from old.tenant_id or new.representation_kind<>old.representation_kind or new.language_id<>old.language_id or new.media_type<>old.media_type or new.content_text<>old.content_text or new.content_sha256<>old.content_sha256 or new.access_classification<>old.access_classification or new.supersedes_representation_id is distinct from old.supersedes_representation_id or new.created_at<>old.created_at then raise exception 'Representation material and lineage are immutable'; end if;
 new.updated_at=statement_timestamp(); return new;
end $$;
create trigger document_representations_guard before update or delete on bios_knowledge.document_representations for each row execute function bios_internal.guard_document_representation();

create function bios_internal.assert_processing_input(p_input_source_document_id uuid,p_input_representation_id uuid,p_knowledge_scope text,p_tenant_id uuid,p_operation_kind text) returns uuid language plpgsql security definer set search_path='' as $$
declare d bios_knowledge.source_documents%rowtype; s bios_knowledge.sources%rowtype; p bios_knowledge.document_representations%rowtype; root_id uuid;
begin
 if (p_input_source_document_id is null)=(p_input_representation_id is null) then raise exception 'exactly one processing input required'; end if;
 if p_input_source_document_id is not null then
  if p_operation_kind not in ('extract_text','ocr','transcribe') then raise exception 'operation requires Representation input'; end if;
  select * into strict d from bios_knowledge.source_documents where id=p_input_source_document_id;
  select * into strict s from bios_knowledge.sources where id=d.source_id;
  root_id=d.id;
 else
  if p_operation_kind not in ('normalize','translate') then raise exception 'operation requires Source Document input'; end if;
  select * into strict p from bios_knowledge.document_representations where id=p_input_representation_id;
  if p.status<>'active' then raise exception 'active parent Representation required'; end if;
  select * into strict d from bios_knowledge.source_documents where id=p.source_document_id;
  select * into strict s from bios_knowledge.sources where id=d.source_id;
  root_id=d.id;
  if p.knowledge_scope='tenant' and (p_knowledge_scope<>'tenant' or p_tenant_id is distinct from p.tenant_id) then raise exception 'same-Tenant parent required'; end if;
  if p.knowledge_scope='shared' and p.access_classification<>'public' then raise exception 'public shared parent required'; end if;
 end if;
 if d.status<>'active' or s.status<>'active' then raise exception 'active Source and Source Document required'; end if;
 if d.knowledge_scope='shared' then
  if d.access_classification<>'public' then raise exception 'shared licensed or restricted processing is not authorized'; end if;
  if p_knowledge_scope='shared' and p_tenant_id is not null then raise exception 'shared processing cannot have Tenant context'; end if;
  if p_knowledge_scope='tenant' and (p_tenant_id is null or not exists(select 1 from bios_core.tenants where id=p_tenant_id and status='active')) then raise exception 'active target Tenant required'; end if;
 elsif d.knowledge_scope='tenant' then
  if d.access_classification<>'tenant_confidential' or p_knowledge_scope<>'tenant' or p_tenant_id is null or p_tenant_id<>d.tenant_id then raise exception 'same-Tenant tenant-confidential processing required'; end if;
 end if;
 return root_id;
end $$;

create function bios_internal.start_processing_run(p_input_source_document_id uuid,p_input_representation_id uuid,p_knowledge_scope text,p_target_tenant_id uuid,p_operation_kind text,p_processor_identifier text,p_processor_version text,p_model_identifier text,p_model_version text,p_parameters jsonb,p_actor_identifier text,p_correlation_id text,p_purpose text) returns uuid language plpgsql security definer set search_path='' as $$
declare v uuid; root_id uuid;
begin
 perform bios_internal.assert_evidence_context(p_actor_identifier,p_correlation_id,p_purpose);
 root_id=bios_internal.assert_processing_input(p_input_source_document_id,p_input_representation_id,p_knowledge_scope,p_target_tenant_id,p_operation_kind);
 insert into bios_knowledge.processing_runs(input_source_document_id,input_representation_id,knowledge_scope,tenant_id,operation_kind,processor_identifier,processor_version,model_identifier,model_version,parameters,actor_identifier,correlation_id,purpose)
 values(p_input_source_document_id,p_input_representation_id,p_knowledge_scope,p_target_tenant_id,p_operation_kind,p_processor_identifier,p_processor_version,p_model_identifier,p_model_version,coalesce(p_parameters,'{}'),p_actor_identifier,p_correlation_id,p_purpose) returning id into v;
 perform bios_internal.write_evidence_audit(p_target_tenant_id,p_actor_identifier,'reference.created','processing_run',v,jsonb_build_object('correlation_id',p_correlation_id,'purpose',p_purpose,'target_tenant_id',p_target_tenant_id,'operation_kind',p_operation_kind));
 return v;
end $$;

create function bios_internal.complete_processing_run_success(p_run_id uuid,p_language_id uuid,p_media_type text,p_content_text text,p_content_sha256 text,p_access_classification text,p_supersedes_representation_id uuid,p_actor_identifier text,p_correlation_id text,p_purpose text) returns uuid language plpgsql security definer set search_path='' as $$
declare r bios_knowledge.processing_runs%rowtype; parent bios_knowledge.document_representations%rowtype; pred bios_knowledge.document_representations%rowtype; d bios_knowledge.source_documents%rowtype; root_id uuid; kind text; v uuid; now_at timestamptz=statement_timestamp();
begin
 perform bios_internal.assert_evidence_context(p_actor_identifier,p_correlation_id,p_purpose);
 select * into strict r from bios_knowledge.processing_runs where id=p_run_id for update;
 if r.outcome<>'running' then raise exception 'Processing Run is terminal'; end if;
 if octet_length(convert_to(p_content_text,'UTF8'))>1048576 then
  update bios_knowledge.processing_runs set outcome='failed',error_code='content_too_large',error_summary='Output exceeds Migration 007 PostgreSQL text bound',completed_at=now_at where id=p_run_id;
  perform bios_internal.write_evidence_audit(r.tenant_id,p_actor_identifier,'reference.status_changed','processing_run',p_run_id,jsonb_build_object('correlation_id',p_correlation_id,'purpose',p_purpose,'target_tenant_id',r.tenant_id,'from_status','running','to_status','failed','error_code','content_too_large'));
  return null;
 end if;
 root_id=bios_internal.assert_processing_input(r.input_source_document_id,r.input_representation_id,r.knowledge_scope,r.tenant_id,r.operation_kind);
 select * into strict d from bios_knowledge.source_documents where id=root_id;
 if not exists(select 1 from bios_core.languages where id=p_language_id and status='active') then raise exception 'active Language required'; end if;
 if r.input_source_document_id is not null then
  if d.language_mode='single' and d.language_id<>p_language_id then raise exception 'direct output Language must match Source Document'; end if;
  kind=case r.operation_kind when 'extract_text' then 'extracted_text' when 'ocr' then 'ocr_text' when 'transcribe' then 'transcript' end;
 else
  select * into strict parent from bios_knowledge.document_representations where id=r.input_representation_id;
  if r.operation_kind='normalize' and p_language_id<>parent.language_id then raise exception 'normalization Language must match parent'; end if;
  if r.operation_kind='translate' and p_language_id=parent.language_id then raise exception 'translation Language must differ from parent'; end if;
  if parent.source_document_id<>root_id or parent.knowledge_scope<>r.knowledge_scope or parent.tenant_id is distinct from r.tenant_id then raise exception 'incompatible parent lineage'; end if;
  kind=case r.operation_kind when 'normalize' then 'normalized_text' when 'translate' then 'translated_text' end;
 end if;
 if r.knowledge_scope='shared' and p_access_classification not in ('public','restricted') then raise exception 'invalid shared Representation classification'; end if;
 if d.knowledge_scope='tenant' and p_access_classification not in ('tenant_confidential','restricted') then raise exception 'Representation cannot broaden root access'; end if;
 if r.input_representation_id is not null and ((parent.access_classification='licensed' and p_access_classification not in ('licensed','tenant_confidential','restricted')) or (parent.access_classification='tenant_confidential' and p_access_classification not in ('tenant_confidential','restricted')) or (parent.access_classification='restricted' and p_access_classification<>'restricted')) then raise exception 'Representation cannot broaden parent access'; end if;
 if p_supersedes_representation_id is not null then
  perform pg_advisory_xact_lock(hashtextextended('bios_representation_successor:'||p_supersedes_representation_id::text,0));
  select * into strict pred from bios_knowledge.document_representations where id=p_supersedes_representation_id for update;
  if pred.status<>'active' or pred.source_document_id<>root_id or pred.representation_kind<>kind or pred.language_id<>p_language_id or pred.knowledge_scope<>r.knowledge_scope or pred.tenant_id is distinct from r.tenant_id then raise exception 'incompatible active Representation predecessor'; end if;
 end if;
 insert into bios_knowledge.document_representations(source_document_id,parent_representation_id,producing_run_id,knowledge_scope,tenant_id,representation_kind,language_id,media_type,content_text,content_sha256,access_classification,supersedes_representation_id)
 values(root_id,r.input_representation_id,p_run_id,r.knowledge_scope,r.tenant_id,kind,p_language_id,p_media_type,p_content_text,p_content_sha256,p_access_classification,p_supersedes_representation_id) returning id into v;
 update bios_knowledge.processing_runs set outcome='succeeded',completed_at=now_at where id=p_run_id;
 perform bios_internal.write_evidence_audit(r.tenant_id,p_actor_identifier,'reference.created','document_representation',v,jsonb_build_object('correlation_id',p_correlation_id,'purpose',p_purpose,'target_tenant_id',r.tenant_id,'processing_run_id',p_run_id,'source_document_id',root_id,'parent_representation_id',r.input_representation_id,'supersedes_representation_id',p_supersedes_representation_id));
 perform bios_internal.write_evidence_audit(r.tenant_id,p_actor_identifier,'reference.status_changed','processing_run',p_run_id,jsonb_build_object('correlation_id',p_correlation_id,'purpose',p_purpose,'target_tenant_id',r.tenant_id,'from_status','running','to_status','succeeded','document_representation_id',v));
 return v;
end $$;

create function bios_internal.complete_processing_run_terminal(p_run_id uuid,p_outcome text,p_error_code text,p_error_summary text,p_actor_identifier text,p_correlation_id text,p_purpose text) returns void language plpgsql security definer set search_path='' as $$
declare r bios_knowledge.processing_runs%rowtype;
begin
 perform bios_internal.assert_evidence_context(p_actor_identifier,p_correlation_id,p_purpose);
 select * into strict r from bios_knowledge.processing_runs where id=p_run_id for update;
 if r.outcome<>'running' or p_outcome not in ('failed','cancelled') then raise exception 'invalid Processing Run transition'; end if;
 update bios_knowledge.processing_runs set outcome=p_outcome,error_code=case when p_outcome='failed' then p_error_code end,error_summary=case when p_outcome='failed' then p_error_summary end,completed_at=statement_timestamp() where id=p_run_id;
 perform bios_internal.write_evidence_audit(r.tenant_id,p_actor_identifier,'reference.status_changed','processing_run',p_run_id,jsonb_build_object('correlation_id',p_correlation_id,'purpose',p_purpose,'target_tenant_id',r.tenant_id,'from_status','running','to_status',p_outcome,'error_code',case when p_outcome='failed' then p_error_code end));
end $$;

create function bios_internal.transition_document_representation(p_id uuid,p_new_status text,p_actor_identifier text,p_correlation_id text,p_purpose text) returns void language plpgsql security definer set search_path='' as $$
declare o bios_knowledge.document_representations%rowtype; pred bios_knowledge.document_representations%rowtype; r bios_knowledge.processing_runs%rowtype; now_at timestamptz=statement_timestamp();
begin
 perform bios_internal.assert_evidence_context(p_actor_identifier,p_correlation_id,p_purpose);
 select * into strict o from bios_knowledge.document_representations where id=p_id;
 if o.supersedes_representation_id is not null and p_new_status='active' then perform pg_advisory_xact_lock(hashtextextended('bios_representation_successor:'||o.supersedes_representation_id::text,0)); end if;
 select * into strict o from bios_knowledge.document_representations where id=p_id for update;
 if not ((o.status='candidate' and p_new_status in ('active','archived')) or (o.status='active' and p_new_status='archived')) then raise exception 'invalid Representation transition'; end if;
 if p_new_status='active' then
  select * into strict r from bios_knowledge.processing_runs where id=o.producing_run_id;
  if r.outcome<>'succeeded' then raise exception 'succeeded producing Run required'; end if;
  perform bios_internal.assert_processing_input(r.input_source_document_id,r.input_representation_id,r.knowledge_scope,r.tenant_id,r.operation_kind);
  if not exists(select 1 from bios_core.languages where id=o.language_id and status='active') then raise exception 'active Language required'; end if;
 end if;
 update bios_knowledge.document_representations set status=p_new_status,activated_at=case when p_new_status='active' then now_at else activated_at end,archived_at=case when p_new_status='archived' then now_at end where id=p_id;
 perform bios_internal.write_evidence_audit(o.tenant_id,p_actor_identifier,'reference.status_changed','document_representation',p_id,jsonb_build_object('correlation_id',p_correlation_id,'purpose',p_purpose,'target_tenant_id',o.tenant_id,'from_status',o.status,'to_status',p_new_status));
 if p_new_status='active' and o.supersedes_representation_id is not null then
  select * into strict pred from bios_knowledge.document_representations where id=o.supersedes_representation_id for update;
  if pred.status<>'active' or pred.source_document_id<>o.source_document_id or pred.representation_kind<>o.representation_kind or pred.language_id<>o.language_id or pred.knowledge_scope<>o.knowledge_scope or pred.tenant_id is distinct from o.tenant_id then raise exception 'incompatible active Representation predecessor'; end if;
  update bios_knowledge.document_representations set status='superseded',superseded_at=now_at where id=pred.id;
  perform bios_internal.write_evidence_audit(pred.tenant_id,p_actor_identifier,'reference.status_changed','document_representation',pred.id,jsonb_build_object('correlation_id',p_correlation_id,'purpose',p_purpose,'target_tenant_id',pred.tenant_id,'from_status','active','to_status','superseded','successor_representation_id',p_id));
 end if;
end $$;

alter table bios_knowledge.document_representations enable row level security;
alter table bios_knowledge.processing_runs enable row level security;
create policy document_representations_authorized_read on bios_knowledge.document_representations for select to authenticated using(status='active' and bios_internal.current_profile_id() is not null and ((knowledge_scope='shared' and access_classification='public' and exists(select 1 from bios_knowledge.source_documents d where d.id=document_representations.source_document_id and d.status='active' and d.knowledge_scope='shared' and d.access_classification='public')) or (knowledge_scope='tenant' and bios_internal.has_active_membership(tenant_id) and exists(select 1 from bios_knowledge.source_documents d where d.id=document_representations.source_document_id and d.status='active' and ((d.knowledge_scope='shared' and d.access_classification='public') or (d.knowledge_scope='tenant' and d.tenant_id=document_representations.tenant_id and d.access_classification='tenant_confidential'))))));
grant usage on schema bios_knowledge to authenticated,service_role;
grant select on bios_knowledge.document_representations to authenticated;
revoke all on all functions in schema bios_internal from public;
grant execute on function bios_internal.start_processing_run(uuid,uuid,text,uuid,text,text,text,text,text,jsonb,text,text,text),bios_internal.complete_processing_run_success(uuid,uuid,text,text,text,text,uuid,text,text,text),bios_internal.complete_processing_run_terminal(uuid,text,text,text,text,text,text),bios_internal.transition_document_representation(uuid,text,text,text,text) to service_role;

comment on column bios_knowledge.document_representations.content_text is 'Immutable UTF-8 text; Migration 007 operational PostgreSQL limit is 1,048,576 bytes.';
