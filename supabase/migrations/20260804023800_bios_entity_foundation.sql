-- DB-005 v1.3: BIOS Migration 004 -- Entity Foundation

alter table bios_governance.audit_events
  drop constraint audit_action_check,
  add constraint audit_action_check check (action in (
    'tenant.created','tenant.status_changed','membership.invited','membership.activated','membership.suspended','membership.revoked',
    'role.granted','role.revoked','platform.privileged_action','reference.created','reference.status_changed',
    'reference.metadata_updated','reference.relationship_added','reference.relationship_ended','entity.merged','entity.unmerged'
  )),
  drop constraint audit_resource_check,
  add constraint audit_resource_check check (resource_type ~ '^[a-z][a-z0-9_]*$' and resource_type in (
    'tenant','profile','tenant_membership','role','membership_role','platform','geography','geography_relationship',
    'market','market_geography','market_group','market_group_member','language','market_language',
    'domain','domain_node','domain_node_relationship','entity_type','entity','entity_alias'
  ));

create table bios_knowledge.entity_types (
  id uuid primary key default gen_random_uuid(), code text not null unique, name text not null, description text,
  status text not null default 'draft', created_at timestamptz not null default transaction_timestamp(),
  updated_at timestamptz not null default transaction_timestamp(), activated_at timestamptz, deprecated_at timestamptz,
  constraint entity_types_code_check check(code ~ '^[a-z][a-z0-9_]{1,62}[a-z0-9]$'),
  constraint entity_types_name_check check(name=btrim(name) and char_length(name) between 1 and 200),
  constraint entity_types_description_check check(description is null or (description=btrim(description) and char_length(description) between 1 and 1000)),
  constraint entity_types_status_check check(status in ('draft','active','deprecated')),
  constraint entity_types_lifecycle_check check((status='draft' and activated_at is null and deprecated_at is null) or (status='active' and activated_at is not null and deprecated_at is null) or (status='deprecated' and activated_at is not null and deprecated_at is not null))
);
grant usage on schema bios_knowledge to authenticated,service_role;
create index entity_types_status_idx on bios_knowledge.entity_types(status);
create index entity_types_name_lower_idx on bios_knowledge.entity_types(lower(name));

create table bios_knowledge.entities (
  id uuid primary key default gen_random_uuid(), entity_type_id uuid not null references bios_knowledge.entity_types(id) on delete restrict,
  knowledge_scope text not null, tenant_id uuid references bios_core.tenants(id) on delete restrict,
  canonical_name text not null, description text, status text not null default 'candidate',
  merge_target_entity_id uuid references bios_knowledge.entities(id) on delete restrict,
  created_at timestamptz not null default transaction_timestamp(), updated_at timestamptz not null default transaction_timestamp(),
  activated_at timestamptz, merged_at timestamptz, archived_at timestamptz,
  constraint entities_scope_check check((knowledge_scope='shared' and tenant_id is null) or (knowledge_scope='tenant' and tenant_id is not null)),
  constraint entities_name_check check(canonical_name=btrim(canonical_name) and char_length(canonical_name) between 1 and 200),
  constraint entities_description_check check(description is null or (description=btrim(description) and char_length(description) between 1 and 1000)),
  constraint entities_status_check check(status in ('candidate','active','merged','archived')),
  constraint entities_merge_self_check check(merge_target_entity_id is null or merge_target_entity_id<>id),
  constraint entities_lifecycle_check check(
    (status='candidate' and merge_target_entity_id is null and merged_at is null and archived_at is null and activated_at is null) or
    (status='active' and merge_target_entity_id is null and merged_at is null and archived_at is null and activated_at is not null) or
    (status='merged' and merge_target_entity_id is not null and merged_at is not null and archived_at is null and activated_at is not null) or
    (status='archived' and merge_target_entity_id is null and merged_at is null and archived_at is not null)
  )
);
create index entities_type_status_idx on bios_knowledge.entities(entity_type_id,status);
create index entities_scope_status_idx on bios_knowledge.entities(knowledge_scope,tenant_id,status);
create index entities_name_lower_idx on bios_knowledge.entities(lower(canonical_name));
create index entities_merge_target_idx on bios_knowledge.entities(merge_target_entity_id) where merge_target_entity_id is not null;

