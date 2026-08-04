-- DB-006 v1.3: BIOS Migration 005 -- Source & Document Foundation

alter table bios_governance.audit_events
  drop constraint audit_resource_check,
  add constraint audit_resource_check check (resource_type ~ '^[a-z][a-z0-9_]*$' and resource_type in (
    'tenant','profile','tenant_membership','role','membership_role','platform','geography','geography_relationship',
    'market','market_geography','market_group','market_group_member','language','market_language',
    'domain','domain_node','domain_node_relationship','entity_type','entity','entity_alias','source','source_document'
  ));

create table bios_knowledge.sources (
  id uuid primary key default gen_random_uuid(),
  code text not null,
  canonical_name text not null,
  description text,
  canonical_origin_uri text,
  knowledge_scope text not null,
  tenant_id uuid references bios_core.tenants(id) on delete restrict,
  status text not null default 'candidate',
  created_at timestamptz not null default transaction_timestamp(),
  updated_at timestamptz not null default transaction_timestamp(),
  activated_at timestamptz,
  deprecated_at timestamptz,
  constraint sources_code_check check(code ~ '^[a-z][a-z0-9_]{1,62}[a-z0-9]$'),
  constraint sources_name_check check(canonical_name=btrim(canonical_name) and char_length(canonical_name) between 1 and 200),
  constraint sources_description_check check(description is null or (description=btrim(description) and char_length(description) between 1 and 1000)),
  constraint sources_origin_uri_check check(canonical_origin_uri is null or (canonical_origin_uri=btrim(canonical_origin_uri) and char_length(canonical_origin_uri) between 1 and 2048)),
  constraint sources_scope_check check((knowledge_scope='shared' and tenant_id is null) or (knowledge_scope='tenant' and tenant_id is not null)),
  constraint sources_status_check check(status in ('candidate','active','deprecated')),
  constraint sources_lifecycle_check check(
    (status='candidate' and activated_at is null and deprecated_at is null) or
    (status='active' and activated_at is not null and deprecated_at is null) or
    (status='deprecated' and deprecated_at is not null)
  )
);
create unique index sources_shared_code_uq on bios_knowledge.sources(code) where knowledge_scope='shared';
create unique index sources_tenant_code_uq on bios_knowledge.sources(tenant_id,code) where knowledge_scope='tenant';
create index sources_scope_status_idx on bios_knowledge.sources(knowledge_scope,tenant_id,status);
create index sources_name_lower_idx on bios_knowledge.sources(lower(canonical_name));

