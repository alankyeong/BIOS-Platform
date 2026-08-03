begin;
select plan(49);

select has_schema('bios_core');
select has_schema('bios_knowledge');
select has_schema('bios_intelligence');
select has_schema('bios_governance');
select has_schema('bios_internal');
select has_table('bios_core'::name,'profiles'::name);
select has_table('bios_core'::name,'tenants'::name);
select has_table('bios_core'::name,'tenant_memberships'::name);
select has_table('bios_core'::name,'roles'::name);
select has_table('bios_core'::name,'membership_roles'::name);
select has_table('bios_governance'::name,'audit_events'::name);

select results_eq(
  $$select count(*)::bigint from pg_catalog.pg_tables where (schemaname,tablename) in
    (('bios_core','profiles'),('bios_core','tenants'),('bios_core','tenant_memberships'),
     ('bios_core','roles'),('bios_core','membership_roles'),('bios_governance','audit_events'))$$,
  array[6::bigint], 'all six Migration 001 foundation tables exist');
select is_empty(
  $$select 1 from information_schema.columns where (table_schema,table_name) in
    (('bios_core','profiles'),('bios_core','tenants'),('bios_core','tenant_memberships'),
     ('bios_core','roles'),('bios_core','membership_roles'),('bios_governance','audit_events')) and column_name in
    ('password','encrypted_password','provider','mfa_state','token','workspace_id','client_id','market_id','category_id')$$,
  'no authentication secrets or deferred architecture columns exist');
select results_eq(
  $$select code||':'||can_manage_memberships||':'||can_manage_role_assignments||':'||can_read_audit
      from bios_core.roles order by code$$,
  array['analyst:false:false:false','tenant_admin:true:true:true','viewer:false:false:false'],
  'the three deterministic roles have minimal capabilities');
select results_eq(
  $$select count(*)::bigint from pg_catalog.pg_class c join pg_catalog.pg_namespace n on n.oid=c.relnamespace
    where n.nspname in ('bios_core','bios_governance') and c.relname in
      ('profiles','tenants','tenant_memberships','roles','membership_roles','audit_events') and c.relrowsecurity$$,
  array[6::bigint], 'RLS is enabled on every exposed BIOS table');
select results_eq(
  $$select count(*)::bigint from pg_catalog.pg_proc p join pg_catalog.pg_namespace n on n.oid=p.pronamespace
    where n.nspname='bios_internal' and p.prosecdef and has_function_privilege('public',p.oid,'execute')$$,
  array[0::bigint], 'PUBLIC cannot execute security-definer functions');

insert into auth.users(id,email,encrypted_password,aud,role)
values
 ('10000000-0000-0000-0000-000000000001','admin-a@example.test','','authenticated','authenticated'),
 ('10000000-0000-0000-0000-000000000002','admin-b@example.test','','authenticated','authenticated'),
 ('10000000-0000-0000-0000-000000000003','member@example.test','','authenticated','authenticated'),
 ('10000000-0000-0000-0000-000000000004','inactive@example.test','','authenticated','authenticated'),
 ('10000000-0000-0000-0000-000000000005','expired@example.test','','authenticated','authenticated'),
 ('10000000-0000-0000-0000-000000000006','future@example.test','','authenticated','authenticated'),
 ('10000000-0000-0000-0000-000000000007','suspended-member@example.test','','authenticated','authenticated');

insert into bios_core.profiles(id,auth_user_id,display_name,status) values
 ('20000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000001','Admin A','active'),
 ('20000000-0000-0000-0000-000000000002','10000000-0000-0000-0000-000000000002','Admin B','active'),
 ('20000000-0000-0000-0000-000000000003','10000000-0000-0000-0000-000000000003','Member','active'),
 ('20000000-0000-0000-0000-000000000004','10000000-0000-0000-0000-000000000004','Inactive','suspended'),
 ('20000000-0000-0000-0000-000000000005','10000000-0000-0000-0000-000000000005','Expired','active'),
 ('20000000-0000-0000-0000-000000000006','10000000-0000-0000-0000-000000000006','Future','active'),
 ('20000000-0000-0000-0000-000000000007','10000000-0000-0000-0000-000000000007','Suspended member','active');

select throws_ok(
  $$insert into bios_core.profiles(auth_user_id,display_name) values('10000000-0000-0000-0000-999999999999','Invalid')$$,
  '23503',null,'profile rejects an unknown Auth identity');
select throws_ok(
  $$insert into bios_core.profiles(auth_user_id,display_name) values('10000000-0000-0000-0000-000000000001','Duplicate')$$,
  '23505',null,'profile rejects a duplicate Auth identity');

select set_config('request.jwt.claims','{"role":"service_role"}',true);
set local role service_role;
select lives_ok(
  $$select bios_internal.bootstrap_tenant('tenant_a','Tenant A','20000000-0000-0000-0000-000000000001','test-service','30000000-0000-0000-0000-000000000001')$$,
  'trusted service atomically bootstraps Tenant A');