create table bios_knowledge.entity_aliases (
  id uuid primary key default gen_random_uuid(), entity_id uuid not null references bios_knowledge.entities(id) on delete restrict,
  alias_text text not null, alias_type text not null, language_id uuid references bios_core.languages(id) on delete restrict,
  market_id uuid references bios_core.markets(id) on delete restrict, confidence numeric, status text not null default 'candidate',
  valid_from timestamptz, valid_to timestamptz, created_at timestamptz not null default transaction_timestamp(),
  updated_at timestamptz not null default transaction_timestamp(), activated_at timestamptz, superseded_at timestamptz,
  constraint entity_aliases_text_check check(alias_text=btrim(alias_text) and char_length(alias_text) between 1 and 500),
  constraint entity_aliases_type_check check(alias_type in ('name','abbreviation','former_name','transliteration','trade_name','other')),
  constraint entity_aliases_confidence_check check(confidence is null or confidence between 0 and 1),
  constraint entity_aliases_status_check check(status in ('candidate','active','superseded')),
  constraint entity_aliases_validity_check check(valid_to is null or (valid_from is not null and valid_to>valid_from)),
  constraint entity_aliases_lifecycle_check check((status='candidate' and activated_at is null and superseded_at is null) or (status='active' and activated_at is not null and superseded_at is null) or (status='superseded' and superseded_at is not null))
);
create index entity_aliases_entity_status_idx on bios_knowledge.entity_aliases(entity_id,status);
create index entity_aliases_text_lower_idx on bios_knowledge.entity_aliases(lower(alias_text));
create index entity_aliases_language_idx on bios_knowledge.entity_aliases(language_id) where language_id is not null;
create index entity_aliases_market_idx on bios_knowledge.entity_aliases(market_id) where market_id is not null;

create function bios_internal.touch_entity_updated_at() returns trigger language plpgsql set search_path='' as $$ begin new.updated_at=statement_timestamp(); return new; end $$;
create function bios_internal.protect_entity_fields() returns trigger language plpgsql set search_path='' as $$
declare n jsonb:=to_jsonb(new); o jsonb:=to_jsonb(old);
begin
  if new.id<>old.id or new.created_at<>old.created_at then raise exception 'Entity foundation identity is immutable'; end if;
  if tg_table_name='entity_types' and n->>'code' is distinct from o->>'code' then raise exception 'Entity Type code is immutable'; end if;
  if tg_table_name='entities' and (n->>'entity_type_id' is distinct from o->>'entity_type_id' or n->>'knowledge_scope' is distinct from o->>'knowledge_scope' or n->>'tenant_id' is distinct from o->>'tenant_id') then raise exception 'Entity identity and ownership are immutable'; end if;
  if tg_table_name='entities' and o->>'status'='merged' and n->>'status'='merged' and n->>'merge_target_entity_id' is distinct from o->>'merge_target_entity_id' then raise exception 'merged target is immutable while merged'; end if;
  if tg_table_name='entity_aliases' and (n->>'entity_id' is distinct from o->>'entity_id' or n->>'alias_text' is distinct from o->>'alias_text' or n->>'alias_type' is distinct from o->>'alias_type' or n->>'language_id' is distinct from o->>'language_id' or n->>'market_id' is distinct from o->>'market_id' or n->>'valid_from' is distinct from o->>'valid_from' or n->>'valid_to' is distinct from o->>'valid_to') then raise exception 'Alias identity and context are immutable'; end if;
  return new;
end $$;
create function bios_internal.reject_entity_delete() returns trigger language plpgsql set search_path='' as $$ begin raise exception 'Entity foundation rows cannot be deleted'; end $$;