create table bios_knowledge.source_documents (
  id uuid primary key default gen_random_uuid(),
  source_id uuid not null references bios_knowledge.sources(id) on delete restrict,
  knowledge_scope text not null,
  tenant_id uuid references bios_core.tenants(id) on delete restrict,
  document_identifier text,
  canonical_title text not null,
  description text,
  locator_scheme text,
  canonical_locator text,
  published_at timestamptz,
  language_mode text not null default 'unknown',
  language_id uuid references bios_core.languages(id) on delete restrict,
  media_type text,
  content_sha256 text,
  access_classification text not null,
  restriction_note text,
  supersedes_document_id uuid references bios_knowledge.source_documents(id) on delete restrict,
  status text not null default 'candidate',
  created_at timestamptz not null default transaction_timestamp(),
  updated_at timestamptz not null default transaction_timestamp(),
  activated_at timestamptz,
  superseded_at timestamptz,
  archived_at timestamptz,
  constraint source_documents_scope_check check((knowledge_scope='shared' and tenant_id is null) or (knowledge_scope='tenant' and tenant_id is not null)),
  constraint source_documents_identifier_check check(document_identifier is null or (document_identifier=btrim(document_identifier) and char_length(document_identifier) between 1 and 300)),
  constraint source_documents_title_check check(canonical_title=btrim(canonical_title) and char_length(canonical_title) between 1 and 500),
  constraint source_documents_description_check check(description is null or (description=btrim(description) and char_length(description) between 1 and 1000)),
  constraint source_documents_locator_check check((locator_scheme is null and canonical_locator is null) or (locator_scheme in ('url','doi','accession','report_number','source_local','other') and canonical_locator is not null and canonical_locator=btrim(canonical_locator) and char_length(canonical_locator) between 1 and 2048)),
  constraint source_documents_language_check check((language_mode='single' and language_id is not null) or (language_mode in ('unknown','multiple') and language_id is null)),
  constraint source_documents_media_type_check check(media_type is null or (char_length(media_type) between 3 and 255 and media_type ~ '^[a-z0-9][a-z0-9!#$&^_.+\-]*/[a-z0-9][a-z0-9!#$&^_.+\-]*$')),
  constraint source_documents_digest_check check(content_sha256 is null or content_sha256 ~ '^[0-9a-f]{64}$'),
  constraint source_documents_access_check check(access_classification in ('public','licensed','tenant_confidential','restricted') and not (knowledge_scope='shared' and access_classification='tenant_confidential')),
  constraint source_documents_note_check check(restriction_note is null or (restriction_note=btrim(restriction_note) and char_length(restriction_note) between 1 and 1000)),
  constraint source_documents_status_check check(status in ('candidate','active','superseded','archived')),
  constraint source_documents_not_self_check check(supersedes_document_id is null or supersedes_document_id<>id),
  constraint source_documents_lifecycle_check check(
    (status='candidate' and activated_at is null and superseded_at is null and archived_at is null) or
    (status='active' and activated_at is not null and superseded_at is null and archived_at is null) or
    (status='superseded' and activated_at is not null and superseded_at is not null and archived_at is null) or
    (status='archived' and superseded_at is null and archived_at is not null)
  )
);
create unique index source_documents_shared_identifier_uq on bios_knowledge.source_documents(source_id,document_identifier) where knowledge_scope='shared' and document_identifier is not null;
create unique index source_documents_tenant_identifier_uq on bios_knowledge.source_documents(source_id,tenant_id,document_identifier) where knowledge_scope='tenant' and document_identifier is not null;
create unique index source_documents_candidate_successor_uq on bios_knowledge.source_documents(supersedes_document_id) where status='candidate' and supersedes_document_id is not null;
create index source_documents_source_status_idx on bios_knowledge.source_documents(source_id,status);
create index source_documents_scope_status_idx on bios_knowledge.source_documents(knowledge_scope,tenant_id,status);
create index source_documents_title_lower_idx on bios_knowledge.source_documents(lower(canonical_title));
create index source_documents_language_idx on bios_knowledge.source_documents(language_id) where language_id is not null;
create index source_documents_digest_idx on bios_knowledge.source_documents(content_sha256) where content_sha256 is not null;

create function bios_internal.touch_source_updated_at() returns trigger language plpgsql set search_path='' as $$ begin new.updated_at=statement_timestamp(); return new; end $$;
create function bios_internal.reject_source_delete() returns trigger language plpgsql set search_path='' as $$ begin raise exception 'Source foundation rows cannot be deleted'; end $$;

create function bios_internal.govern_source_row() returns trigger language plpgsql set search_path='' as $$
begin
  if new.id<>old.id or new.code<>old.code or new.knowledge_scope<>old.knowledge_scope or new.tenant_id is distinct from old.tenant_id or new.created_at<>old.created_at then raise exception 'Source identity and ownership are immutable'; end if;
  if old.status='deprecated' and new.status<>old.status then raise exception 'deprecated Source is terminal'; end if;
  if new.status<>old.status and not ((old.status='candidate' and new.status in ('active','deprecated')) or (old.status='active' and new.status='deprecated')) then raise exception 'invalid Source transition'; end if;
  if new.status='deprecated' and old.status<>new.status and exists(select 1 from bios_knowledge.source_documents d where d.source_id=old.id and d.status in ('candidate','active')) then raise exception 'Source has candidate or active Documents'; end if;
  if (new.activated_at is distinct from old.activated_at or new.deprecated_at is distinct from old.deprecated_at) and new.status=old.status then raise exception 'Source lifecycle timestamps are governed'; end if;
  return new;
end $$;

