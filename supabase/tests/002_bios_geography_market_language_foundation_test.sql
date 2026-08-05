begin;
select no_plan();

select has_table('bios_core'::name,'geographies'::name);
select has_table('bios_core'::name,'geography_relationships'::name);
select has_table('bios_core'::name,'markets'::name);
select has_table('bios_core'::name,'market_geographies'::name);
select has_table('bios_core'::name,'market_groups'::name);
select has_table('bios_core'::name,'market_group_members'::name);
select has_table('bios_core'::name,'languages'::name);
select has_table('bios_core'::name,'market_languages'::name);
select results_eq(
  $$select count(*)::bigint from pg_catalog.pg_tables where schemaname='bios_core' and tablename in
    ('geographies','geography_relationships','markets','market_geographies','market_groups','market_group_members','languages','market_languages')$$,
  array[8::bigint], 'exactly eight Migration 002 tables exist');
select results_eq(
  $$select count(*)::bigint from pg_catalog.pg_class c join pg_catalog.pg_namespace n on n.oid=c.relnamespace
    where n.nspname='bios_core' and c.relname in
    ('geographies','geography_relationships','markets','market_geographies','market_groups','market_group_members','languages','market_languages') and c.relrowsecurity$$,
  array[8::bigint], 'RLS is enabled on all eight tables');
select is_empty(
  $$select 1 from information_schema.tables where table_schema like 'bios_%' and
    (table_name like '%workspace%' or table_name like '%client%' or (table_name like '%evidence%' and table_name not in ('evidence','evidence_provenance')) or table_name like '%signal%' or table_name like '%agent%' or table_name like '%vector%' or table_name like '%connector%')$$,
  'excluded table families remain absent');
select is_empty(
  $$select 1 from information_schema.columns where table_schema='bios_core' and table_name in
    ('geographies','geography_relationships','markets','market_geographies','market_groups','market_group_members','languages','market_languages') and
    column_name in ('tenant_id','priority','priority_level','is_priority','group_type','usage_role','primary_language','official_language','supported_language')$$,
  'no tenant, priority, group taxonomy, or language usage semantics exist');
select isnt(
  (select data_type from information_schema.columns where table_schema='bios_core' and table_name='geographies' and column_name='id'),
  null, 'Geography has independent identity');
select isnt(
  (select data_type from information_schema.columns where table_schema='bios_core' and table_name='markets' and column_name='id'),
  null, 'Market has independent identity');
select results_eq(
  $$select (select count(*) from bios_core.geographies)+(select count(*) from bios_core.markets)+(select count(*) from bios_core.market_groups)+(select count(*) from bios_core.languages)$$,
  array[0::bigint], 'Migration 002 seeds no production reference rows');
select results_eq(
  $$select count(*)::bigint from pg_catalog.pg_proc p join pg_catalog.pg_namespace n on n.oid=p.pronamespace
    where n.nspname='bios_internal' and p.prosecdef and has_function_privilege('public',p.oid,'execute')$$,
  array[0::bigint], 'PUBLIC cannot execute security-definer functions');

select throws_ok(
  $$insert into bios_core.geographies(code,name,geography_type) values('A','Invalid','country')$$,
  '23514',null,'invalid stable code is rejected');
insert into bios_core.geographies(code,name,geography_type) values('test_geo','Test geography','other');
select throws_ok(
  $$insert into bios_core.geographies(code,name,geography_type) values('test_geo','Duplicate','country')$$,
  '23505',null,'duplicate stable Geography code is rejected');
select throws_ok(
  $$insert into bios_core.markets(code,name) values('ab',' Market ')$$,
  '23514',null,'trimmed name bounds are enforced');
select throws_ok(
  $$insert into bios_core.geographies(code,name,geography_type) values('bad_type','Bad type','planet')$$,
  '23514',null,'unknown Geography type is rejected');
select throws_ok(
  $$insert into bios_core.markets(code,name,description) values('long_description','Long description',repeat('x',1001))$$,
  '23514',null,'description bound is enforced');
