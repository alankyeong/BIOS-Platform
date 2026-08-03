-- DB-003 v1.0: BIOS Migration 002 -- Geography, Market & Language Foundation

alter table bios_governance.audit_events
  drop constraint audit_action_check,
  add constraint audit_action_check check (action in (
    'tenant.created','tenant.status_changed','membership.invited','membership.activated',
    'membership.suspended','membership.revoked','role.granted','role.revoked',
    'platform.privileged_action','reference.created','reference.status_changed',
    'reference.metadata_updated','reference.relationship_added','reference.relationship_ended'
  )),
  drop constraint audit_resource_check,
  add constraint audit_resource_check check (
    resource_type ~ '^[a-z][a-z0-9_]*$' and resource_type in (
      'tenant','profile','tenant_membership','role','membership_role','platform',
      'geography','geography_relationship','market','market_geography',
      'market_group','market_group_member','language','market_language'
    )
  );

create table bios_core.geographies (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  name text not null,
  geography_type text not null,
  description text,
  status text not null default 'draft',
  created_at timestamptz not null default transaction_timestamp(),
  updated_at timestamptz not null default transaction_timestamp(),
  activated_at timestamptz,
  deprecated_at timestamptz,
  constraint geographies_code_check check (code ~ '^[a-z][a-z0-9_]{1,62}[a-z0-9]$'),
  constraint geographies_name_check check (name=btrim(name) and char_length(name) between 1 and 200),
  constraint geographies_type_check check (geography_type in ('country','territory','administrative_region','subnational_geography','macro_region','other')),
  constraint geographies_description_check check (description is null or (description=btrim(description) and char_length(description)<=1000)),
  constraint geographies_status_check check (status in ('draft','active','deprecated')),
  constraint geographies_lifecycle_check check (
    (status='draft' and activated_at is null and deprecated_at is null) or
    (status='active' and activated_at is not null and deprecated_at is null) or
    (status='deprecated' and activated_at is not null and deprecated_at is not null)
  )
);
create index geographies_status_type_idx on bios_core.geographies(status,geography_type);
create index geographies_name_lower_idx on bios_core.geographies(lower(name));

create table bios_core.geography_relationships (
  id uuid primary key default gen_random_uuid(),
  subject_geography_id uuid not null references bios_core.geographies(id) on delete restrict,
  object_geography_id uuid not null references bios_core.geographies(id) on delete restrict,
  relationship_type text not null default 'contains',
  valid_from timestamptz not null default transaction_timestamp(),
  valid_to timestamptz,
  created_at timestamptz not null default transaction_timestamp(),
  updated_at timestamptz not null default transaction_timestamp(),
  constraint geography_relationships_distinct_endpoints_check check (subject_geography_id<>object_geography_id),
  constraint geography_relationships_type_check check (relationship_type='contains'),
  constraint geography_relationships_validity_check check (valid_to is null or valid_to>valid_from)
);
create unique index geography_relationships_active_uidx on bios_core.geography_relationships(subject_geography_id,object_geography_id,relationship_type) where valid_to is null;
create index geography_relationships_active_subject_idx on bios_core.geography_relationships(subject_geography_id,object_geography_id) where valid_to is null;
create index geography_relationships_active_object_idx on bios_core.geography_relationships(object_geography_id,subject_geography_id) where valid_to is null;

create table bios_core.markets (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  name text not null,
  description text,
  status text not null default 'draft',
  created_at timestamptz not null default transaction_timestamp(),
  updated_at timestamptz not null default transaction_timestamp(),
  activated_at timestamptz,
  deprecated_at timestamptz,
  constraint markets_code_check check (code ~ '^[a-z][a-z0-9_]{1,62}[a-z0-9]$'),
  constraint markets_name_check check (name=btrim(name) and char_length(name) between 1 and 200),
  constraint markets_description_check check (description is null or (description=btrim(description) and char_length(description)<=1000)),
  constraint markets_status_check check (status in ('draft','active','deprecated')),
  constraint markets_lifecycle_check check (
    (status='draft' and activated_at is null and deprecated_at is null) or
    (status='active' and activated_at is not null and deprecated_at is null) or
    (status='deprecated' and activated_at is not null and deprecated_at is not null)
  )
);
create index markets_status_idx on bios_core.markets(status);
create index markets_name_lower_idx on bios_core.markets(lower(name));