create function bios_internal.govern_source_document_row() returns trigger language plpgsql set search_path='' as $$
declare s bios_knowledge.sources%rowtype; p bios_knowledge.source_documents%rowtype;
begin
  select * into strict s from bios_knowledge.sources where id=new.source_id;
  if new.knowledge_scope='shared' and (s.knowledge_scope<>'shared' or new.tenant_id is not null) then raise exception 'shared Document requires shared Source'; end if;
  if new.knowledge_scope='tenant' and s.knowledge_scope='tenant' and s.tenant_id<>new.tenant_id then raise exception 'cross-Tenant Source is prohibited'; end if;
  if tg_op='INSERT' then
    if new.status<>'candidate' or s.status='deprecated' then raise exception 'new Document requires candidate or active Source'; end if;
    if new.language_mode='single' and not exists(select 1 from bios_core.languages where id=new.language_id and status='active') then raise exception 'active Language required'; end if;
    if new.supersedes_document_id is not null then
      if new.supersedes_document_id=new.id then raise exception 'Document cannot supersede itself'; end if;
      perform pg_advisory_xact_lock(hashtextextended('bios_document_successor:'||new.supersedes_document_id::text,0));
      select * into strict p from bios_knowledge.source_documents where id=new.supersedes_document_id for update;
      if s.status<>'active' or p.status<>'active' or p.source_id<>new.source_id or p.knowledge_scope<>new.knowledge_scope or p.tenant_id is distinct from new.tenant_id then raise exception 'incompatible successor proposal'; end if;
    end if;
    return new;
  end if;
  if new.id<>old.id or new.source_id<>old.source_id or new.knowledge_scope<>old.knowledge_scope or new.tenant_id is distinct from old.tenant_id or new.document_identifier is distinct from old.document_identifier or new.locator_scheme is distinct from old.locator_scheme or new.canonical_locator is distinct from old.canonical_locator or new.supersedes_document_id is distinct from old.supersedes_document_id or new.created_at<>old.created_at then raise exception 'Document identity is immutable'; end if;
  if old.content_sha256 is not null and new.content_sha256 is distinct from old.content_sha256 then raise exception 'Document digest is immutable once set'; end if;
  if old.status<>'candidate' and new.access_classification is distinct from old.access_classification then raise exception 'access classification is immutable after activation'; end if;
  if old.status in ('superseded','archived') and new.status<>old.status then raise exception 'historical Document status is terminal'; end if;
  if new.status<>old.status and not ((old.status='candidate' and new.status in ('active','archived')) or (old.status='active' and new.status in ('superseded','archived'))) then raise exception 'invalid Document transition'; end if;
  if new.status='active' and old.status<>new.status then
    if s.status<>'active' then raise exception 'Document activation requires active Source'; end if;
    if new.language_mode='single' and not exists(select 1 from bios_core.languages where id=new.language_id and status='active') then raise exception 'active Language required'; end if;
    if new.supersedes_document_id is not null then
      perform pg_advisory_xact_lock(hashtextextended('bios_document_successor:'||new.supersedes_document_id::text,0));
      select * into strict p from bios_knowledge.source_documents where id=new.supersedes_document_id for update;
      if p.status<>'active' or p.source_id<>new.source_id or p.knowledge_scope<>new.knowledge_scope or p.tenant_id is distinct from new.tenant_id then raise exception 'active compatible predecessor required'; end if;
      update bios_knowledge.source_documents set status='superseded',superseded_at=statement_timestamp() where id=p.id;
    end if;
  end if;
  return new;
end $$;

create trigger sources_govern before update on bios_knowledge.sources for each row execute function bios_internal.govern_source_row();
create trigger sources_touch before update on bios_knowledge.sources for each row execute function bios_internal.touch_source_updated_at();
create trigger sources_no_delete before delete on bios_knowledge.sources for each row execute function bios_internal.reject_source_delete();
create trigger source_documents_govern before insert or update on bios_knowledge.source_documents for each row execute function bios_internal.govern_source_document_row();
create trigger source_documents_touch before update on bios_knowledge.source_documents for each row execute function bios_internal.touch_source_updated_at();
create trigger source_documents_no_delete before delete on bios_knowledge.source_documents for each row execute function bios_internal.reject_source_delete();