select throws_ok(
  $$insert into bios_core.markets(code,name,status) values('bad_lifecycle','Bad lifecycle','active')$$,
  '23514',null,'lifecycle timestamps are structurally required');
select throws_ok(
  $$insert into bios_core.languages(tag,base_language_subtag,display_name) values('EN','en','English')$$,
  '23514',null,'noncanonical language tag is rejected');
select throws_ok(
  $$insert into bios_core.languages(tag,base_language_subtag,script_subtag,display_name) values('zh-Hans','zh','Hant','Chinese')$$,
  '23514',null,'language tag must agree with components');
select throws_ok(
  $$insert into bios_core.languages(tag,base_language_subtag,display_name,native_name) values('zz','zz','Test',repeat('x',201))$$,
  '23514',null,'native-name bound is enforced');

insert into auth.users(id,email,encrypted_password,aud,role)
values ('81000000-0000-0000-0000-000000000001','reference-user@example.test','','authenticated','authenticated'),
       ('81000000-0000-0000-0000-000000000002','reference-admin@example.test','','authenticated','authenticated');
insert into bios_core.profiles(id,auth_user_id,display_name) values
       ('82000000-0000-0000-0000-000000000001','81000000-0000-0000-0000-000000000001','Reference User'),
       ('82000000-0000-0000-0000-000000000002','81000000-0000-0000-0000-000000000002','Reference Admin');

select set_config('request.jwt.claims','{"role":"service_role"}',true);
set local role service_role;
select lives_ok($$select bios_internal.bootstrap_tenant('reference_admin_tenant','Reference Admin Tenant','82000000-0000-0000-0000-000000000002','reference-test')$$,'Migration 001 tenant_admin fixture is established');
select lives_ok($$select bios_internal.create_geography('world_geo','World','macro_region',null,'reference-test')$$,'trusted service creates World geography');
select lives_ok($$select bios_internal.create_geography('asia_geo','Asia','macro_region',null,'reference-test')$$,'trusted service creates Asia geography');
select lives_ok($$select bios_internal.create_geography('mainland_china_geo','Mainland China','country',null,'reference-test')$$,'trusted service creates Mainland China geography');
select lives_ok($$select bios_internal.create_geography('hong_kong_geo','Hong Kong','territory',null,'reference-test')$$,'trusted service creates Hong Kong geography');
select lives_ok($$select bios_internal.create_geography('taiwan_geo','Taiwan','territory',null,'reference-test')$$,'trusted service creates Taiwan geography');
select lives_ok($$select bios_internal.create_market('mainland_china_market','Mainland China',null,'reference-test')$$,'trusted service creates Mainland China Market');
select lives_ok($$select bios_internal.create_market('hong_kong_market','Hong Kong',null,'reference-test')$$,'trusted service creates Hong Kong Market');
select lives_ok($$select bios_internal.create_market('taiwan_market','Taiwan',null,'reference-test')$$,'trusted service creates Taiwan Market');
select lives_ok($$select bios_internal.create_market('regional_market','Regional Market',null,'reference-test')$$,'trusted service creates a multi-geography Market');
select lives_ok($$select bios_internal.create_market_group('greater_china_group','Greater China',null,'reference-test')$$,'trusted service creates ordinary Greater China group');
select lives_ok($$select bios_internal.create_language('zh-Hans','zh','Hans',null,'Simplified Chinese','简体中文','reference-test')$$,'restricted tag zh-Hans is valid');
select lives_ok($$select bios_internal.create_language('zh-Hant','zh','Hant',null,'Traditional Chinese','繁體中文','reference-test')$$,'restricted tag zh-Hant is valid');
select lives_ok($$select bios_internal.create_language('en','en',null,null,'English','English','reference-test')$$,'base language tag en is valid');
select lives_ok($$select bios_internal.create_language('es-419','es',null,'419','Latin American Spanish',null,'reference-test')$$,'numeric region language tag is valid');
reset role;
select lives_ok($$
  select bios_internal.transition_reference_status(v.kind,v.id,'active','test activation','reference-test')
  from (
    select 'geography' kind,id from bios_core.geographies where code<>'test_geo'
    union all select 'market',id from bios_core.markets
    union all select 'market_group',id from bios_core.market_groups
    union all select 'language',id from bios_core.languages
  ) v$$,'trusted service activates all representative references');
