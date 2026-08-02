-- DB-002 v1.1: BIOS Migration 001 -- Core Platform Foundation

create schema bios_core;
create schema bios_knowledge;
create schema bios_intelligence;
create schema bios_governance;
create schema bios_internal;

revoke all on schema bios_core, bios_knowledge, bios_intelligence, bios_governance, bios_internal from public;
grant usage on schema bios_core, bios_governance to authenticated, service_role;
grant usage on schema bios_internal to authenticated, service_role;

create table bios_core.profiles (
  id uuid primary key default gen_random_uuid(),
  auth_user_id uuid not null unique references auth.users(id) on delete restrict,
  display_name text not null,
  preferred_language_code text,
  status text not null default 'active',
  created_at timestamptz not null default transaction_timestamp(),
  updated_at timestamptz not null default transaction_timestamp(),
  constraint profiles_display_name_check check (display_name = btrim(display_name) and char_length(display_name) between 1 and 200),
  constraint profiles_language_check check (preferred_language_code is null or char_length(preferred_language_code) between 2 and 35),
  constraint profiles_status_check check (status in ('active', 'suspended', 'deactivated'))
);

create table bios_core.tenants (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  name text not null,
  status text not null default 'provisioning',
  default_locale text,
  default_time_zone text,
  created_at timestamptz not null default transaction_timestamp(),
  updated_at timestamptz not null default transaction_timestamp(),
  activated_at timestamptz,
  archived_at timestamptz,
  constraint tenants_code_check check (code ~ '^[a-z][a-z0-9_]*$'),
  constraint tenants_name_check check (name = btrim(name) and char_length(name) between 1 and 200),
  constraint tenants_status_check check (status in ('provisioning', 'active', 'suspended', 'archived')),
  constraint tenants_timestamps_check check (
    (status = 'provisioning' and activated_at is null and archived_at is null) or
    (status in ('active', 'suspended') and activated_at is not null and archived_at is null) or
    (status = 'archived' and activated_at is not null and archived_at is not null)
  )
);

create index tenants_status_idx on bios_core.tenants(status);

create table bios_core.tenant_memberships (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references bios_core.tenants(id) on delete restrict,
  profile_id uuid not null references bios_core.profiles(id) on delete restrict,
  status text not null default 'invited',
  invited_at timestamptz not null default transaction_timestamp(),
  activated_at timestamptz,
  suspended_at timestamptz,
  revoked_at timestamptz,
  valid_from timestamptz,
  valid_until timestamptz,
  created_by_profile_id uuid references bios_core.profiles(id) on delete restrict,
  created_at timestamptz not null default transaction_timestamp(),
  updated_at timestamptz not null default transaction_timestamp(),
  constraint tenant_memberships_id_tenant_unique unique (id, tenant_id),
  constraint tenant_memberships_status_check check (status in ('invited', 'active', 'suspended', 'revoked')),
  constraint tenant_memberships_validity_check check (valid_until is null or (valid_from is not null and valid_until > valid_from)),
  constraint tenant_memberships_timestamps_check check (
    (status = 'invited' and activated_at is null and suspended_at is null and revoked_at is null and valid_from is null) or
    (status = 'active' and activated_at is not null and suspended_at is null and revoked_at is null and valid_from is not null) or
    (status = 'suspended' and activated_at is not null and suspended_at is not null and revoked_at is null and valid_from is not null) or
    (status = 'revoked' and revoked_at is not null)
  )
);

create unique index tenant_memberships_current_uidx on bios_core.tenant_memberships(tenant_id, profile_id) where status <> 'revoked';
create index tenant_memberships_profile_idx on bios_core.tenant_memberships(profile_id);
create index tenant_memberships_tenant_status_idx on bios_core.tenant_memberships(tenant_id, status);
create index tenant_memberships_active_lookup_idx on bios_core.tenant_memberships(profile_id, tenant_id, valid_from, valid_until) where status = 'active';

