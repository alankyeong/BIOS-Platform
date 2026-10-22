begin;
select plan(16);

select has_function('public'::name, 'resolve_bios_user_context'::name);
select is(
  (select pg_catalog.pg_get_function_result(p.oid) from pg_catalog.pg_proc p
    join pg_catalog.pg_namespace n on n.oid=p.pronamespace
    where n.nspname='public' and p.proname='resolve_bios_user_context' and p.pronargs=0),
  'jsonb',
  'resolver returns jsonb'
);
select is(
  (select p.provolatile::text from pg_catalog.pg_proc p join pg_catalog.pg_namespace n on n.oid=p.pronamespace
    where n.nspname='public' and p.proname='resolve_bios_user_context' and p.pronargs=0),
  's'::text,
  'resolver is stable'
);
select is(
  (select p.prosecdef from pg_catalog.pg_proc p join pg_catalog.pg_namespace n on n.oid=p.pronamespace
    where n.nspname='public' and p.proname='resolve_bios_user_context' and p.pronargs=0),
  true,
  'resolver is security definer'
);
select is(
  (select proconfig from pg_catalog.pg_proc p join pg_catalog.pg_namespace n on n.oid=p.pronamespace
    where n.nspname='public' and p.proname='resolve_bios_user_context' and p.pronargs=0),
  array['search_path=""'],
  'resolver has an empty search_path'
);
select ok(not has_function_privilege('public','public.resolve_bios_user_context()','execute'),'PUBLIC cannot execute resolver');
select ok(not has_function_privilege('anon','public.resolve_bios_user_context()','execute'),'anonymous callers cannot execute resolver');
select ok(has_function_privilege('authenticated','public.resolve_bios_user_context()','execute'),'authenticated callers can execute resolver');
select ok(not has_function_privilege('service_role','public.resolve_bios_user_context()','execute'),'service role does not receive the user resolver');
select is_empty(
  $$select 1 from information_schema.parameters where specific_schema='public'
    and specific_name like 'resolve_bios_user_context_%' and parameter_mode in ('IN','INOUT')$$,
  'resolver accepts no caller-supplied authorization context'
);

insert into auth.users(id,email,encrypted_password,aud,role) values
 ('e0000000-0000-0000-0000-000000000001','context-active@example.test','','authenticated','authenticated'),
 ('e0000000-0000-0000-0000-000000000002','context-other@example.test','','authenticated','authenticated'),
 ('e0000000-0000-0000-0000-000000000003','context-inactive@example.test','','authenticated','authenticated');

insert into bios_core.profiles(id,auth_user_id,display_name,preferred_language_code,status) values
 ('e0010000-0000-0000-0000-000000000001','e0000000-0000-0000-0000-000000000001','Context Active','en','active'),
 ('e0010000-0000-0000-0000-000000000002','e0000000-0000-0000-0000-000000000002','Context Other',null,'active'),
 ('e0010000-0000-0000-0000-000000000003','e0000000-0000-0000-0000-000000000003','Context Inactive',null,'suspended');

insert into bios_core.tenants(id,code,name,status,activated_at,default_locale,default_time_zone) values
 ('e0100000-0000-0000-0000-000000000001','context_active','Context Active Tenant','active',statement_timestamp(),'en-MY','Asia/Kuala_Lumpur'),
 ('e0100000-0000-0000-0000-000000000002','context_other','Context Other Tenant','active',statement_timestamp(),null,null),
 ('e0100000-0000-0000-0000-000000000003','context_suspended','Context Suspended Tenant','suspended',statement_timestamp(),null,null),
 ('e0100000-0000-0000-0000-000000000004','context_expired','Context Expired Tenant','active',statement_timestamp(),null,null),
 ('e0100000-0000-0000-0000-000000000005','context_future','Context Future Tenant','active',statement_timestamp(),null,null);

insert into bios_core.tenant_memberships(id,tenant_id,profile_id,status,activated_at,suspended_at,valid_from,valid_until) values
 ('e0110000-0000-0000-0000-000000000001','e0100000-0000-0000-0000-000000000001','e0010000-0000-0000-0000-000000000001','active',statement_timestamp(),null,statement_timestamp()-interval '1 hour',null),
 ('e0110000-0000-0000-0000-000000000002','e0100000-0000-0000-0000-000000000002','e0010000-0000-0000-0000-000000000002','active',statement_timestamp(),null,statement_timestamp()-interval '1 hour',null),
 ('e0110000-0000-0000-0000-000000000003','e0100000-0000-0000-0000-000000000003','e0010000-0000-0000-0000-000000000001','active',statement_timestamp(),null,statement_timestamp()-interval '1 hour',null),
 ('e0110000-0000-0000-0000-000000000004','e0100000-0000-0000-0000-000000000004','e0010000-0000-0000-0000-000000000001','active',statement_timestamp(),null,statement_timestamp()-interval '2 hours',statement_timestamp()-interval '1 hour'),
 ('e0110000-0000-0000-0000-000000000005','e0100000-0000-0000-0000-000000000005','e0010000-0000-0000-0000-000000000001','active',statement_timestamp(),null,statement_timestamp()+interval '1 hour',statement_timestamp()+interval '2 hours');

insert into bios_core.roles(id,code,name,description,is_assignable,status) values
 ('e0130000-0000-0000-0000-000000000001','context_deprecated','Context Deprecated','Deprecated test role.',false,'deprecated');

insert into bios_core.membership_roles(id,tenant_id,tenant_membership_id,role_id,revoked_at,revoked_by_profile_id,revocation_reason) values
 ('e0120000-0000-0000-0000-000000000001','e0100000-0000-0000-0000-000000000001','e0110000-0000-0000-0000-000000000001',(select id from bios_core.roles where code='tenant_admin'),null,null,null),
 ('e0120000-0000-0000-0000-000000000002','e0100000-0000-0000-0000-000000000001','e0110000-0000-0000-0000-000000000001',(select id from bios_core.roles where code='viewer'),statement_timestamp(),null,'expired test grant'),
 ('e0120000-0000-0000-0000-000000000003','e0100000-0000-0000-0000-000000000002','e0110000-0000-0000-0000-000000000002',(select id from bios_core.roles where code='viewer'),null,null,null),
 ('e0120000-0000-0000-0000-000000000004','e0100000-0000-0000-0000-000000000001','e0110000-0000-0000-0000-000000000001','e0130000-0000-0000-0000-000000000001',null,null,null);

select set_config('request.jwt.claims','{"sub":"e0000000-0000-0000-0000-000000000001","role":"authenticated"}',true);
set local role authenticated;
select is(public.resolve_bios_user_context() #>> '{profile,id}','e0010000-0000-0000-0000-000000000001','resolver returns only the caller active profile');
select is(jsonb_array_length(public.resolve_bios_user_context()->'memberships'),1,'inactive, expired, and future Tenant memberships are excluded');
select is(public.resolve_bios_user_context() #>> '{memberships,0,tenant,code}','context_active','resolver returns the active Tenant');
select is(jsonb_array_length(public.resolve_bios_user_context() #> '{memberships,0,roles}'),1,'revoked grants and deprecated roles are excluded');
select is(public.resolve_bios_user_context() #>> '{memberships,0,roles,0,code}','tenant_admin','resolver returns the current active role');
reset role;

select set_config('request.jwt.claims','{"sub":"e0000000-0000-0000-0000-000000000003","role":"authenticated"}',true);
set local role authenticated;
select is(public.resolve_bios_user_context(),null::jsonb,'inactive BIOS profile resolves to no context');

select * from finish();
rollback;