create table bios_core.market_geographies (
  id uuid primary key default gen_random_uuid(),
  market_id uuid not null references bios_core.markets(id) on delete restrict,
  geography_id uuid not null references bios_core.geographies(id) on delete restrict,
  relationship_role text not null default 'included',
  valid_from timestamptz not null default transaction_timestamp(),
  valid_to timestamptz,
  created_at timestamptz not null default transaction_timestamp(),
  updated_at timestamptz not null default transaction_timestamp(),
  constraint market_geographies_role_check check (relationship_role in ('primary','included')),
  constraint market_geographies_validity_check check (valid_to is null or valid_to>valid_from)
);
create unique index market_geographies_active_uidx on bios_core.market_geographies(market_id,geography_id,relationship_role) where valid_to is null;
create unique index market_geographies_active_primary_uidx on bios_core.market_geographies(market_id) where relationship_role='primary' and valid_to is null;
create index market_geographies_active_market_idx on bios_core.market_geographies(market_id,geography_id) where valid_to is null;
create index market_geographies_active_geography_idx on bios_core.market_geographies(geography_id,market_id) where valid_to is null;

create table bios_core.market_groups (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  name text not null,
  description text,
  status text not null default 'draft',
  created_at timestamptz not null default transaction_timestamp(),
  updated_at timestamptz not null default transaction_timestamp(),
  activated_at timestamptz,
  deprecated_at timestamptz,
  constraint market_groups_code_check check (code ~ '^[a-z][a-z0-9_]{1,62}[a-z0-9]$'),
  constraint market_groups_name_check check (name=btrim(name) and char_length(name) between 1 and 200),
  constraint market_groups_description_check check (description is null or (description=btrim(description) and char_length(description)<=1000)),
  constraint market_groups_status_check check (status in ('draft','active','deprecated')),
  constraint market_groups_lifecycle_check check (
    (status='draft' and activated_at is null and deprecated_at is null) or
    (status='active' and activated_at is not null and deprecated_at is null) or
    (status='deprecated' and activated_at is not null and deprecated_at is not null)
  )
);
create index market_groups_status_idx on bios_core.market_groups(status);
create index market_groups_name_lower_idx on bios_core.market_groups(lower(name));

create table bios_core.market_group_members (
  id uuid primary key default gen_random_uuid(),
  market_group_id uuid not null references bios_core.market_groups(id) on delete restrict,
  market_id uuid not null references bios_core.markets(id) on delete restrict,
  valid_from timestamptz not null default transaction_timestamp(),
  valid_to timestamptz,
  created_at timestamptz not null default transaction_timestamp(),
  updated_at timestamptz not null default transaction_timestamp(),
  constraint market_group_members_validity_check check (valid_to is null or valid_to>valid_from)
);
create unique index market_group_members_active_uidx on bios_core.market_group_members(market_group_id,market_id) where valid_to is null;
create index market_group_members_active_group_idx on bios_core.market_group_members(market_group_id,market_id) where valid_to is null;
create index market_group_members_active_market_idx on bios_core.market_group_members(market_id,market_group_id) where valid_to is null;

create table bios_core.languages (
  id uuid primary key default gen_random_uuid(),
  tag text not null unique,
  base_language_subtag text not null,
  script_subtag text,
  region_subtag text,
  display_name text not null,
  native_name text,
  status text not null default 'draft',
  created_at timestamptz not null default transaction_timestamp(),
  updated_at timestamptz not null default transaction_timestamp(),
  activated_at timestamptz,
  deprecated_at timestamptz,
  constraint languages_tag_check check (tag ~ '^[a-z]{2,3}(-[A-Z][a-z]{3})?(-([A-Z]{2}|[0-9]{3}))?$'),
  constraint languages_base_check check (base_language_subtag ~ '^[a-z]{2,3}$'),
  constraint languages_script_check check (script_subtag is null or script_subtag ~ '^[A-Z][a-z]{3}$'),
  constraint languages_region_check check (region_subtag is null or region_subtag ~ '^([A-Z]{2}|[0-9]{3})$'),
  constraint languages_components_check check (tag=base_language_subtag||case when script_subtag is null then '' else '-'||script_subtag end||case when region_subtag is null then '' else '-'||region_subtag end),
  constraint languages_display_name_check check (display_name=btrim(display_name) and char_length(display_name) between 1 and 200),
  constraint languages_native_name_check check (native_name is null or (native_name=btrim(native_name) and char_length(native_name) between 1 and 200)),
  constraint languages_status_check check (status in ('draft','active','deprecated')),
  constraint languages_lifecycle_check check (
    (status='draft' and activated_at is null and deprecated_at is null) or
    (status='active' and activated_at is not null and deprecated_at is null) or
    (status='deprecated' and activated_at is not null and deprecated_at is not null)
  )
);
create index languages_base_idx on bios_core.languages(base_language_subtag);
create index languages_base_script_idx on bios_core.languages(base_language_subtag,script_subtag);
create index languages_status_idx on bios_core.languages(status);