create function bios_internal.prevent_active_alias_overlap() returns trigger language plpgsql set search_path='' as $$
begin
  if new.status='active' then
    perform pg_advisory_xact_lock(hashtextextended('bios_alias:'||new.entity_id::text,0));
    if exists(select 1 from bios_knowledge.entity_aliases a where a.entity_id=new.entity_id and a.id<>new.id and a.status='active'
      and a.alias_text=new.alias_text and a.alias_type=new.alias_type and a.language_id is not distinct from new.language_id and a.market_id is not distinct from new.market_id
      and coalesce(a.valid_from,'-infinity'::timestamptz)<coalesce(new.valid_to,'infinity'::timestamptz)
      and coalesce(new.valid_from,'-infinity'::timestamptz)<coalesce(a.valid_to,'infinity'::timestamptz))
    then raise exception 'overlapping active alias episode exists'; end if;
  end if; return new;
end $$;

create trigger entity_types_immutable before update on bios_knowledge.entity_types for each row execute function bios_internal.protect_entity_fields();
create trigger entity_types_touch before update on bios_knowledge.entity_types for each row execute function bios_internal.touch_entity_updated_at();
create trigger entity_types_no_delete before delete on bios_knowledge.entity_types for each row execute function bios_internal.reject_entity_delete();
create trigger entities_immutable before update on bios_knowledge.entities for each row execute function bios_internal.protect_entity_fields();
create trigger entities_touch before update on bios_knowledge.entities for each row execute function bios_internal.touch_entity_updated_at();
create trigger entities_no_delete before delete on bios_knowledge.entities for each row execute function bios_internal.reject_entity_delete();
create trigger entity_aliases_immutable before update on bios_knowledge.entity_aliases for each row execute function bios_internal.protect_entity_fields();
create trigger entity_aliases_overlap before insert or update on bios_knowledge.entity_aliases for each row execute function bios_internal.prevent_active_alias_overlap();
create trigger entity_aliases_touch before update on bios_knowledge.entity_aliases for each row execute function bios_internal.touch_entity_updated_at();
create trigger entity_aliases_no_delete before delete on bios_knowledge.entity_aliases for each row execute function bios_internal.reject_entity_delete();

create function bios_internal.entity_actor(p_tenant_id uuid,p_actor_identifier text) returns uuid language plpgsql set search_path='' as $$
declare v_profile uuid;
begin
  if auth.role()='service_role' then perform bios_internal.assert_reference_actor(p_actor_identifier); return null; end if;
  if p_tenant_id is null or p_actor_identifier is not null then raise exception 'platform authority required'; end if;
  v_profile=bios_internal.current_profile_id();
  if v_profile is null or not bios_internal.has_capability(p_tenant_id,'manage_memberships') then raise exception 'same-tenant administrator required'; end if;
  return v_profile;
end $$;
create function bios_internal.write_entity_audit(p_tenant_id uuid,p_actor_profile_id uuid,p_actor_identifier text,p_action text,p_resource_type text,p_resource_id uuid,p_correlation_id uuid,p_metadata jsonb) returns void language plpgsql set search_path='' as $$
begin
  insert into bios_governance.audit_events(scope_type,tenant_id,actor_type,actor_profile_id,actor_identifier,action,resource_type,resource_id,outcome,correlation_id,metadata)
  values(case when p_tenant_id is null then 'platform' else 'tenant' end,p_tenant_id,case when p_actor_profile_id is null then 'service' else 'user' end,p_actor_profile_id,case when p_actor_profile_id is null then p_actor_identifier end,p_action,p_resource_type,p_resource_id,'succeeded',p_correlation_id,p_metadata);
end $$;