create table bios_core.roles (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  name text not null,
  description text not null default '',
  can_manage_memberships boolean not null default false,
  can_manage_role_assignments boolean not null default false,
  can_read_audit boolean not null default false,
  is_assignable boolean not null default true,
  status text not null default 'active',
  created_at timestamptz not null default transaction_timestamp(),
  updated_at timestamptz not null default transaction_timestamp(),
  constraint roles_code_check check (code ~ '^[a-z][a-z0-9_]*$'),
  constraint roles_name_check check (name = btrim(name) and char_length(name) > 0),
  constraint roles_description_check check (char_length(description) <= 1000),
  constraint roles_status_check check (status in ('active', 'deprecated'))
);

create table bios_core.membership_roles (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  tenant_membership_id uuid not null,
  role_id uuid not null references bios_core.roles(id) on delete restrict,
  granted_by_profile_id uuid references bios_core.profiles(id) on delete restrict,
  granted_at timestamptz not null default transaction_timestamp(),
  revoked_by_profile_id uuid references bios_core.profiles(id) on delete restrict,
  revoked_at timestamptz,
  revocation_reason text,
  created_at timestamptz not null default transaction_timestamp(),
  constraint membership_roles_membership_fk foreign key (tenant_membership_id, tenant_id)
    references bios_core.tenant_memberships(id, tenant_id) on delete restrict,
  constraint membership_roles_revocation_check check (
    (revoked_at is null and revoked_by_profile_id is null and revocation_reason is null) or
    (revoked_at is not null and revoked_at >= granted_at)
  ),
  constraint membership_roles_reason_check check (revocation_reason is null or char_length(revocation_reason) <= 500)
);

create unique index membership_roles_current_uidx on bios_core.membership_roles(tenant_membership_id, role_id) where revoked_at is null;
create index membership_roles_membership_idx on bios_core.membership_roles(tenant_id, tenant_membership_id);
create index membership_roles_role_idx on bios_core.membership_roles(tenant_id, role_id);
create index membership_roles_current_idx on bios_core.membership_roles(tenant_id, tenant_membership_id, role_id) where revoked_at is null;

create table bios_governance.audit_events (
  id uuid primary key default gen_random_uuid(),
  scope_type text not null,
  tenant_id uuid references bios_core.tenants(id) on delete restrict,
  actor_type text not null,
  actor_profile_id uuid references bios_core.profiles(id) on delete restrict,
  actor_identifier text,
  action text not null,
  resource_type text not null,
  resource_id uuid,
  outcome text not null,
  correlation_id uuid not null default gen_random_uuid(),
  occurred_at timestamptz not null default transaction_timestamp(),
  metadata jsonb not null default '{}'::jsonb,
  constraint audit_scope_check check ((scope_type = 'tenant' and tenant_id is not null) or (scope_type = 'platform' and tenant_id is null)),
  constraint audit_actor_type_check check (actor_type in ('user', 'service', 'platform_admin', 'system')),
  constraint audit_actor_check check ((actor_type = 'user' and actor_profile_id is not null and actor_identifier is null) or (actor_type <> 'user' and actor_profile_id is null and actor_identifier is not null)),
  constraint audit_actor_identifier_check check (actor_identifier is null or char_length(actor_identifier) <= 200),
  constraint audit_action_check check (action in ('tenant.created','tenant.status_changed','membership.invited','membership.activated','membership.suspended','membership.revoked','role.granted','role.revoked','platform.privileged_action')),
  constraint audit_resource_check check (resource_type ~ '^[a-z][a-z0-9_]*$' and resource_type in ('tenant','profile','tenant_membership','role','membership_role','platform')),
  constraint audit_outcome_check check (outcome in ('succeeded','denied','failed')),
  constraint audit_metadata_check check (jsonb_typeof(metadata) = 'object' and octet_length(metadata::text) <= 8192)
);