create table bios_core.market_languages (
  id uuid primary key default gen_random_uuid(),
  market_id uuid not null references bios_core.markets(id) on delete restrict,
  language_id uuid not null references bios_core.languages(id) on delete restrict,
  valid_from timestamptz not null default transaction_timestamp(),
  valid_to timestamptz,
  created_at timestamptz not null default transaction_timestamp(),
  updated_at timestamptz not null default transaction_timestamp(),
  constraint market_languages_validity_check check (valid_to is null or valid_to>valid_from)
);
create unique index market_languages_active_uidx on bios_core.market_languages(market_id,language_id) where valid_to is null;
create index market_languages_active_market_idx on bios_core.market_languages(market_id,language_id) where valid_to is null;
create index market_languages_active_language_idx on bios_core.market_languages(language_id,market_id) where valid_to is null;

create function bios_internal.protect_reference_fields() returns trigger
language plpgsql set search_path='' as $$
declare v_new jsonb:=to_jsonb(new); v_old jsonb:=to_jsonb(old);
begin
  if new.id<>old.id or new.created_at<>old.created_at then raise exception 'reference identity is immutable'; end if;
  if tg_table_name in ('geographies','markets','market_groups') and v_new->>'code' is distinct from v_old->>'code' then raise exception 'reference code is immutable'; end if;
  if tg_table_name='languages' and (v_new->>'tag' is distinct from v_old->>'tag' or v_new->>'base_language_subtag' is distinct from v_old->>'base_language_subtag' or v_new->>'script_subtag' is distinct from v_old->>'script_subtag' or v_new->>'region_subtag' is distinct from v_old->>'region_subtag') then raise exception 'language identity is immutable'; end if;
  if tg_table_name='geography_relationships' and (v_new->>'subject_geography_id' is distinct from v_old->>'subject_geography_id' or v_new->>'object_geography_id' is distinct from v_old->>'object_geography_id' or v_new->>'relationship_type' is distinct from v_old->>'relationship_type' or v_new->>'valid_from' is distinct from v_old->>'valid_from') then raise exception 'relationship episode identity is immutable'; end if;
  if tg_table_name='market_geographies' and (v_new->>'market_id' is distinct from v_old->>'market_id' or v_new->>'geography_id' is distinct from v_old->>'geography_id' or v_new->>'relationship_role' is distinct from v_old->>'relationship_role' or v_new->>'valid_from' is distinct from v_old->>'valid_from') then raise exception 'relationship episode identity is immutable'; end if;
  if tg_table_name='market_group_members' and (v_new->>'market_group_id' is distinct from v_old->>'market_group_id' or v_new->>'market_id' is distinct from v_old->>'market_id' or v_new->>'valid_from' is distinct from v_old->>'valid_from') then raise exception 'relationship episode identity is immutable'; end if;
  if tg_table_name='market_languages' and (v_new->>'market_id' is distinct from v_old->>'market_id' or v_new->>'language_id' is distinct from v_old->>'language_id' or v_new->>'valid_from' is distinct from v_old->>'valid_from') then raise exception 'relationship episode identity is immutable'; end if;
  if tg_table_name in ('geography_relationships','market_geographies','market_group_members','market_languages') and v_old->>'valid_to' is not null and v_new->>'valid_to' is distinct from v_old->>'valid_to' then raise exception 'ended relationship episode is immutable'; end if;
  if tg_table_name in ('geography_relationships','market_geographies','market_group_members','market_languages') and v_old->>'valid_to' is null and v_new->>'valid_to' is null then raise exception 'only relationship closure is permitted'; end if;
  return new;
end $$;