reset role;

select results_eq(
  $$select count(*)::bigint from bios_governance.audit_events where action='reference.created'$$,
  array[14::bigint], 'every base reference creation is audited atomically');
select results_eq(
  $$select count(*)::bigint from bios_governance.audit_events where action='reference.status_changed'$$,
  array[14::bigint], 'every base activation is audited atomically');
select throws_ok(
  $$insert into bios_governance.audit_events(scope_type,actor_type,actor_identifier,action,resource_type,outcome) values('platform','service','test','reference.deleted','market','succeeded')$$,
  '23514',null,'reference.deleted remains unauthorized');
select throws_ok(
  $$insert into bios_governance.audit_events(scope_type,actor_type,actor_identifier,action,resource_type,outcome) values('platform','service','test','reference.created','unauthorized_reference_resource','succeeded')$$,
  '23514',null,'unknown Migration 002 audit resource remains rejected');

select set_config('request.jwt.claims','{"role":"service_role"}',true);
select lives_ok($$select bios_internal.add_geography_relationship((select id from bios_core.geographies where code='world_geo'),(select id from bios_core.geographies where code='asia_geo'),'reference-test')$$,'World contains Asia');
select lives_ok($$select bios_internal.add_geography_relationship((select id from bios_core.geographies where code='asia_geo'),(select id from bios_core.geographies where code='mainland_china_geo'),'reference-test')$$,'Asia contains Mainland China');
select throws_ok($$select bios_internal.add_geography_relationship((select id from bios_core.geographies where code='mainland_china_geo'),(select id from bios_core.geographies where code='world_geo'),'reference-test')$$,'P0001','geography relationship would create a cycle','transitive Geography cycle is rejected');
select throws_ok($$select bios_internal.add_geography_relationship((select id from bios_core.geographies where code='asia_geo'),(select id from bios_core.geographies where code='asia_geo'),'reference-test')$$,'P0001','geography cannot contain itself','self Geography link is rejected');
select throws_ok($$select bios_internal.add_geography_relationship((select id from bios_core.geographies where code='world_geo'),(select id from bios_core.geographies where code='asia_geo'),'reference-test')$$,'23505',null,'duplicate active Geography relationship is rejected');
select lives_ok($$select bios_internal.end_reference_relationship('geography_relationship',(select id from bios_core.geography_relationships where subject_geography_id=(select id from bios_core.geographies where code='world_geo') and object_geography_id=(select id from bios_core.geographies where code='asia_geo') and valid_to is null),'test correction','reference-test')$$,'Geography relationship episode can end');
select lives_ok($$select bios_internal.add_geography_relationship((select id from bios_core.geographies where code='world_geo'),(select id from bios_core.geographies where code='asia_geo'),'reference-test')$$,'ended Geography relationship permits a new episode');
select throws_ok($$insert into bios_core.geography_relationships(subject_geography_id,object_geography_id) values((select id from bios_core.geographies where code='asia_geo'),'ffffffff-ffff-ffff-ffff-ffffffffffff')$$,'23503',null,'invalid Geography endpoint FK is rejected');
select throws_ok($$insert into bios_core.geography_relationships(subject_geography_id,object_geography_id,relationship_type) values((select id from bios_core.geographies where code='asia_geo'),(select id from bios_core.geographies where code='hong_kong_geo'),'parent')$$,'23514',null,'unknown Geography relationship vocabulary is rejected');