create index audit_events_tenant_time_idx on bios_governance.audit_events(tenant_id, occurred_at desc);
create index audit_events_actor_time_idx on bios_governance.audit_events(actor_profile_id, occurred_at desc);
create index audit_events_correlation_idx on bios_governance.audit_events(correlation_id);
create index audit_events_resource_idx on bios_governance.audit_events(resource_type, resource_id);

insert into bios_core.roles(code,name,description,can_manage_memberships,can_manage_role_assignments,can_read_audit)
values ('tenant_admin','Tenant administrator','Tenant-scoped administration.',true,true,true),
       ('analyst','Analyst','Ordinary analytical work in later migrations.',false,false,false),
       ('viewer','Viewer','Read-only work in later migrations.',false,false,false)
on conflict (code) do nothing;

do $$
begin
  if exists (
    select 1 from bios_core.roles where
      (code = 'tenant_admin' and not (can_manage_memberships and can_manage_role_assignments and can_read_audit and is_assignable and status='active')) or
      (code in ('analyst','viewer') and (can_manage_memberships or can_manage_role_assignments or can_read_audit or not is_assignable or status<>'active'))
  ) then raise exception 'incompatible BIOS role seed definitions'; end if;
end $$;

create function bios_internal.current_profile_id() returns uuid
language sql stable security definer set search_path = '' as $$
  select p.id from bios_core.profiles p where p.auth_user_id = auth.uid() and p.status = 'active'
$$;