create trigger geographies_immutable before update on bios_core.geographies for each row execute function bios_internal.protect_reference_fields();
create trigger geographies_touch before update on bios_core.geographies for each row execute function bios_internal.touch_updated_at();
create trigger geographies_no_delete before delete on bios_core.geographies for each row execute function bios_internal.reject_delete();
create trigger geography_relationships_immutable before update on bios_core.geography_relationships for each row execute function bios_internal.protect_reference_fields();
create trigger geography_relationships_touch before update on bios_core.geography_relationships for each row execute function bios_internal.touch_updated_at();
create trigger geography_relationships_no_delete before delete on bios_core.geography_relationships for each row execute function bios_internal.reject_delete();
create trigger markets_immutable before update on bios_core.markets for each row execute function bios_internal.protect_reference_fields();
create trigger markets_touch before update on bios_core.markets for each row execute function bios_internal.touch_updated_at();
create trigger markets_no_delete before delete on bios_core.markets for each row execute function bios_internal.reject_delete();
create trigger market_geographies_immutable before update on bios_core.market_geographies for each row execute function bios_internal.protect_reference_fields();
create trigger market_geographies_touch before update on bios_core.market_geographies for each row execute function bios_internal.touch_updated_at();
create trigger market_geographies_no_delete before delete on bios_core.market_geographies for each row execute function bios_internal.reject_delete();
create trigger market_groups_immutable before update on bios_core.market_groups for each row execute function bios_internal.protect_reference_fields();
create trigger market_groups_touch before update on bios_core.market_groups for each row execute function bios_internal.touch_updated_at();
create trigger market_groups_no_delete before delete on bios_core.market_groups for each row execute function bios_internal.reject_delete();
create trigger market_group_members_immutable before update on bios_core.market_group_members for each row execute function bios_internal.protect_reference_fields();
create trigger market_group_members_touch before update on bios_core.market_group_members for each row execute function bios_internal.touch_updated_at();
create trigger market_group_members_no_delete before delete on bios_core.market_group_members for each row execute function bios_internal.reject_delete();
create trigger languages_immutable before update on bios_core.languages for each row execute function bios_internal.protect_reference_fields();
create trigger languages_touch before update on bios_core.languages for each row execute function bios_internal.touch_updated_at();
create trigger languages_no_delete before delete on bios_core.languages for each row execute function bios_internal.reject_delete();
create trigger market_languages_immutable before update on bios_core.market_languages for each row execute function bios_internal.protect_reference_fields();
create trigger market_languages_touch before update on bios_core.market_languages for each row execute function bios_internal.touch_updated_at();
create trigger market_languages_no_delete before delete on bios_core.market_languages for each row execute function bios_internal.reject_delete();

create function bios_internal.assert_reference_actor(p_actor_identifier text) returns void
language plpgsql set search_path='' as $$
begin
  if auth.role()<>'service_role' then raise exception 'service role required'; end if;
  if p_actor_identifier is null or p_actor_identifier<>btrim(p_actor_identifier) or char_length(p_actor_identifier) not between 1 and 200 then raise exception 'safe actor identifier required'; end if;
end $$;

create function bios_internal.write_reference_audit(p_actor_identifier text,p_action text,p_resource_type text,p_resource_id uuid,p_correlation_id uuid,p_metadata jsonb) returns void
language plpgsql set search_path='' as $$
begin
  insert into bios_governance.audit_events(scope_type,actor_type,actor_identifier,action,resource_type,resource_id,outcome,correlation_id,metadata)
  values('platform','service',p_actor_identifier,p_action,p_resource_type,p_resource_id,'succeeded',p_correlation_id,p_metadata);
end $$;

create function bios_internal.create_geography(p_code text,p_name text,p_geography_type text,p_description text,p_actor_identifier text,p_correlation_id uuid default gen_random_uuid()) returns uuid
language plpgsql security definer set search_path='' as $$
declare v_id uuid;
begin
  perform bios_internal.assert_reference_actor(p_actor_identifier);
  insert into bios_core.geographies(code,name,geography_type,description) values(p_code,p_name,p_geography_type,p_description) returning id into v_id;
  perform bios_internal.write_reference_audit(p_actor_identifier,'reference.created','geography',v_id,p_correlation_id,'{}'); return v_id;
end $$;

create function bios_internal.create_market(p_code text,p_name text,p_description text,p_actor_identifier text,p_correlation_id uuid default gen_random_uuid()) returns uuid
language plpgsql security definer set search_path='' as $$
declare v_id uuid;
begin
  perform bios_internal.assert_reference_actor(p_actor_identifier);
  insert into bios_core.markets(code,name,description) values(p_code,p_name,p_description) returning id into v_id;
  perform bios_internal.write_reference_audit(p_actor_identifier,'reference.created','market',v_id,p_correlation_id,'{}'); return v_id;
end $$;