create function bios_internal.create_entity_type(p_code text,p_name text,p_description text,p_actor_identifier text,p_correlation_id uuid default gen_random_uuid()) returns uuid language plpgsql security definer set search_path='' as $$
declare v uuid; begin perform bios_internal.entity_actor(null,p_actor_identifier); insert into bios_knowledge.entity_types(code,name,description) values(p_code,p_name,p_description) returning id into v; perform bios_internal.write_entity_audit(null,null,p_actor_identifier,'reference.created','entity_type',v,p_correlation_id,'{}'); return v; end $$;
create function bios_internal.transition_entity_type(p_id uuid,p_new_status text,p_reason text,p_actor_identifier text,p_correlation_id uuid default gen_random_uuid()) returns void language plpgsql security definer set search_path='' as $$
declare old_status text; begin perform bios_internal.entity_actor(null,p_actor_identifier); select status into strict old_status from bios_knowledge.entity_types where id=p_id for update; if not ((old_status='draft' and p_new_status='active') or (old_status='active' and p_new_status='deprecated')) then raise exception 'invalid Entity Type transition'; end if; if p_new_status='deprecated' and exists(select 1 from bios_knowledge.entities where entity_type_id=p_id and status in ('candidate','active')) then raise exception 'Entity Type has candidate or active Entities'; end if; update bios_knowledge.entity_types set status=p_new_status,activated_at=coalesce(activated_at,statement_timestamp()),deprecated_at=case when p_new_status='deprecated' then statement_timestamp() end where id=p_id; perform bios_internal.write_entity_audit(null,null,p_actor_identifier,'reference.status_changed','entity_type',p_id,p_correlation_id,jsonb_build_object('from_status',old_status,'to_status',p_new_status,'reason',p_reason)); end $$;
create function bios_internal.update_entity_type_metadata(p_id uuid,p_name text,p_description text,p_reason text,p_actor_identifier text,p_correlation_id uuid default gen_random_uuid()) returns void language plpgsql security definer set search_path='' as $$
declare o bios_knowledge.entity_types%rowtype; c text[]; begin perform bios_internal.entity_actor(null,p_actor_identifier); select * into strict o from bios_knowledge.entity_types where id=p_id for update; c=array_remove(array[case when o.name is distinct from p_name then 'name' end,case when o.description is distinct from p_description then 'description' end],null); if cardinality(c)=0 then raise exception 'no metadata change'; end if; update bios_knowledge.entity_types set name=p_name,description=p_description where id=p_id; perform bios_internal.write_entity_audit(null,null,p_actor_identifier,'reference.metadata_updated','entity_type',p_id,p_correlation_id,jsonb_build_object('changed_fields',c,'reason',p_reason)); end $$;