select lives_ok(
  $$select bios_internal.bootstrap_tenant('tenant_b','Tenant B','20000000-0000-0000-0000-000000000002','test-service','30000000-0000-0000-0000-000000000002')$$,
  'trusted service atomically bootstraps Tenant B');
reset role;

insert into bios_core.tenant_memberships(tenant_id,profile_id,status,activated_at,suspended_at,valid_from,valid_until)
select id,'20000000-0000-0000-0000-000000000004'::uuid,'active',now(),null::timestamptz,now()-interval '1 hour',null::timestamptz from bios_core.tenants where code='tenant_a'
union all select id,'20000000-0000-0000-0000-000000000005'::uuid,'active',now(),null::timestamptz,now()-interval '2 hours',now()-interval '1 hour' from bios_core.tenants where code='tenant_a'
union all select id,'20000000-0000-0000-0000-000000000006'::uuid,'active',now(),null::timestamptz,now()+interval '1 hour',now()+interval '2 hours' from bios_core.tenants where code='tenant_a'
union all select id,'20000000-0000-0000-0000-000000000007'::uuid,'suspended',now(),now(),now()-interval '1 hour',null::timestamptz from bios_core.tenants where code='tenant_a';

select set_config('request.jwt.claims','{"sub":"10000000-0000-0000-0000-000000000004","role":"authenticated"}',true);
set local role authenticated;
select is_empty($$select 1 from bios_core.tenants$$,'suspended profile receives no tenant authorization');
reset role;
select set_config('request.jwt.claims','{"sub":"10000000-0000-0000-0000-000000000005","role":"authenticated"}',true);
set local role authenticated;
select is_empty($$select 1 from bios_core.tenants$$,'expired membership receives no tenant authorization');
reset role;
select set_config('request.jwt.claims','{"sub":"10000000-0000-0000-0000-000000000006","role":"authenticated"}',true);
set local role authenticated;
select is_empty($$select 1 from bios_core.tenants$$,'not-yet-valid membership receives no tenant authorization');
reset role;
select set_config('request.jwt.claims','{"sub":"10000000-0000-0000-0000-000000000007","role":"authenticated"}',true);
set local role authenticated;
select is_empty($$select 1 from bios_core.tenants$$,'suspended membership receives no tenant authorization');
reset role;
update bios_core.tenant_memberships set status='revoked',revoked_at=now() where profile_id='20000000-0000-0000-0000-000000000007';
set local role authenticated;
select is_empty($$select 1 from bios_core.tenants$$,'revoked membership receives no tenant authorization');
reset role;

select set_config('request.jwt.claims','{"sub":"10000000-0000-0000-0000-000000000001","role":"authenticated"}',true);
set local role authenticated;
select results_eq($$select code from bios_core.tenants order by code$$,array['tenant_a'],'Tenant A admin cannot read Tenant B');
select is_empty($$select 1 from bios_core.tenant_memberships m join bios_core.tenants t on t.id=m.tenant_id where t.code='tenant_b'$$,'cross-tenant memberships are hidden');
select throws_ok($$insert into bios_core.tenant_memberships(tenant_id,profile_id) select id,'20000000-0000-0000-0000-000000000003' from bios_core.tenants limit 1$$,'42501',null,'direct membership insert is denied');
select throws_ok($$update bios_core.tenants set status='archived'$$,'42501',null,'direct tenant lifecycle mutation is denied');
select lives_ok(
  $$select bios_internal.transition_membership(bios_internal.invite_member((select id from bios_core.tenants where code='tenant_a'),'20000000-0000-0000-0000-000000000003',null),'active')$$,
  'tenant admin can invite and activate through governed functions');
select lives_ok(
  $$select bios_internal.grant_role((select m.id from bios_core.tenant_memberships m join bios_core.tenants t on t.id=m.tenant_id where t.code='tenant_a' and m.profile_id='20000000-0000-0000-0000-000000000003'),'viewer')$$,
  'tenant admin can grant an assignable role through the governed function');
select throws_ok(
  $$select bios_internal.grant_role((select m.id from bios_core.tenant_memberships m join bios_core.tenants t on t.id=m.tenant_id where t.code='tenant_a' and m.profile_id='20000000-0000-0000-0000-000000000003'),'viewer')$$,
  '23505',null,'repeated current role grant is rejected');
reset role;

select set_config('request.jwt.claims','{"sub":"10000000-0000-0000-0000-000000000002","role":"authenticated"}',true);
set local role authenticated;
select lives_ok(
  $$select bios_internal.transition_membership(bios_internal.invite_member((select id from bios_core.tenants where code='tenant_b'),'20000000-0000-0000-0000-000000000003',null),'active')$$,
  'one profile independently joins Tenant B');
reset role;