create function bios_internal.create_market_group(p_code text,p_name text,p_description text,p_actor_identifier text,p_correlation_id uuid default gen_random_uuid()) returns uuid
language plpgsql security definer set search_path='' as $$
declare v_id uuid;
begin
  perform bios_internal.assert_reference_actor(p_actor_identifier);
  insert into bios_core.market_groups(code,name,description) values(p_code,p_name,p_description) returning id into v_id;
  perform bios_internal.write_reference_audit(p_actor_identifier,'reference.created','market_group',v_id,p_correlation_id,'{}'); return v_id;
end $$;

create function bios_internal.create_language(p_tag text,p_base_language_subtag text,p_script_subtag text,p_region_subtag text,p_display_name text,p_native_name text,p_actor_identifier text,p_correlation_id uuid default gen_random_uuid()) returns uuid
language plpgsql security definer set search_path='' as $$
declare v_id uuid;
begin
  perform bios_internal.assert_reference_actor(p_actor_identifier);
  insert into bios_core.languages(tag,base_language_subtag,script_subtag,region_subtag,display_name,native_name) values(p_tag,p_base_language_subtag,p_script_subtag,p_region_subtag,p_display_name,p_native_name) returning id into v_id;
  perform bios_internal.write_reference_audit(p_actor_identifier,'reference.created','language',v_id,p_correlation_id,'{}'); return v_id;
end $$;

create function bios_internal.transition_reference_status(p_resource_type text,p_resource_id uuid,p_new_status text,p_reason text,p_actor_identifier text,p_correlation_id uuid default gen_random_uuid()) returns void
language plpgsql security definer set search_path='' as $$
declare v_old text;
begin
  perform bios_internal.assert_reference_actor(p_actor_identifier);
  case p_resource_type
    when 'geography' then select status into strict v_old from bios_core.geographies where id=p_resource_id for update;
    when 'market' then select status into strict v_old from bios_core.markets where id=p_resource_id for update;
    when 'market_group' then select status into strict v_old from bios_core.market_groups where id=p_resource_id for update;
    when 'language' then select status into strict v_old from bios_core.languages where id=p_resource_id for update;
    else raise exception 'unsupported base reference type';
  end case;
  if not ((v_old='draft' and p_new_status='active') or (v_old='active' and p_new_status='deprecated')) then raise exception 'invalid reference lifecycle transition'; end if;
  case p_resource_type
    when 'geography' then update bios_core.geographies set status=p_new_status,activated_at=coalesce(activated_at,transaction_timestamp()),deprecated_at=case when p_new_status='deprecated' then transaction_timestamp() end where id=p_resource_id;
    when 'market' then update bios_core.markets set status=p_new_status,activated_at=coalesce(activated_at,transaction_timestamp()),deprecated_at=case when p_new_status='deprecated' then transaction_timestamp() end where id=p_resource_id;
    when 'market_group' then update bios_core.market_groups set status=p_new_status,activated_at=coalesce(activated_at,transaction_timestamp()),deprecated_at=case when p_new_status='deprecated' then transaction_timestamp() end where id=p_resource_id;
    when 'language' then update bios_core.languages set status=p_new_status,activated_at=coalesce(activated_at,transaction_timestamp()),deprecated_at=case when p_new_status='deprecated' then transaction_timestamp() end where id=p_resource_id;
  end case;
  perform bios_internal.write_reference_audit(p_actor_identifier,'reference.status_changed',p_resource_type,p_resource_id,p_correlation_id,jsonb_build_object('from_status',v_old,'to_status',p_new_status,'reason',p_reason));
end $$;

create function bios_internal.update_geography_metadata(p_id uuid,p_name text,p_geography_type text,p_description text,p_reason text,p_actor_identifier text,p_correlation_id uuid default gen_random_uuid()) returns void
language plpgsql security definer set search_path='' as $$
declare v_old bios_core.geographies%rowtype; v_changed text[];
begin
  perform bios_internal.assert_reference_actor(p_actor_identifier); select * into strict v_old from bios_core.geographies where id=p_id for update;
  v_changed=array_remove(array[case when v_old.name is distinct from p_name then 'name' end,case when v_old.geography_type is distinct from p_geography_type then 'geography_type' end,case when v_old.description is distinct from p_description then 'description' end],null);
  if cardinality(v_changed)=0 then raise exception 'no approved metadata change supplied'; end if;
  update bios_core.geographies set name=p_name,geography_type=p_geography_type,description=p_description where id=p_id;
  perform bios_internal.write_reference_audit(p_actor_identifier,'reference.metadata_updated','geography',p_id,p_correlation_id,jsonb_build_object('changed_fields',v_changed,'reason',p_reason));