create function bios_internal.create_entity(p_entity_type_id uuid,p_scope text,p_tenant_id uuid,p_name text,p_description text,p_actor_identifier text,p_correlation_id uuid default gen_random_uuid()) returns uuid language plpgsql security definer set search_path='' as $$
declare v uuid; actor uuid; begin actor=bios_internal.entity_actor(p_tenant_id,p_actor_identifier); if not exists(select 1 from bios_knowledge.entity_types where id=p_entity_type_id and status='active') then raise exception 'active Entity Type required'; end if; insert into bios_knowledge.entities(entity_type_id,knowledge_scope,tenant_id,canonical_name,description) values(p_entity_type_id,p_scope,p_tenant_id,p_name,p_description) returning id into v; perform bios_internal.write_entity_audit(p_tenant_id,actor,p_actor_identifier,'reference.created','entity',v,p_correlation_id,jsonb_build_object('knowledge_scope',p_scope)); return v; end $$;
create function bios_internal.update_entity_metadata(p_id uuid,p_name text,p_description text,p_reason text,p_actor_identifier text,p_correlation_id uuid default gen_random_uuid()) returns void language plpgsql security definer set search_path='' as $$
declare o bios_knowledge.entities%rowtype; actor uuid; c text[]; begin select * into strict o from bios_knowledge.entities where id=p_id for update; actor=bios_internal.entity_actor(o.tenant_id,p_actor_identifier); c=array_remove(array[case when o.canonical_name is distinct from p_name then 'canonical_name' end,case when o.description is distinct from p_description then 'description' end],null); if cardinality(c)=0 then raise exception 'no metadata change'; end if; update bios_knowledge.entities set canonical_name=p_name,description=p_description where id=p_id; perform bios_internal.write_entity_audit(o.tenant_id,actor,p_actor_identifier,'reference.metadata_updated','entity',p_id,p_correlation_id,jsonb_build_object('changed_fields',c,'reason',p_reason)); end $$;
create function bios_internal.transition_entity(p_id uuid,p_new_status text,p_reason text,p_actor_identifier text,p_correlation_id uuid default gen_random_uuid()) returns void language plpgsql security definer set search_path='' as $$
declare o bios_knowledge.entities%rowtype; actor uuid; begin select * into strict o from bios_knowledge.entities where id=p_id for update; actor=bios_internal.entity_actor(o.tenant_id,p_actor_identifier); if not ((o.status='candidate' and p_new_status in ('active','archived')) or (o.status='active' and p_new_status='archived')) then raise exception 'invalid Entity transition'; end if; if p_new_status='active' and not exists(select 1 from bios_knowledge.entity_types where id=o.entity_type_id and status='active') then raise exception 'active Entity Type required'; end if; if o.tenant_id is not null and p_new_status='active' and not bios_internal.has_active_membership(o.tenant_id) and auth.role()<>'service_role' then raise exception 'active Tenant membership required'; end if; update bios_knowledge.entities set status=p_new_status,activated_at=case when p_new_status='active' then statement_timestamp() else activated_at end,archived_at=case when p_new_status='archived' then statement_timestamp() end where id=p_id; perform bios_internal.write_entity_audit(o.tenant_id,actor,p_actor_identifier,'reference.status_changed','entity',p_id,p_correlation_id,jsonb_build_object('from_status',o.status,'to_status',p_new_status,'reason',p_reason)); end $$;

create function bios_internal.merge_entity(p_source_id uuid,p_target_id uuid,p_reason text,p_actor_identifier text,p_correlation_id uuid default gen_random_uuid()) returns void language plpgsql security definer set search_path='' as $$
declare s bios_knowledge.entities%rowtype; t bios_knowledge.entities%rowtype; actor uuid; lo uuid; hi uuid;
begin if p_source_id=p_target_id then raise exception 'Entity cannot merge into itself'; end if; lo=least(p_source_id,p_target_id); hi=greatest(p_source_id,p_target_id); perform pg_advisory_xact_lock(hashtextextended('bios_entity_merge:'||lo::text,0)); perform pg_advisory_xact_lock(hashtextextended('bios_entity_merge:'||hi::text,0)); select * into strict s from bios_knowledge.entities where id=p_source_id for update; select * into strict t from bios_knowledge.entities where id=p_target_id for update; actor=bios_internal.entity_actor(s.tenant_id,p_actor_identifier); if s.status<>'active' or t.status<>'active' or s.entity_type_id<>t.entity_type_id or s.knowledge_scope<>t.knowledge_scope or s.tenant_id is distinct from t.tenant_id then raise exception 'incompatible Entity merge'; end if; update bios_knowledge.entities set status='merged',merge_target_entity_id=p_target_id,merged_at=statement_timestamp() where id=p_source_id; perform bios_internal.write_entity_audit(s.tenant_id,actor,p_actor_identifier,'entity.merged','entity',p_source_id,p_correlation_id,jsonb_build_object('source_entity_id',p_source_id,'target_entity_id',p_target_id,'knowledge_scope',s.knowledge_scope,'tenant_id',s.tenant_id,'reason',p_reason)); end $$;
create function bios_internal.unmerge_entity(p_source_id uuid,p_reason text,p_actor_identifier text,p_correlation_id uuid default gen_random_uuid()) returns void language plpgsql security definer set search_path='' as $$
declare s bios_knowledge.entities%rowtype; actor uuid; old_target uuid; begin select * into strict s from bios_knowledge.entities where id=p_source_id for update; actor=bios_internal.entity_actor(s.tenant_id,p_actor_identifier); if s.status<>'merged' or not exists(select 1 from bios_knowledge.entity_types where id=s.entity_type_id and status='active') then raise exception 'Entity cannot be unmerged'; end if; old_target=s.merge_target_entity_id; update bios_knowledge.entities set status='active',merge_target_entity_id=null,merged_at=null where id=p_source_id; perform bios_internal.write_entity_audit(s.tenant_id,actor,p_actor_identifier,'entity.unmerged','entity',p_source_id,p_correlation_id,jsonb_build_object('source_entity_id',p_source_id,'former_target_entity_id',old_target,'knowledge_scope',s.knowledge_scope,'tenant_id',s.tenant_id,'reason',p_reason)); end $$;