create function bios_internal.source_actor(p_tenant_id uuid,p_actor_identifier text) returns uuid language plpgsql set search_path='' as $$
declare v_profile uuid;
begin
  if auth.role()='service_role' then perform bios_internal.assert_reference_actor(p_actor_identifier); return null; end if;
  if p_tenant_id is null or p_actor_identifier is not null then raise exception 'platform authority required'; end if;
  v_profile=bios_internal.current_profile_id();
  if v_profile is null or not bios_internal.has_capability(p_tenant_id,'manage_memberships') then raise exception 'same-Tenant administrator required'; end if;
  return v_profile;
end $$;
create function bios_internal.write_source_audit(p_tenant_id uuid,p_actor_profile_id uuid,p_actor_identifier text,p_action text,p_resource_type text,p_resource_id uuid,p_correlation_id uuid,p_metadata jsonb) returns void language plpgsql set search_path='' as $$
begin
  insert into bios_governance.audit_events(scope_type,tenant_id,actor_type,actor_profile_id,actor_identifier,action,resource_type,resource_id,outcome,correlation_id,metadata)
  values(case when p_tenant_id is null then 'platform' else 'tenant' end,p_tenant_id,case when p_actor_profile_id is null then 'service' else 'user' end,p_actor_profile_id,case when p_actor_profile_id is null then p_actor_identifier end,p_action,p_resource_type,p_resource_id,'succeeded',p_correlation_id,p_metadata);
end $$;

create function bios_internal.create_source(p_code text,p_canonical_name text,p_description text,p_canonical_origin_uri text,p_knowledge_scope text,p_tenant_id uuid,p_actor_identifier text,p_correlation_id uuid default gen_random_uuid()) returns uuid language plpgsql security definer set search_path='' as $$
declare v uuid; a uuid; begin a=bios_internal.source_actor(p_tenant_id,p_actor_identifier); insert into bios_knowledge.sources(code,canonical_name,description,canonical_origin_uri,knowledge_scope,tenant_id) values(p_code,p_canonical_name,p_description,p_canonical_origin_uri,p_knowledge_scope,p_tenant_id) returning id into v; perform bios_internal.write_source_audit(p_tenant_id,a,p_actor_identifier,'reference.created','source',v,p_correlation_id,jsonb_build_object('knowledge_scope',p_knowledge_scope)); return v; end $$;
create function bios_internal.update_source_metadata(p_id uuid,p_canonical_name text,p_description text,p_canonical_origin_uri text,p_reason text,p_actor_identifier text,p_correlation_id uuid default gen_random_uuid()) returns void language plpgsql security definer set search_path='' as $$
declare o bios_knowledge.sources%rowtype; a uuid; c text[]; begin select * into strict o from bios_knowledge.sources where id=p_id for update; a=bios_internal.source_actor(o.tenant_id,p_actor_identifier); c=array_remove(array[case when o.canonical_name is distinct from p_canonical_name then 'canonical_name' end,case when o.description is distinct from p_description then 'description' end,case when o.canonical_origin_uri is distinct from p_canonical_origin_uri then 'canonical_origin_uri' end],null); if cardinality(c)=0 then raise exception 'no metadata change'; end if; update bios_knowledge.sources set canonical_name=p_canonical_name,description=p_description,canonical_origin_uri=p_canonical_origin_uri where id=p_id; perform bios_internal.write_source_audit(o.tenant_id,a,p_actor_identifier,'reference.metadata_updated','source',p_id,p_correlation_id,jsonb_build_object('changed_fields',c,'reason',p_reason)); end $$;
create function bios_internal.transition_source(p_id uuid,p_new_status text,p_reason text,p_actor_identifier text,p_correlation_id uuid default gen_random_uuid()) returns void language plpgsql security definer set search_path='' as $$
declare o bios_knowledge.sources%rowtype; a uuid; begin select * into strict o from bios_knowledge.sources where id=p_id for update; a=bios_internal.source_actor(o.tenant_id,p_actor_identifier); if not ((o.status='candidate' and p_new_status in ('active','deprecated')) or (o.status='active' and p_new_status='deprecated')) then raise exception 'invalid Source transition'; end if; update bios_knowledge.sources set status=p_new_status,activated_at=case when p_new_status='active' then statement_timestamp() else activated_at end,deprecated_at=case when p_new_status='deprecated' then statement_timestamp() end where id=p_id; perform bios_internal.write_source_audit(o.tenant_id,a,p_actor_identifier,'reference.status_changed','source',p_id,p_correlation_id,jsonb_build_object('from_status',o.status,'to_status',p_new_status,'reason',p_reason)); end $$;