end $$;

create function bios_internal.update_market_metadata(p_id uuid,p_name text,p_description text,p_reason text,p_actor_identifier text,p_correlation_id uuid default gen_random_uuid()) returns void
language plpgsql security definer set search_path='' as $$
declare v_old bios_core.markets%rowtype; v_changed text[];
begin
  perform bios_internal.assert_reference_actor(p_actor_identifier); select * into strict v_old from bios_core.markets where id=p_id for update;
  v_changed=array_remove(array[case when v_old.name is distinct from p_name then 'name' end,case when v_old.description is distinct from p_description then 'description' end],null);
  if cardinality(v_changed)=0 then raise exception 'no approved metadata change supplied'; end if;
  update bios_core.markets set name=p_name,description=p_description where id=p_id;
  perform bios_internal.write_reference_audit(p_actor_identifier,'reference.metadata_updated','market',p_id,p_correlation_id,jsonb_build_object('changed_fields',v_changed,'reason',p_reason));
end $$;

create function bios_internal.update_market_group_metadata(p_id uuid,p_name text,p_description text,p_reason text,p_actor_identifier text,p_correlation_id uuid default gen_random_uuid()) returns void
language plpgsql security definer set search_path='' as $$
declare v_old bios_core.market_groups%rowtype; v_changed text[];
begin
  perform bios_internal.assert_reference_actor(p_actor_identifier); select * into strict v_old from bios_core.market_groups where id=p_id for update;
  v_changed=array_remove(array[case when v_old.name is distinct from p_name then 'name' end,case when v_old.description is distinct from p_description then 'description' end],null);
  if cardinality(v_changed)=0 then raise exception 'no approved metadata change supplied'; end if;
  update bios_core.market_groups set name=p_name,description=p_description where id=p_id;
  perform bios_internal.write_reference_audit(p_actor_identifier,'reference.metadata_updated','market_group',p_id,p_correlation_id,jsonb_build_object('changed_fields',v_changed,'reason',p_reason));
end $$;

create function bios_internal.update_language_metadata(p_id uuid,p_display_name text,p_native_name text,p_reason text,p_actor_identifier text,p_correlation_id uuid default gen_random_uuid()) returns void
language plpgsql security definer set search_path='' as $$
declare v_old bios_core.languages%rowtype; v_changed text[];
begin
  perform bios_internal.assert_reference_actor(p_actor_identifier); select * into strict v_old from bios_core.languages where id=p_id for update;
  v_changed=array_remove(array[case when v_old.display_name is distinct from p_display_name then 'display_name' end,case when v_old.native_name is distinct from p_native_name then 'native_name' end],null);
  if cardinality(v_changed)=0 then raise exception 'no approved metadata change supplied'; end if;
  update bios_core.languages set display_name=p_display_name,native_name=p_native_name where id=p_id;
  perform bios_internal.write_reference_audit(p_actor_identifier,'reference.metadata_updated','language',p_id,p_correlation_id,jsonb_build_object('changed_fields',v_changed,'reason',p_reason));
end $$;

create function bios_internal.add_geography_relationship(p_subject_id uuid,p_object_id uuid,p_actor_identifier text,p_correlation_id uuid default gen_random_uuid()) returns uuid
language plpgsql security definer set search_path='' as $$
declare v_id uuid;
begin
  perform bios_internal.assert_reference_actor(p_actor_identifier); perform pg_advisory_xact_lock(hashtextextended('bios_geography_contains_graph',0));
  if p_subject_id=p_object_id then raise exception 'geography cannot contain itself'; end if;
  if exists(with recursive reachable(id) as (
    select gr.object_geography_id from bios_core.geography_relationships gr where gr.subject_geography_id=p_object_id and gr.valid_to is null
    union select gr.object_geography_id from bios_core.geography_relationships gr join reachable r on gr.subject_geography_id=r.id where gr.valid_to is null
  ) select 1 from reachable where id=p_subject_id) then raise exception 'geography relationship would create a cycle'; end if;
  insert into bios_core.geography_relationships(subject_geography_id,object_geography_id) values(p_subject_id,p_object_id) returning id into v_id;
  perform bios_internal.write_reference_audit(p_actor_identifier,'reference.relationship_added','geography_relationship',v_id,p_correlation_id,jsonb_build_object('subject_geography_id',p_subject_id,'object_geography_id',p_object_id,'relationship_type','contains')); return v_id;