create function bios_internal.create_entity_alias(p_entity_id uuid,p_alias_text text,p_alias_type text,p_language_id uuid,p_market_id uuid,p_confidence numeric,p_valid_from timestamptz,p_valid_to timestamptz,p_actor_identifier text,p_correlation_id uuid default gen_random_uuid()) returns uuid language plpgsql security definer set search_path='' as $$
declare e bios_knowledge.entities%rowtype; actor uuid; v uuid; begin select * into strict e from bios_knowledge.entities where id=p_entity_id; actor=bios_internal.entity_actor(e.tenant_id,p_actor_identifier); if e.status in ('merged','archived') then raise exception 'Entity cannot accept new aliases'; end if; if p_language_id is not null and not exists(select 1 from bios_core.languages where id=p_language_id and status='active') then raise exception 'active Language required'; end if; if p_market_id is not null and not exists(select 1 from bios_core.markets where id=p_market_id and status='active') then raise exception 'active Market required'; end if; insert into bios_knowledge.entity_aliases(entity_id,alias_text,alias_type,language_id,market_id,confidence,valid_from,valid_to) values(p_entity_id,p_alias_text,p_alias_type,p_language_id,p_market_id,p_confidence,p_valid_from,p_valid_to) returning id into v; perform bios_internal.write_entity_audit(e.tenant_id,actor,p_actor_identifier,'reference.created','entity_alias',v,p_correlation_id,jsonb_build_object('entity_id',p_entity_id)); return v; end $$;
create function bios_internal.transition_entity_alias(p_alias_id uuid,p_new_status text,p_reason text,p_actor_identifier text,p_correlation_id uuid default gen_random_uuid()) returns void language plpgsql security definer set search_path='' as $$
declare a bios_knowledge.entity_aliases%rowtype; e bios_knowledge.entities%rowtype; actor uuid; begin select * into strict a from bios_knowledge.entity_aliases where id=p_alias_id for update; select * into strict e from bios_knowledge.entities where id=a.entity_id; actor=bios_internal.entity_actor(e.tenant_id,p_actor_identifier); if not ((a.status='candidate' and p_new_status in ('active','superseded')) or (a.status='active' and p_new_status='superseded')) then raise exception 'invalid Alias transition'; end if; if p_new_status='active' and e.status<>'active' then raise exception 'active Entity required'; end if; if p_new_status='active' and a.language_id is not null and not exists(select 1 from bios_core.languages where id=a.language_id and status='active') then raise exception 'active Language required'; end if; if p_new_status='active' and a.market_id is not null and not exists(select 1 from bios_core.markets where id=a.market_id and status='active') then raise exception 'active Market required'; end if; update bios_knowledge.entity_aliases set status=p_new_status,activated_at=case when p_new_status='active' then statement_timestamp() else activated_at end,superseded_at=case when p_new_status='superseded' then statement_timestamp() end where id=p_alias_id; perform bios_internal.write_entity_audit(e.tenant_id,actor,p_actor_identifier,'reference.status_changed','entity_alias',p_alias_id,p_correlation_id,jsonb_build_object('from_status',a.status,'to_status',p_new_status,'reason',p_reason)); end $$;
create function bios_internal.update_entity_alias_confidence(p_alias_id uuid,p_confidence numeric,p_reason text,p_actor_identifier text,p_correlation_id uuid default gen_random_uuid()) returns void language plpgsql security definer set search_path='' as $$
declare a bios_knowledge.entity_aliases%rowtype; e bios_knowledge.entities%rowtype; actor uuid; begin select * into strict a from bios_knowledge.entity_aliases where id=p_alias_id for update; select * into strict e from bios_knowledge.entities where id=a.entity_id; actor=bios_internal.entity_actor(e.tenant_id,p_actor_identifier); if a.confidence is not distinct from p_confidence then raise exception 'no confidence change'; end if; update bios_knowledge.entity_aliases set confidence=p_confidence where id=p_alias_id; perform bios_internal.write_entity_audit(e.tenant_id,actor,p_actor_identifier,'reference.metadata_updated','entity_alias',p_alias_id,p_correlation_id,jsonb_build_object('changed_fields',jsonb_build_array('confidence'),'reason',p_reason)); end $$;