select set_config('request.jwt.claims','{"sub":"10000000-0000-0000-0000-000000000003","role":"authenticated"}',true);
set local role authenticated;
select results_eq($$select code from bios_core.tenants order by code$$,array['tenant_a','tenant_b'],'multi-tenant member reads both authorized tenants');
select throws_ok(
  $$select bios_internal.grant_role((select id from bios_core.tenant_memberships limit 1),'tenant_admin')$$,
  'P0001','not authorized','ordinary member cannot escalate privileges');
select throws_ok($$update bios_governance.audit_events set outcome='failed'$$,'42501',null,'ordinary user cannot update audit history');
select throws_ok($$delete from bios_governance.audit_events$$,'42501',null,'ordinary user cannot delete audit history');
reset role;

select throws_ok(
  $$insert into bios_core.membership_roles(tenant_id,tenant_membership_id,role_id)
    select tb.id,ma.id,r.id from bios_core.tenants tb cross join bios_core.tenant_memberships ma cross join bios_core.roles r
    where tb.code='tenant_b' and ma.tenant_id<>(select id from bios_core.tenants where code='tenant_b') and r.code='analyst' limit 1$$,
  '23503',null,'composite FK rejects mismatched tenant assignment');
select throws_ok(
  $$update bios_core.tenant_memberships set tenant_id=(select id from bios_core.tenants where code='tenant_b')
    where id=(select m.id from bios_core.tenant_memberships m join bios_core.tenants t on t.id=m.tenant_id where t.code='tenant_a' limit 1)$$,
  'P0001','membership ownership is immutable','tenant ownership mutation is rejected');
select throws_ok(
  $$insert into bios_governance.audit_events(scope_type,tenant_id,actor_type,actor_identifier,action,resource_type,outcome)
    values('platform',null,'service','test','invalid.action','workspace','succeeded')$$,
  '23514',null,'invalid audit action and resource vocabulary is rejected');
select throws_ok(
  $$insert into bios_governance.audit_events(scope_type,actor_type,actor_identifier,action,resource_type,outcome,metadata)
    values('platform','service','test','platform.privileged_action','platform','succeeded',jsonb_build_object('payload',repeat('x',8200)))$$,
  '23514',null,'oversized audit metadata is rejected');

select set_config('request.jwt.claims','{"sub":"10000000-0000-0000-0000-000000000001","role":"authenticated"}',true);
set local role authenticated;
select throws_ok(
  $$select bios_internal.revoke_role((select mr.id from bios_core.membership_roles mr join bios_core.roles r on r.id=mr.role_id join bios_core.tenant_memberships m on m.id=mr.tenant_membership_id where r.code='tenant_admin' and m.profile_id='20000000-0000-0000-0000-000000000001' and mr.revoked_at is null),'self removal')$$,
  'P0001','cannot remove the last active tenant administrator','last active tenant administrator cannot be removed');
select lives_ok(
  $$select bios_internal.revoke_role((select mr.id from bios_core.membership_roles mr join bios_core.roles r on r.id=mr.role_id join bios_core.tenant_memberships m on m.id=mr.tenant_membership_id where r.code='viewer' and m.profile_id='20000000-0000-0000-0000-000000000003' and mr.revoked_at is null),'rotate grant')$$,
  'role revocation succeeds and preserves its episode');
select lives_ok(
  $$select bios_internal.grant_role((select m.id from bios_core.tenant_memberships m join bios_core.tenants t on t.id=m.tenant_id where t.code='tenant_a' and m.profile_id='20000000-0000-0000-0000-000000000003'),'viewer')$$,
  're-grant creates a new role episode');
reset role;
select results_eq(
  $$select count(*)::bigint from bios_core.membership_roles mr join bios_core.roles r on r.id=mr.role_id where r.code='viewer'$$,
  array[2::bigint], 'role grant history contains both episodes');
select results_eq(
  $$select count(*)::bigint from bios_governance.audit_events where action in ('tenant.created','membership.activated','role.granted','role.revoked')$$,
  array[11::bigint], 'governed successes produced atomic audit events');

select set_config('request.jwt.claims','{"role":"service_role"}',true);
set local role service_role;
select lives_ok(
  $$select bios_internal.transition_tenant((select id from bios_core.tenants where code='tenant_b'),'suspended','security hold','test-service')$$,
  'trusted service governs tenant suspension');
reset role;
select set_config('request.jwt.claims','{"sub":"10000000-0000-0000-0000-000000000002","role":"authenticated"}',true);
set local role authenticated;
select is_empty($$select 1 from bios_core.tenants where code='tenant_b'$$,'suspended tenant denies ordinary access');
reset role;
select results_eq(
  $$select (metadata->>'from_status')||':'||(metadata->>'to_status')||':'||(metadata->>'reason') from bios_governance.audit_events where action='tenant.status_changed' order by occurred_at desc limit 1$$,
  array['active:suspended:security hold'],'tenant status audit contains safe transition metadata');

select * from finish();
rollback;