end $$;

create function bios_internal.add_market_geography(p_market_id uuid,p_geography_id uuid,p_relationship_role text,p_actor_identifier text,p_correlation_id uuid default gen_random_uuid()) returns uuid
language plpgsql security definer set search_path='' as $$
declare v_id uuid;
begin
  perform bios_internal.assert_reference_actor(p_actor_identifier); perform pg_advisory_xact_lock(hashtextextended('bios_market_geography:'||p_market_id::text,0));
  if p_relationship_role='primary' and not exists(select 1 from bios_core.market_geographies where market_id=p_market_id and geography_id=p_geography_id and relationship_role='included' and valid_to is null) then raise exception 'primary geography requires active included coverage'; end if;
  insert into bios_core.market_geographies(market_id,geography_id,relationship_role) values(p_market_id,p_geography_id,p_relationship_role) returning id into v_id;
  perform bios_internal.write_reference_audit(p_actor_identifier,'reference.relationship_added','market_geography',v_id,p_correlation_id,jsonb_build_object('market_id',p_market_id,'geography_id',p_geography_id,'relationship_role',p_relationship_role)); return v_id;
end $$;

create function bios_internal.add_market_group_member(p_market_group_id uuid,p_market_id uuid,p_actor_identifier text,p_correlation_id uuid default gen_random_uuid()) returns uuid
language plpgsql security definer set search_path='' as $$
declare v_id uuid;
begin
  perform bios_internal.assert_reference_actor(p_actor_identifier);
  insert into bios_core.market_group_members(market_group_id,market_id) values(p_market_group_id,p_market_id) returning id into v_id;
  perform bios_internal.write_reference_audit(p_actor_identifier,'reference.relationship_added','market_group_member',v_id,p_correlation_id,jsonb_build_object('market_group_id',p_market_group_id,'market_id',p_market_id)); return v_id;
end $$;

create function bios_internal.add_market_language(p_market_id uuid,p_language_id uuid,p_actor_identifier text,p_correlation_id uuid default gen_random_uuid()) returns uuid
language plpgsql security definer set search_path='' as $$
declare v_id uuid;
begin
  perform bios_internal.assert_reference_actor(p_actor_identifier);
  insert into bios_core.market_languages(market_id,language_id) values(p_market_id,p_language_id) returning id into v_id;
  perform bios_internal.write_reference_audit(p_actor_identifier,'reference.relationship_added','market_language',v_id,p_correlation_id,jsonb_build_object('market_id',p_market_id,'language_id',p_language_id)); return v_id;
end $$;

create function bios_internal.end_reference_relationship(p_resource_type text,p_resource_id uuid,p_reason text,p_actor_identifier text,p_correlation_id uuid default gen_random_uuid()) returns void
language plpgsql security definer set search_path='' as $$
declare v_metadata jsonb;
begin
  perform bios_internal.assert_reference_actor(p_actor_identifier);
  case p_resource_type
    when 'geography_relationship' then
      perform 1 from bios_core.geography_relationships where id=p_resource_id and valid_to is null for update;
      if not found then raise exception 'active relationship not found'; end if;
      update bios_core.geography_relationships set valid_to=statement_timestamp() where id=p_resource_id;
      select jsonb_build_object('subject_geography_id',subject_geography_id,'object_geography_id',object_geography_id,'valid_to',valid_to,'reason',p_reason) into v_metadata from bios_core.geography_relationships where id=p_resource_id;
    when 'market_geography' then
      perform pg_advisory_xact_lock(hashtextextended('bios_market_geography:'||(select market_id::text from bios_core.market_geographies where id=p_resource_id),0));
      if exists(select 1 from bios_core.market_geographies i where i.id=p_resource_id and i.valid_to is null and i.relationship_role='included' and exists(select 1 from bios_core.market_geographies p where p.market_id=i.market_id and p.geography_id=i.geography_id and p.relationship_role='primary' and p.valid_to is null)) then raise exception 'cannot end included coverage while its primary relationship is active'; end if;
      update bios_core.market_geographies set valid_to=statement_timestamp() where id=p_resource_id and valid_to is null;
      if not found then raise exception 'active relationship not found'; end if;
      select jsonb_build_object('market_id',market_id,'geography_id',geography_id,'relationship_role',relationship_role,'valid_to',valid_to,'reason',p_reason) into v_metadata from bios_core.market_geographies where id=p_resource_id;
    when 'market_group_member' then
      update bios_core.market_group_members set valid_to=statement_timestamp() where id=p_resource_id and valid_to is null;
      if not found then raise exception 'active relationship not found'; end if;
      select jsonb_build_object('market_group_id',market_group_id,'market_id',market_id,'valid_to',valid_to,'reason',p_reason) into v_metadata from bios_core.market_group_members where id=p_resource_id;
    when 'market_language' then
      update bios_core.market_languages set valid_to=statement_timestamp() where id=p_resource_id and valid_to is null;
      if not found then raise exception 'active relationship not found'; end if;
      select jsonb_build_object('market_id',market_id,'language_id',language_id,'valid_to',valid_to,'reason',p_reason) into v_metadata from bios_core.market_languages where id=p_resource_id;
    else raise exception 'unsupported relationship resource type';
  end case;
  perform bios_internal.write_reference_audit(p_actor_identifier,'reference.relationship_ended',p_resource_type,p_resource_id,p_correlation_id,v_metadata);