create function bios_internal.resolve_entity(p_entity_id uuid) returns table(requested_entity_id uuid,resolved_entity_id uuid) language sql stable security definer set search_path='' as $$
  select e.id,case when e.status='merged' then e.merge_target_entity_id else e.id end
  from bios_knowledge.entities e join bios_core.profiles p on p.auth_user_id=auth.uid() and p.status='active'
  where e.id=p_entity_id and e.status in ('active','merged') and
    (e.knowledge_scope='shared' or (e.knowledge_scope='tenant' and bios_internal.has_active_membership(e.tenant_id))) and
    (e.status<>'merged' or exists(select 1 from bios_knowledge.entities t where t.id=e.merge_target_entity_id and t.status='active'))
$$;

alter table bios_knowledge.entity_types enable row level security; alter table bios_knowledge.entities enable row level security; alter table bios_knowledge.entity_aliases enable row level security;
create policy entity_types_active_read on bios_knowledge.entity_types for select to authenticated using(status='active');
create policy entities_authorized_read on bios_knowledge.entities for select to authenticated using((knowledge_scope='shared' and status='active') or (knowledge_scope='tenant' and bios_internal.has_active_membership(tenant_id) and (status='active' or bios_internal.has_capability(tenant_id,'manage_memberships'))));
create policy entity_aliases_authorized_read on bios_knowledge.entity_aliases for select to authenticated using(exists(select 1 from bios_knowledge.entities e where e.id=entity_id and ((e.knowledge_scope='shared' and e.status='active' and bios_knowledge.entity_aliases.status='active') or (e.knowledge_scope='tenant' and bios_internal.has_active_membership(e.tenant_id) and ((e.status='active' and bios_knowledge.entity_aliases.status='active') or bios_internal.has_capability(e.tenant_id,'manage_memberships'))))));
grant select on bios_knowledge.entity_types,bios_knowledge.entities,bios_knowledge.entity_aliases to authenticated;
revoke all on all functions in schema bios_internal from public;
grant execute on function bios_internal.resolve_entity(uuid) to authenticated,service_role;
grant execute on function bios_internal.create_entity_type(text,text,text,text,uuid),bios_internal.transition_entity_type(uuid,text,text,text,uuid),bios_internal.update_entity_type_metadata(uuid,text,text,text,text,uuid) to service_role;
grant execute on function bios_internal.create_entity(uuid,text,uuid,text,text,text,uuid),bios_internal.update_entity_metadata(uuid,text,text,text,text,uuid),bios_internal.transition_entity(uuid,text,text,text,uuid),bios_internal.merge_entity(uuid,uuid,text,text,uuid),bios_internal.unmerge_entity(uuid,text,text,uuid),bios_internal.create_entity_alias(uuid,text,text,uuid,uuid,numeric,timestamptz,timestamptz,text,uuid),bios_internal.transition_entity_alias(uuid,text,text,text,uuid),bios_internal.update_entity_alias_confidence(uuid,numeric,text,text,uuid) to service_role,authenticated;

comment on function bios_internal.resolve_entity(uuid) is 'Authorized one-hop Entity UUID resolver returning exactly requested and resolved UUIDs.';