select lives_ok($$select bios_internal.add_market_geography((select id from bios_core.markets where code='regional_market'),(select id from bios_core.geographies where code='mainland_china_geo'),'included','reference-test')$$,'regional Market includes Mainland China geography');
select lives_ok($$select bios_internal.add_market_geography((select id from bios_core.markets where code='regional_market'),(select id from bios_core.geographies where code='hong_kong_geo'),'included','reference-test')$$,'one Market relates to multiple geographies');
select lives_ok($$select bios_internal.add_market_geography((select id from bios_core.markets where code='mainland_china_market'),(select id from bios_core.geographies where code='mainland_china_geo'),'included','reference-test')$$,'one Geography relates to multiple Markets');
select throws_ok($$select bios_internal.add_market_geography((select id from bios_core.markets where code='regional_market'),(select id from bios_core.geographies where code='hong_kong_geo'),'included','reference-test')$$,'23505',null,'duplicate active Market-Geography episode is rejected through the governed path');
select lives_ok($$select bios_internal.end_reference_relationship('market_geography',(select id from bios_core.market_geographies where market_id=(select id from bios_core.markets where code='regional_market') and geography_id=(select id from bios_core.geographies where code='hong_kong_geo') and relationship_role='included' and valid_to is null),'episode history test','reference-test')$$,'ordinary included Market-Geography episode ends through the governed path');
select lives_ok($$select bios_internal.add_market_geography((select id from bios_core.markets where code='regional_market'),(select id from bios_core.geographies where code='hong_kong_geo'),'included','reference-test')$$,'ended Market-Geography episode permits a later new episode');
select results_eq($$select count(*)::bigint from bios_core.market_geographies where market_id=(select id from bios_core.markets where code='regional_market') and geography_id=(select id from bios_core.geographies where code='hong_kong_geo') and relationship_role='included'$$,array[2::bigint],'Market-Geography history retains both episode rows');
select results_eq($$select count(*)::bigint from bios_core.market_geographies where market_id=(select id from bios_core.markets where code='regional_market') and geography_id=(select id from bios_core.geographies where code='hong_kong_geo') and relationship_role='included' and valid_to is not null$$,array[1::bigint],'original Market-Geography episode remains ended');
select results_eq($$select count(*)::bigint from bios_core.market_geographies where market_id=(select id from bios_core.markets where code='regional_market') and geography_id=(select id from bios_core.geographies where code='hong_kong_geo') and relationship_role='included' and valid_to is null$$,array[1::bigint],'replacement Market-Geography episode is active');
select results_eq($$select count(distinct id)::bigint from bios_core.market_geographies where market_id=(select id from bios_core.markets where code='regional_market') and geography_id=(select id from bios_core.geographies where code='hong_kong_geo') and relationship_role='included'$$,array[2::bigint],'Market-Geography history uses distinct episode identities');
select throws_ok($$select bios_internal.add_market_geography((select id from bios_core.markets where code='hong_kong_market'),(select id from bios_core.geographies where code='hong_kong_geo'),'primary','reference-test')$$,'P0001','primary geography requires active included coverage','primary requires included coverage');
select lives_ok($$select bios_internal.add_market_geography((select id from bios_core.markets where code='regional_market'),(select id from bios_core.geographies where code='mainland_china_geo'),'primary','reference-test')$$,'primary link succeeds after included coverage');
select throws_ok($$select bios_internal.add_market_geography((select id from bios_core.markets where code='regional_market'),(select id from bios_core.geographies where code='hong_kong_geo'),'primary','reference-test')$$,'23505',null,'Market cannot have two active primary geographies');
select throws_ok($$select bios_internal.end_reference_relationship('market_geography',(select id from bios_core.market_geographies where market_id=(select id from bios_core.markets where code='regional_market') and geography_id=(select id from bios_core.geographies where code='mainland_china_geo') and relationship_role='included' and valid_to is null),'invalid end','reference-test')$$,'P0001','cannot end included coverage while its primary relationship is active','included coverage cannot end beneath active primary');