end $$;

alter table bios_core.geographies enable row level security;
alter table bios_core.geography_relationships enable row level security;
alter table bios_core.markets enable row level security;
alter table bios_core.market_geographies enable row level security;
alter table bios_core.market_groups enable row level security;
alter table bios_core.market_group_members enable row level security;
alter table bios_core.languages enable row level security;
alter table bios_core.market_languages enable row level security;

create policy geographies_active_read on bios_core.geographies for select to authenticated using(status='active');
create policy geography_relationships_active_read on bios_core.geography_relationships for select to authenticated using(valid_to is null and exists(select 1 from bios_core.geographies s where s.id=subject_geography_id and s.status='active') and exists(select 1 from bios_core.geographies o where o.id=object_geography_id and o.status='active'));
create policy markets_active_read on bios_core.markets for select to authenticated using(status='active');
create policy market_geographies_active_read on bios_core.market_geographies for select to authenticated using(valid_to is null and exists(select 1 from bios_core.markets m where m.id=market_id and m.status='active') and exists(select 1 from bios_core.geographies g where g.id=geography_id and g.status='active'));
create policy market_groups_active_read on bios_core.market_groups for select to authenticated using(status='active');
create policy market_group_members_active_read on bios_core.market_group_members for select to authenticated using(valid_to is null and exists(select 1 from bios_core.market_groups g where g.id=market_group_id and g.status='active') and exists(select 1 from bios_core.markets m where m.id=market_id and m.status='active'));
create policy languages_active_read on bios_core.languages for select to authenticated using(status='active');
create policy market_languages_active_read on bios_core.market_languages for select to authenticated using(valid_to is null and exists(select 1 from bios_core.markets m where m.id=market_id and m.status='active') and exists(select 1 from bios_core.languages l where l.id=language_id and l.status='active'));

grant select on bios_core.geographies,bios_core.geography_relationships,bios_core.markets,bios_core.market_geographies,bios_core.market_groups,bios_core.market_group_members,bios_core.languages,bios_core.market_languages to authenticated;

revoke all on all functions in schema bios_internal from public;
grant execute on function bios_internal.create_geography(text,text,text,text,text,uuid),bios_internal.create_market(text,text,text,text,uuid),bios_internal.create_market_group(text,text,text,text,uuid),bios_internal.create_language(text,text,text,text,text,text,text,uuid),bios_internal.transition_reference_status(text,uuid,text,text,text,uuid),bios_internal.update_geography_metadata(uuid,text,text,text,text,text,uuid),bios_internal.update_market_metadata(uuid,text,text,text,text,uuid),bios_internal.update_market_group_metadata(uuid,text,text,text,text,uuid),bios_internal.update_language_metadata(uuid,text,text,text,text,uuid),bios_internal.add_geography_relationship(uuid,uuid,text,uuid),bios_internal.add_market_geography(uuid,uuid,text,text,uuid),bios_internal.add_market_group_member(uuid,uuid,text,uuid),bios_internal.add_market_language(uuid,uuid,text,uuid),bios_internal.end_reference_relationship(text,uuid,text,text,uuid) to service_role;

comment on table bios_core.geographies is 'Shared platform-governed Geography registry; not a country alias.';
comment on table bios_core.markets is 'Shared commercial/analytical Market registry independent of Geography and priority.';
comment on table bios_core.market_groups is 'Shared configurable Market groups with no mandatory purpose taxonomy.';
comment on table bios_core.languages is 'Governed BIOS language profiles using the DB-003 restricted BCP 47-compatible subset.';