create function bios_internal.create_source_document(p_source_id uuid,p_knowledge_scope text,p_tenant_id uuid,p_document_identifier text,p_canonical_title text,p_description text,p_locator_scheme text,p_canonical_locator text,p_published_at timestamptz,p_language_mode text,p_language_id uuid,p_media_type text,p_access_classification text,p_restriction_note text,p_supersedes_document_id uuid,p_actor_identifier text,p_correlation_id uuid default gen_random_uuid()) returns uuid language plpgsql security definer set search_path='' as $$
declare v uuid; a uuid; begin a=bios_internal.source_actor(p_tenant_id,p_actor_identifier); insert into bios_knowledge.source_documents(source_id,knowledge_scope,tenant_id,document_identifier,canonical_title,description,locator_scheme,canonical_locator,published_at,language_mode,language_id,media_type,access_classification,restriction_note,supersedes_document_id) values(p_source_id,p_knowledge_scope,p_tenant_id,p_document_identifier,p_canonical_title,p_description,p_locator_scheme,p_canonical_locator,p_published_at,p_language_mode,p_language_id,p_media_type,p_access_classification,p_restriction_note,p_supersedes_document_id) returning id into v; perform bios_internal.write_source_audit(p_tenant_id,a,p_actor_identifier,'reference.created','source_document',v,p_correlation_id,jsonb_build_object('source_id',p_source_id,'knowledge_scope',p_knowledge_scope,'supersedes_document_id',p_supersedes_document_id)); return v; end $$;
create function bios_internal.update_source_document_metadata(p_id uuid,p_canonical_title text,p_description text,p_published_at timestamptz,p_language_mode text,p_language_id uuid,p_media_type text,p_access_classification text,p_restriction_note text,p_reason text,p_actor_identifier text,p_correlation_id uuid default gen_random_uuid()) returns void language plpgsql security definer set search_path='' as $$
declare o bios_knowledge.source_documents%rowtype; a uuid; c text[]; begin select * into strict o from bios_knowledge.source_documents where id=p_id for update; a=bios_internal.source_actor(o.tenant_id,p_actor_identifier); if o.status<>'candidate' and p_access_classification is distinct from o.access_classification then raise exception 'access classification is immutable after activation'; end if; if p_language_mode='single' and not exists(select 1 from bios_core.languages where id=p_language_id and status='active') then raise exception 'active Language required'; end if; c=array_remove(array[case when o.canonical_title is distinct from p_canonical_title then 'canonical_title' end,case when o.description is distinct from p_description then 'description' end,case when o.published_at is distinct from p_published_at then 'published_at' end,case when o.language_mode is distinct from p_language_mode or o.language_id is distinct from p_language_id then 'language' end,case when o.media_type is distinct from p_media_type then 'media_type' end,case when o.access_classification is distinct from p_access_classification then 'access_classification' end,case when o.restriction_note is distinct from p_restriction_note then 'restriction_note' end],null); if cardinality(c)=0 then raise exception 'no metadata change'; end if; update bios_knowledge.source_documents set canonical_title=p_canonical_title,description=p_description,published_at=p_published_at,language_mode=p_language_mode,language_id=p_language_id,media_type=p_media_type,access_classification=p_access_classification,restriction_note=p_restriction_note where id=p_id; perform bios_internal.write_source_audit(o.tenant_id,a,p_actor_identifier,'reference.metadata_updated','source_document',p_id,p_correlation_id,jsonb_build_object('changed_fields',c,'reason',p_reason)); end $$;
create function bios_internal.register_source_document_digest(p_id uuid,p_content_sha256 text,p_reason text,p_actor_identifier text,p_correlation_id uuid default gen_random_uuid()) returns void language plpgsql security definer set search_path='' as $$
declare o bios_knowledge.source_documents%rowtype; a uuid; begin select * into strict o from bios_knowledge.source_documents where id=p_id for update; a=bios_internal.source_actor(o.tenant_id,p_actor_identifier); if o.content_sha256 is not null then raise exception 'Document digest already registered'; end if; update bios_knowledge.source_documents set content_sha256=p_content_sha256 where id=p_id; perform bios_internal.write_source_audit(o.tenant_id,a,p_actor_identifier,'reference.metadata_updated','source_document',p_id,p_correlation_id,jsonb_build_object('changed_fields',jsonb_build_array('content_sha256'),'reason',p_reason)); end $$;
create function bios_internal.transition_source_document(p_id uuid,p_new_status text,p_reason text,p_actor_identifier text,p_correlation_id uuid default gen_random_uuid()) returns void language plpgsql security definer set search_path='' as $$
declare o bios_knowledge.source_documents%rowtype; a uuid; predecessor_status text; begin select * into strict o from bios_knowledge.source_documents where id=p_id for update; a=bios_internal.source_actor(o.tenant_id,p_actor_identifier); if not ((o.status='candidate' and p_new_status in ('active','archived')) or (o.status='active' and p_new_status='archived')) then raise exception 'invalid Document transition'; end if; update bios_knowledge.source_documents set status=p_new_status,activated_at=case when p_new_status='active' then statement_timestamp() else activated_at end,archived_at=case when p_new_status='archived' then statement_timestamp() end where id=p_id; perform bios_internal.write_source_audit(o.tenant_id,a,p_actor_identifier,'reference.status_changed','source_document',p_id,p_correlation_id,jsonb_build_object('from_status',o.status,'to_status',p_new_status,'reason',p_reason)); if p_new_status='active' and o.supersedes_document_id is not null then select status into strict predecessor_status from bios_knowledge.source_documents where id=o.supersedes_document_id; perform bios_internal.write_source_audit(o.tenant_id,a,p_actor_identifier,'reference.status_changed','source_document',o.supersedes_document_id,p_correlation_id,jsonb_build_object('from_status','active','to_status',predecessor_status,'reason','superseded by activated successor','successor_document_id',p_id)); end if; end $$;