select lives_ok($$select bios_internal.add_market_group_member((select id from bios_core.market_groups where code='greater_china_group'),(select id from bios_core.markets where code='mainland_china_market'),'reference-test')$$,'Greater China adds Mainland China ordinarily');
select lives_ok($$select bios_internal.add_market_group_member((select id from bios_core.market_groups where code='greater_china_group'),(select id from bios_core.markets where code='hong_kong_market'),'reference-test')$$,'Greater China adds Hong Kong ordinarily');
select lives_ok($$select bios_internal.add_market_group_member((select id from bios_core.market_groups where code='greater_china_group'),(select id from bios_core.markets where code='taiwan_market'),'reference-test')$$,'Greater China adds Taiwan ordinarily');
select results_eq($$select count(*)::bigint from bios_core.market_group_members where market_group_id=(select id from bios_core.market_groups where code='greater_china_group') and valid_to is null$$,array[3::bigint],'Greater China is represented by three generic memberships');
select throws_ok($$select bios_internal.add_market_group_member((select id from bios_core.market_groups where code='greater_china_group'),(select id from bios_core.markets where code='taiwan_market'),'reference-test')$$,'23505',null,'duplicate active Market-group member is rejected');
select lives_ok($$select bios_internal.end_reference_relationship('market_group_member',(select id from bios_core.market_group_members where market_group_id=(select id from bios_core.market_groups where code='greater_china_group') and market_id=(select id from bios_core.markets where code='taiwan_market') and valid_to is null),'episode test','reference-test')$$,'Market-group membership episode ends');
select lives_ok($$select bios_internal.add_market_group_member((select id from bios_core.market_groups where code='greater_china_group'),(select id from bios_core.markets where code='taiwan_market'),'reference-test')$$,'ended Market-group membership permits a new episode');

select lives_ok($$select bios_internal.add_market_language((select id from bios_core.markets where code='mainland_china_market'),(select id from bios_core.languages where tag='zh-Hans'),'reference-test')$$,'Market relates to Simplified Chinese');
select lives_ok($$select bios_internal.add_market_language((select id from bios_core.markets where code='mainland_china_market'),(select id from bios_core.languages where tag='en'),'reference-test')$$,'one Market relates to multiple Languages');
select lives_ok($$select bios_internal.add_market_language((select id from bios_core.markets where code='hong_kong_market'),(select id from bios_core.languages where tag='zh-Hans'),'reference-test')$$,'one Language relates to multiple Markets');
select throws_ok($$select bios_internal.add_market_language((select id from bios_core.markets where code='mainland_china_market'),(select id from bios_core.languages where tag='zh-Hans'),'reference-test')$$,'23505',null,'duplicate active Market-Language episode is rejected');
select lives_ok($$select bios_internal.end_reference_relationship('market_language',(select id from bios_core.market_languages where market_id=(select id from bios_core.markets where code='mainland_china_market') and language_id=(select id from bios_core.languages where tag='zh-Hans') and valid_to is null),'episode test','reference-test')$$,'Market-Language episode ends');
select lives_ok($$select bios_internal.add_market_language((select id from bios_core.markets where code='mainland_china_market'),(select id from bios_core.languages where tag='zh-Hans'),'reference-test')$$,'ended Market-Language episode permits re-add');

select throws_ok($$update bios_core.market_languages set market_id=(select id from bios_core.markets where code='hong_kong_market') where id=(select id from bios_core.market_languages limit 1)$$,'P0001','relationship episode identity is immutable','relationship endpoint is immutable');
select throws_ok($$update bios_core.geographies set code='changed_code' where code='asia_geo'$$,'P0001','reference code is immutable','base stable identity is immutable');
select throws_ok($$update bios_core.languages set tag='fr',base_language_subtag='fr' where tag='en'$$,'P0001','language identity is immutable','Language tag and components are immutable');
select lives_ok($$select bios_internal.update_geography_metadata((select id from bios_core.geographies where code='hong_kong_geo'),'Hong Kong SAR','territory','Governed description correction','classification correction','reference-test')$$,'approved Geography metadata correction succeeds');
select lives_ok($$select bios_internal.update_market_metadata((select id from bios_core.markets where code='regional_market'),'Regional Analysis Market','Governed description','name correction','reference-test')$$,'approved Market metadata correction succeeds');
select results_eq($$select metadata->'changed_fields' from bios_governance.audit_events where action='reference.metadata_updated' and resource_type='market' order by occurred_at desc limit 1$$,array['["name", "description"]'::jsonb],'metadata audit lists only approved changed fields');
select is_empty($$select 1 from information_schema.parameters where specific_schema='bios_internal' and specific_name like 'update_%_metadata_%' and parameter_name in ('p_code','p_tag','p_base_language_subtag','p_script_subtag','p_region_subtag')$$,'metadata APIs expose no identity parameters');
reset role;