create function bios_internal.has_active_membership(p_tenant_id uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists(select 1 from bios_core.tenant_memberships m join bios_core.tenants t on t.id=m.tenant_id
    where m.tenant_id=p_tenant_id and m.profile_id=bios_internal.current_profile_id() and m.status='active'
      and t.status='active' and m.valid_from <= statement_timestamp() and (m.valid_until is null or m.valid_until > statement_timestamp()))
$$;

create function bios_internal.has_capability(p_tenant_id uuid, p_capability text) returns boolean
language sql stable security definer set search_path = '' as $$
  select bios_internal.has_active_membership(p_tenant_id) and exists(
    select 1 from bios_core.tenant_memberships m join bios_core.membership_roles mr on mr.tenant_membership_id=m.id and mr.tenant_id=m.tenant_id
    join bios_core.roles r on r.id=mr.role_id where m.tenant_id=p_tenant_id and m.profile_id=bios_internal.current_profile_id()
      and mr.revoked_at is null and r.status='active' and case p_capability when 'manage_memberships' then r.can_manage_memberships
      when 'manage_role_assignments' then r.can_manage_role_assignments when 'read_audit' then r.can_read_audit else false end)
$$;

create function bios_internal.touch_updated_at() returns trigger language plpgsql set search_path='' as $$
begin new.updated_at=transaction_timestamp(); return new; end $$;

create function bios_internal.protect_immutable_fields() returns trigger language plpgsql set search_path='' as $$
begin
  if new.id<>old.id or new.created_at<>old.created_at then raise exception 'immutable fields cannot be changed'; end if;
  if tg_table_name='profiles' and (to_jsonb(new)->>'auth_user_id') is distinct from (to_jsonb(old)->>'auth_user_id') then raise exception 'auth_user_id is immutable'; end if;
  if tg_table_name='tenant_memberships' and ((to_jsonb(new)->>'tenant_id') is distinct from (to_jsonb(old)->>'tenant_id') or (to_jsonb(new)->>'profile_id') is distinct from (to_jsonb(old)->>'profile_id') or (to_jsonb(new)->>'invited_at') is distinct from (to_jsonb(old)->>'invited_at')) then raise exception 'membership ownership is immutable'; end if;
  if tg_table_name='tenants' and (to_jsonb(old)->>'status')<>'provisioning' and (to_jsonb(new)->>'code') is distinct from (to_jsonb(old)->>'code') then raise exception 'activated tenant code is immutable'; end if;
  if tg_table_name='roles' and (to_jsonb(new)->>'code') is distinct from (to_jsonb(old)->>'code') then raise exception 'role code is immutable'; end if;
  if tg_table_name='membership_roles' and ((to_jsonb(new)->>'tenant_id') is distinct from (to_jsonb(old)->>'tenant_id') or (to_jsonb(new)->>'tenant_membership_id') is distinct from (to_jsonb(old)->>'tenant_membership_id') or (to_jsonb(new)->>'role_id') is distinct from (to_jsonb(old)->>'role_id') or (to_jsonb(new)->>'granted_by_profile_id') is distinct from (to_jsonb(old)->>'granted_by_profile_id') or (to_jsonb(new)->>'granted_at') is distinct from (to_jsonb(old)->>'granted_at')) then raise exception 'role grant episode fields are immutable'; end if;
  return new;
end $$;

create function bios_internal.reject_delete() returns trigger language plpgsql set search_path='' as $$ begin raise exception 'historical BIOS rows cannot be deleted'; end $$;
create function bios_internal.reject_audit_mutation() returns trigger language plpgsql set search_path='' as $$ begin raise exception 'audit events are append-only'; end $$;

create trigger profiles_immutable before update on bios_core.profiles for each row execute function bios_internal.protect_immutable_fields();
create trigger profiles_touch before update on bios_core.profiles for each row execute function bios_internal.touch_updated_at();
create trigger tenants_immutable before update on bios_core.tenants for each row execute function bios_internal.protect_immutable_fields();
create trigger tenants_touch before update on bios_core.tenants for each row execute function bios_internal.touch_updated_at();
create trigger memberships_immutable before update on bios_core.tenant_memberships for each row execute function bios_internal.protect_immutable_fields();
create trigger memberships_touch before update on bios_core.tenant_memberships for each row execute function bios_internal.touch_updated_at();
create trigger roles_touch before update on bios_core.roles for each row execute function bios_internal.touch_updated_at();
create trigger roles_immutable before update on bios_core.roles for each row execute function bios_internal.protect_immutable_fields();
create trigger membership_roles_immutable before update on bios_core.membership_roles for each row execute function bios_internal.protect_immutable_fields();
create trigger memberships_no_delete before delete on bios_core.tenant_memberships for each row execute function bios_internal.reject_delete();
create trigger membership_roles_no_delete before delete on bios_core.membership_roles for each row execute function bios_internal.reject_delete();
create trigger audit_append_only before update or delete on bios_governance.audit_events for each row execute function bios_internal.reject_audit_mutation();

create function bios_internal.assert_last_admin(p_tenant_id uuid, p_excluded_membership uuid, p_excluded_grant uuid default null) returns void
language plpgsql security definer set search_path='' as $$
begin
  perform 1 from bios_core.tenants where id=p_tenant_id for update;
  if not exists(select 1 from bios_core.tenant_memberships m join bios_core.profiles p on p.id=m.profile_id
    join bios_core.membership_roles mr on mr.tenant_membership_id=m.id and mr.tenant_id=m.tenant_id
    join bios_core.roles r on r.id=mr.role_id where m.tenant_id=p_tenant_id and m.id<>p_excluded_membership
      and (p_excluded_grant is null or mr.id<>p_excluded_grant) and m.status='active' and p.status='active'
      and m.valid_from<=statement_timestamp() and (m.valid_until is null or m.valid_until>statement_timestamp())
      and mr.revoked_at is null and r.code='tenant_admin' and r.status='active')
  then raise exception 'cannot remove the last active tenant administrator'; end if;
end $$;

create function bios_internal.bootstrap_tenant(p_code text,p_name text,p_initial_profile_id uuid,p_actor_identifier text,p_correlation_id uuid default gen_random_uuid()) returns uuid
language plpgsql security definer set search_path='' as $$
declare v_tenant uuid; v_membership uuid; v_role uuid; v_grant uuid;
begin
  if auth.role()<>'service_role' then raise exception 'service role required'; end if;
  if p_actor_identifier is null or char_length(p_actor_identifier)>200 then raise exception 'safe actor identifier required'; end if;
  if not exists(select 1 from bios_core.profiles where id=p_initial_profile_id and status='active') then raise exception 'active initial profile required'; end if;
  insert into bios_core.tenants(code,name,status,activated_at) values(p_code,p_name,'active',transaction_timestamp()) returning id into v_tenant;
  insert into bios_core.tenant_memberships(tenant_id,profile_id,status,activated_at,valid_from) values(v_tenant,p_initial_profile_id,'active',transaction_timestamp(),transaction_timestamp()) returning id into v_membership;
  select id into strict v_role from bios_core.roles where code='tenant_admin' and status='active' and is_assignable;
  insert into bios_core.membership_roles(tenant_id,tenant_membership_id,role_id) values(v_tenant,v_membership,v_role) returning id into v_grant;
  insert into bios_governance.audit_events(scope_type,tenant_id,actor_type,actor_identifier,action,resource_type,resource_id,outcome,correlation_id,metadata)
  values ('tenant',v_tenant,'service',p_actor_identifier,'tenant.created','tenant',v_tenant,'succeeded',p_correlation_id,'{}'),
         ('tenant',v_tenant,'service',p_actor_identifier,'membership.activated','tenant_membership',v_membership,'succeeded',p_correlation_id,'{}'),
         ('tenant',v_tenant,'service',p_actor_identifier,'role.granted','membership_role',v_grant,'succeeded',p_correlation_id,jsonb_build_object('role_code','tenant_admin'));
  return v_tenant;
end $$;

create function bios_internal.invite_member(p_tenant_id uuid,p_profile_id uuid,p_valid_until timestamptz default null,p_correlation_id uuid default gen_random_uuid()) returns uuid
language plpgsql security definer set search_path='' as $$
declare v_actor uuid:=bios_internal.current_profile_id(); v_id uuid;
begin
  if not bios_internal.has_capability(p_tenant_id,'manage_memberships') then raise exception 'not authorized'; end if;
  if p_profile_id=v_actor then raise exception 'self invitation is not permitted'; end if;
  insert into bios_core.tenant_memberships(tenant_id,profile_id,created_by_profile_id,valid_until) values(p_tenant_id,p_profile_id,v_actor,p_valid_until) returning id into v_id;
  insert into bios_governance.audit_events(scope_type,tenant_id,actor_type,actor_profile_id,action,resource_type,resource_id,outcome,correlation_id)
  values('tenant',p_tenant_id,'user',v_actor,'membership.invited','tenant_membership',v_id,'succeeded',p_correlation_id);
  return v_id;
end $$;

create function bios_internal.transition_membership(p_membership_id uuid,p_new_status text,p_reason text default null,p_correlation_id uuid default gen_random_uuid()) returns void
language plpgsql security definer set search_path='' as $$
declare v_actor uuid:=bios_internal.current_profile_id(); v_m bios_core.tenant_memberships%rowtype; v_action text;
begin
  select * into strict v_m from bios_core.tenant_memberships where id=p_membership_id for update;
  if not bios_internal.has_capability(v_m.tenant_id,'manage_memberships') then raise exception 'not authorized'; end if;
  if p_new_status not in ('active','suspended','revoked') or v_m.status='revoked' or
     not ((v_m.status='invited' and p_new_status in ('active','revoked')) or (v_m.status='active' and p_new_status in ('suspended','revoked')) or (v_m.status='suspended' and p_new_status in ('active','revoked'))) then raise exception 'invalid membership transition'; end if;
  if p_new_status in ('suspended','revoked') then perform bios_internal.assert_last_admin(v_m.tenant_id,v_m.id,null); end if;
  update bios_core.tenant_memberships set status=p_new_status,
    activated_at=case when p_new_status='active' then coalesce(activated_at,transaction_timestamp()) else activated_at end,
    valid_from=case when p_new_status='active' then coalesce(valid_from,transaction_timestamp()) else valid_from end,
    suspended_at=case when p_new_status='suspended' then transaction_timestamp() else null end,
    revoked_at=case when p_new_status='revoked' then transaction_timestamp() else null end where id=p_membership_id;
  v_action='membership.'||case p_new_status when 'active' then 'activated' else p_new_status end;
  insert into bios_governance.audit_events(scope_type,tenant_id,actor_type,actor_profile_id,action,resource_type,resource_id,outcome,correlation_id,metadata)
  values('tenant',v_m.tenant_id,'user',v_actor,v_action,'tenant_membership',v_m.id,'succeeded',p_correlation_id,jsonb_build_object('from_status',v_m.status,'to_status',p_new_status,'reason',p_reason));
end $$;

create function bios_internal.grant_role(p_membership_id uuid,p_role_code text,p_correlation_id uuid default gen_random_uuid()) returns uuid
language plpgsql security definer set search_path='' as $$
declare v_actor uuid:=bios_internal.current_profile_id(); v_m bios_core.tenant_memberships%rowtype; v_role uuid; v_id uuid;
begin
  select * into strict v_m from bios_core.tenant_memberships where id=p_membership_id for update;
  if not bios_internal.has_capability(v_m.tenant_id,'manage_role_assignments') then raise exception 'not authorized'; end if;
  if v_m.status='revoked' then raise exception 'cannot grant a role to a revoked membership'; end if;
  select id into strict v_role from bios_core.roles where code=p_role_code and status='active' and is_assignable;
  insert into bios_core.membership_roles(tenant_id,tenant_membership_id,role_id,granted_by_profile_id) values(v_m.tenant_id,v_m.id,v_role,v_actor) returning id into v_id;
  insert into bios_governance.audit_events(scope_type,tenant_id,actor_type,actor_profile_id,action,resource_type,resource_id,outcome,correlation_id,metadata)
  values('tenant',v_m.tenant_id,'user',v_actor,'role.granted','membership_role',v_id,'succeeded',p_correlation_id,jsonb_build_object('role_code',p_role_code));
  return v_id;
end $$;

create function bios_internal.revoke_role(p_membership_role_id uuid,p_reason text,p_correlation_id uuid default gen_random_uuid()) returns void
language plpgsql security definer set search_path='' as $$
declare v_actor uuid:=bios_internal.current_profile_id(); v_mr bios_core.membership_roles%rowtype; v_code text;
begin
  if p_reason is null or char_length(p_reason)>500 then raise exception 'safe revocation reason required'; end if;
  select mr.* into strict v_mr from bios_core.membership_roles mr where mr.id=p_membership_role_id for update;
  select r.code into strict v_code from bios_core.roles r where r.id=v_mr.role_id;
  if v_mr.revoked_at is not null or not bios_internal.has_capability(v_mr.tenant_id,'manage_role_assignments') then raise exception 'not authorized'; end if;
  if v_code='tenant_admin' then perform bios_internal.assert_last_admin(v_mr.tenant_id,v_mr.tenant_membership_id,v_mr.id); end if;
  update bios_core.membership_roles set revoked_at=transaction_timestamp(),revoked_by_profile_id=v_actor,revocation_reason=p_reason where id=v_mr.id;
  insert into bios_governance.audit_events(scope_type,tenant_id,actor_type,actor_profile_id,action,resource_type,resource_id,outcome,correlation_id,metadata)
  values('tenant',v_mr.tenant_id,'user',v_actor,'role.revoked','membership_role',v_mr.id,'succeeded',p_correlation_id,jsonb_build_object('role_code',v_code,'reason',p_reason));
end $$;

create function bios_internal.transition_tenant(p_tenant_id uuid,p_new_status text,p_reason text,p_actor_identifier text,p_correlation_id uuid default gen_random_uuid()) returns void
language plpgsql security definer set search_path='' as $$
declare v_old text;
begin
  if auth.role()<>'service_role' then raise exception 'service role required'; end if;
  if p_actor_identifier is null or char_length(p_actor_identifier)>200 then raise exception 'safe actor identifier required'; end if;
  select status into strict v_old from bios_core.tenants where id=p_tenant_id for update;
  if not ((v_old='active' and p_new_status in ('suspended','archived')) or (v_old='suspended' and p_new_status in ('active','archived'))) then raise exception 'invalid tenant transition'; end if;
  update bios_core.tenants set status=p_new_status,archived_at=case when p_new_status='archived' then transaction_timestamp() else null end where id=p_tenant_id;
  insert into bios_governance.audit_events(scope_type,tenant_id,actor_type,actor_identifier,action,resource_type,resource_id,outcome,correlation_id,metadata)
  values('tenant',p_tenant_id,'service',p_actor_identifier,'tenant.status_changed','tenant',p_tenant_id,'succeeded',p_correlation_id,jsonb_build_object('from_status',v_old,'to_status',p_new_status,'reason',p_reason));
end $$;

alter table bios_core.profiles enable row level security;
alter table bios_core.tenants enable row level security;
alter table bios_core.tenant_memberships enable row level security;
alter table bios_core.roles enable row level security;
alter table bios_core.membership_roles enable row level security;
alter table bios_governance.audit_events enable row level security;

create policy profiles_self_select on bios_core.profiles for select to authenticated using (auth_user_id=auth.uid() and status='active');
create policy profiles_self_insert on bios_core.profiles for insert to authenticated with check (auth_user_id=auth.uid() and status='active');
create policy profiles_self_update on bios_core.profiles for update to authenticated using (auth_user_id=auth.uid() and status='active') with check (auth_user_id=auth.uid() and status='active');
create policy tenants_member_select on bios_core.tenants for select to authenticated using (bios_internal.has_active_membership(id));
create policy memberships_self_or_admin_select on bios_core.tenant_memberships for select to authenticated using (bios_internal.has_active_membership(tenant_id) and (profile_id=bios_internal.current_profile_id() or bios_internal.has_capability(tenant_id,'manage_memberships')));
create policy roles_member_select on bios_core.roles for select to authenticated using (status='active' and is_assignable and exists(select 1 from bios_core.tenant_memberships m where m.profile_id=bios_internal.current_profile_id() and bios_internal.has_active_membership(m.tenant_id)));
create policy membership_roles_self_or_admin_select on bios_core.membership_roles for select to authenticated using (bios_internal.has_active_membership(tenant_id) and (exists(select 1 from bios_core.tenant_memberships m where m.id=tenant_membership_id and m.profile_id=bios_internal.current_profile_id()) or bios_internal.has_capability(tenant_id,'manage_role_assignments')));
create policy audit_admin_select on bios_governance.audit_events for select to authenticated using (scope_type='tenant' and bios_internal.has_capability(tenant_id,'read_audit'));

grant select on bios_core.profiles to authenticated;
grant insert(auth_user_id,display_name,preferred_language_code) on bios_core.profiles to authenticated;
grant update(display_name,preferred_language_code) on bios_core.profiles to authenticated;
grant select on bios_core.tenants,bios_core.tenant_memberships,bios_core.roles,bios_core.membership_roles,bios_governance.audit_events to authenticated;
grant all on all tables in schema bios_core,bios_governance to service_role;

revoke all on all functions in schema bios_internal from public, anon, authenticated;
grant execute on function bios_internal.current_profile_id(),bios_internal.has_active_membership(uuid),bios_internal.has_capability(uuid,text) to authenticated,service_role;
grant execute on function bios_internal.invite_member(uuid,uuid,timestamptz,uuid),bios_internal.transition_membership(uuid,text,text,uuid),bios_internal.grant_role(uuid,text,uuid),bios_internal.revoke_role(uuid,text,uuid) to authenticated;
grant execute on function bios_internal.bootstrap_tenant(text,text,uuid,text,uuid),bios_internal.transition_tenant(uuid,text,text,text,uuid) to service_role;

comment on schema bios_internal is 'Non-API helpers and narrowly scoped trusted operations for DB-002.';
comment on table bios_governance.audit_events is 'Append-oriented governed events; ordinary callers cannot mutate history.';