alter table bios_knowledge.sources enable row level security;
alter table bios_knowledge.source_documents enable row level security;
create policy sources_authorized_read on bios_knowledge.sources for select to authenticated using((knowledge_scope='shared' and status='active') or (knowledge_scope='tenant' and bios_internal.has_active_membership(tenant_id) and (status='active' or bios_internal.has_capability(tenant_id,'manage_memberships'))));
create policy source_documents_authorized_read on bios_knowledge.source_documents for select to authenticated using((knowledge_scope='shared' and status='active' and access_classification='public') or (knowledge_scope='tenant' and bios_internal.has_active_membership(tenant_id) and (status='active' or bios_internal.has_capability(tenant_id,'manage_memberships'))));
grant usage on schema bios_knowledge to authenticated,service_role;
grant select on bios_knowledge.sources,bios_knowledge.source_documents to authenticated;
revoke all on all functions in schema bios_internal from public;
grant execute on function bios_internal.create_source(text,text,text,text,text,uuid,text,uuid),bios_internal.update_source_metadata(uuid,text,text,text,text,text,uuid),bios_internal.transition_source(uuid,text,text,text,uuid),bios_internal.create_source_document(uuid,text,uuid,text,text,text,text,text,timestamptz,text,uuid,text,text,text,uuid,text,uuid),bios_internal.update_source_document_metadata(uuid,text,text,timestamptz,text,uuid,text,text,text,text,text,uuid),bios_internal.register_source_document_digest(uuid,text,text,text,uuid),bios_internal.transition_source_document(uuid,text,text,text,uuid) to service_role,authenticated;