select set_config('request.jwt.claims','{"sub":"81000000-0000-0000-0000-000000000001","role":"authenticated"}',true);
set local role authenticated;
select results_eq($$select count(*)::bigint from bios_core.geographies$$,array[5::bigint],'authenticated user reads active Geographies but not draft rows');
select results_eq($$select count(*)::bigint from bios_core.markets$$,array[4::bigint],'authenticated user reads active Markets');
select results_eq($$select count(*)::bigint from bios_core.languages$$,array[4::bigint],'authenticated user reads active Languages');
select throws_ok($$insert into bios_core.markets(code,name) values('ordinary_write','Ordinary write')$$,'42501',null,'ordinary authenticated user cannot mutate shared references');
select throws_ok($$delete from bios_core.markets$$,'42501',null,'ordinary authenticated user cannot physically delete references');
select throws_ok($$select bios_internal.create_market('forged_market','Forged Market',null,'forged')$$,'42501',null,'ordinary user cannot execute trusted reference mutation');
reset role;

select set_config('request.jwt.claims','{"role":"anon"}',true);
set local role anon;
select throws_ok($$select * from bios_core.markets$$,'42501',null,'anonymous users cannot read shared references');
reset role;

select set_config('request.jwt.claims','{"sub":"81000000-0000-0000-0000-000000000002","role":"authenticated"}',true);
set local role authenticated;
select lives_ok($$select bios_internal.transition_membership(bios_internal.invite_member((select id from bios_core.tenants where code='reference_admin_tenant'),'82000000-0000-0000-0000-000000000001',null),'active')$$,'Migration 001 tenant-admin governed membership path remains usable');
select throws_ok($$select bios_internal.create_market('admin_forged','Admin forged',null,'forged')$$,'42501',null,'tenant administrator has no global reference mutation authority');
reset role;

select set_config('request.jwt.claims','{"role":"service_role"}',true);
set local role service_role;
select throws_ok($$delete from bios_core.markets$$,'42501',null,'trusted service has no physical-delete table grant');
reset role;
select throws_ok($$delete from bios_core.markets where code='regional_market'$$,'P0001','historical BIOS rows cannot be deleted','reference deletion is trigger-protected even for owner recovery context');

select results_eq(
  $$select count(*)::bigint from bios_governance.audit_events where action='reference.relationship_added'$$,
  array[16::bigint], 'successful relationship additions are audited atomically');
select results_eq(
  $$select count(*)::bigint from bios_governance.audit_events where action='reference.relationship_ended'$$,
  array[4::bigint], 'successful relationship endings are audited atomically');
select results_eq(
  $$select count(*)::bigint from bios_governance.audit_events where action='reference.metadata_updated'$$,
  array[2::bigint], 'successful metadata corrections are audited atomically');
select results_eq(
  $$select count(*)::bigint from pg_catalog.pg_tables where schemaname in ('bios_core','bios_governance') and tablename in
    ('tenants','profiles','tenant_memberships','roles','membership_roles','audit_events',
     'geographies','geography_relationships','markets','market_geographies','market_groups','market_group_members','languages','market_languages')$$,
  array[14::bigint], 'all Migration 001 and Migration 002 foundation tables remain present');

select * from finish();
rollback;
