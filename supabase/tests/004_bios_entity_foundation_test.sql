begin;
select no_plan();

select has_table('bios_knowledge'::name,'entity_types'::name);
select has_table('bios_knowledge'::name,'entities'::name);
select has_table('bios_knowledge'::name,'entity_aliases'::name);
select results_eq($$select count(*)::bigint from pg_catalog.pg_tables where (schemaname,tablename) in (('bios_knowledge','entity_types'),('bios_knowledge','entities'),('bios_knowledge','entity_aliases'))$$,array[3::bigint],'exactly three Migration 004 tables exist');
select is_empty($$select 1 from information_schema.tables where table_schema like 'bios_%' and (table_name like 'entity_relationship%' or table_name like 'entity_market%' or table_name like 'entity_domain%' or table_name like '%source%' or table_name like '%evidence%' or table_name like '%vector%' or table_name like '%agent%' or table_name like '%connector%' or table_name like '%workspace%' or table_name like '%client%') and table_name not in ('sources','source_documents')$$,'Migration 004 prohibited/deferred families remain absent except specific later canonical Migration 005 tables');
select results_eq($$select (select count(*) from bios_knowledge.entity_types)+(select count(*) from bios_knowledge.entities)+(select count(*) from bios_knowledge.entity_aliases)$$,array[0::bigint],'Migration 004 seeds no business rows');
select results_eq($$select count(*)::bigint from pg_catalog.pg_class c join pg_catalog.pg_namespace n on n.oid=c.relnamespace where n.nspname='bios_knowledge' and c.relname in ('entity_types','entities','entity_aliases') and c.relrowsecurity$$,array[3::bigint],'RLS is enabled on all Migration 004 tables');
select is_empty($$select 1 from information_schema.columns where table_schema='bios_knowledge' and table_name='entities' and column_name in ('market_id','domain_id','domain_node_id','country_code','priority','category_id')$$,'Entity identity has no Market, Domain, country, priority, or category coupling');
select is_empty($$select 1 from information_schema.columns where table_schema='bios_knowledge' and table_name='entity_aliases' and column_name in ('source_id','evidence_id','normalized_key','domain_id')$$,'aliases contain no provenance placeholder or normalized matching key');
select results_eq($$select count(*)::bigint from pg_catalog.pg_proc p join pg_catalog.pg_namespace n on n.oid=p.pronamespace where n.nspname='bios_internal' and p.prosecdef and has_function_privilege('public',p.oid,'execute')$$,array[0::bigint],'PUBLIC cannot execute security-definer functions');
select results_eq($$select count(*)::bigint from pg_catalog.pg_proc p join pg_catalog.pg_namespace n on n.oid=p.pronamespace where n.nspname='bios_internal' and p.proname in ('resolve_entity','create_entity','merge_entity','unmerge_entity') and p.prosecdef and p.proconfig=array['search_path=""']$$,array[4::bigint],'critical Entity security-definer functions use fixed empty search_path');

select throws_ok($$insert into bios_knowledge.entity_types(code,name) values('A','Bad')$$,'23514',null,'Entity Type stable code regex is enforced');
select throws_ok($$insert into bios_knowledge.entity_types(code,name) values('valid_type',' Bad ')$$,'23514',null,'Entity Type name must be trimmed');
select throws_ok($$insert into bios_knowledge.entity_types(code,name,description) values('empty_description','Bad','')$$,'23514',null,'Entity Type empty description is rejected');
select throws_ok($$insert into bios_knowledge.entity_types(code,name,description) values('long_description','Bad',repeat('x',1001))$$,'23514',null,'Entity Type description maximum is enforced');
insert into bios_knowledge.entity_types(code,name) values('constraint_type','Constraint Type');
select throws_ok($$insert into bios_knowledge.entities(entity_type_id,knowledge_scope,canonical_name) values(gen_random_uuid(),'shared','Missing type')$$,'23503',null,'Entity requires a valid Entity Type');
select throws_ok($$insert into bios_knowledge.entities(entity_type_id,knowledge_scope,tenant_id,canonical_name) values((select id from bios_knowledge.entity_types limit 1),'shared',gen_random_uuid(),'Bad scope')$$,'23514',null,'shared scope requires null Tenant');

insert into auth.users(id,email,encrypted_password,aud,role) values
 ('91000000-0000-0000-0000-000000000001','entity-admin-a@example.test','','authenticated','authenticated'),
 ('91000000-0000-0000-0000-000000000002','entity-member-a@example.test','','authenticated','authenticated'),
 ('91000000-0000-0000-0000-000000000003','entity-admin-b@example.test','','authenticated','authenticated'),
 ('91000000-0000-0000-0000-000000000004','entity-outsider@example.test','','authenticated','authenticated'),
 ('91000000-0000-0000-0000-000000000005','entity-inactive@example.test','','authenticated','authenticated');
insert into bios_core.profiles(id,auth_user_id,display_name,status) values
 ('92000000-0000-0000-0000-000000000001','91000000-0000-0000-0000-000000000001','Entity Admin A','active'),
 ('92000000-0000-0000-0000-000000000002','91000000-0000-0000-0000-000000000002','Entity Member A','active'),
 ('92000000-0000-0000-0000-000000000003','91000000-0000-0000-0000-000000000003','Entity Admin B','active'),
 ('92000000-0000-0000-0000-000000000004','91000000-0000-0000-0000-000000000004','Entity Outsider','active'),
 ('92000000-0000-0000-0000-000000000005','91000000-0000-0000-0000-000000000005','Inactive Profile','suspended');

select set_config('request.jwt.claims','{"role":"service_role"}',true);
set local role service_role;
select lives_ok($$select bios_internal.bootstrap_tenant('entity_tenant_a','Entity Tenant A','92000000-0000-0000-0000-000000000001','entity-test')$$,'Tenant A bootstrap succeeds');
select lives_ok($$select bios_internal.bootstrap_tenant('entity_tenant_b','Entity Tenant B','92000000-0000-0000-0000-000000000003','entity-test')$$,'Tenant B bootstrap succeeds');
select lives_ok($$select bios_internal.create_entity_type('organization_type','Organization','Synthetic test type','entity-test')$$,'platform creates draft Entity Type');
select lives_ok($$select bios_internal.create_entity_type('person_type','Person',null,'entity-test')$$,'platform creates second draft Entity Type');
reset role;
select results_eq($$select status from bios_knowledge.entity_types where code='organization_type'$$,array['draft'],'Entity Type creation always starts draft');
select is_empty($$select 1 from information_schema.parameters where specific_schema='bios_internal' and specific_name like 'create_entity_type_%' and parameter_name='p_status'$$,'governed Entity Type creation accepts no caller-selected status');
select set_config('request.jwt.claims','{"role":"service_role"}',true);
select lives_ok($$select bios_internal.transition_entity_type((select id from bios_knowledge.entity_types where code='organization_type'),'active','activate','entity-test')$$,'Entity Type draft-to-active succeeds');
select lives_ok($$select bios_internal.transition_entity_type((select id from bios_knowledge.entity_types where code='person_type'),'active','activate','entity-test')$$,'second Entity Type activates');
select throws_ok($$select bios_internal.transition_entity_type((select id from bios_knowledge.entity_types where code='organization_type'),'draft','reverse','entity-test')$$,'P0001','invalid Entity Type transition','invalid Entity Type transition is rejected');
select throws_ok($$select bios_internal.create_entity_type('organization_type','Duplicate',null,'entity-test')$$,'23505',null,'Entity Type code is globally unique');
select throws_ok($$update bios_knowledge.entity_types set code='changed_type' where code='organization_type'$$,'P0001','Entity Type code is immutable','Entity Type code is immutable');

select lives_ok($$select bios_internal.create_entity((select id from bios_knowledge.entity_types where code='organization_type'),'shared',null,'Shared Candidate',null,'entity-test')$$,'platform creates shared candidate Entity');
select lives_ok($$select bios_internal.create_entity((select id from bios_knowledge.entity_types where code='organization_type'),'shared',null,'Shared Candidate',null,'entity-test')$$,'canonical Entity names are not unique');
select results_eq($$select count(*)::bigint from bios_knowledge.entities where canonical_name='Shared Candidate'$$,array[2::bigint],'duplicate canonical names coexist');
select results_eq($$select count(*)::bigint from bios_knowledge.entities where status='candidate'$$,array[2::bigint],'Entity creation always starts candidate');
select set_config('request.jwt.claims','{"sub":"91000000-0000-0000-0000-000000000004","role":"authenticated"}',true);
select throws_ok($$select bios_internal.create_entity((select id from bios_knowledge.entity_types where code='organization_type'),'tenant',(select id from bios_core.tenants where code='entity_tenant_a'),'Unauthorized private',null,null)$$,'P0001','same-tenant administrator required','non-admin cannot create tenant Entity');

select set_config('request.jwt.claims','{"sub":"91000000-0000-0000-0000-000000000001","role":"authenticated"}',true);
set local role authenticated;
select lives_ok($$select bios_internal.transition_membership(bios_internal.invite_member((select id from bios_core.tenants where code='entity_tenant_a'),'92000000-0000-0000-0000-000000000002',null),'active')$$,'Tenant A ordinary member fixture activates');
select lives_ok($$select bios_internal.create_entity((select id from bios_knowledge.entity_types where code='organization_type'),'tenant',(select id from bios_core.tenants where code='entity_tenant_a'),'Tenant A Candidate',null,null)$$,'same-tenant admin creates private candidate');
select throws_ok($$select bios_internal.create_entity((select id from bios_knowledge.entity_types where code='organization_type'),'shared',null,'Admin shared attempt',null,null)$$,'P0001','platform authority required','tenant admin cannot create shared Entity');
select throws_ok($$select bios_internal.create_entity((select id from bios_knowledge.entity_types where code='organization_type'),'tenant',(select id from bios_core.tenants where code='entity_tenant_b'),'Cross tenant',null,null)$$,'P0001','platform authority required','tenant admin cannot select or act through another Tenant hidden by RLS');
reset role;

select set_config('request.jwt.claims','{"sub":"91000000-0000-0000-0000-000000000002","role":"authenticated"}',true);
set local role authenticated;
select throws_ok($$select bios_internal.create_entity((select id from bios_knowledge.entity_types where code='organization_type'),'tenant',(select id from bios_core.tenants where code='entity_tenant_a'),'Member attempt',null,null)$$,'P0001','same-tenant administrator required','ordinary active member cannot create Entity');
reset role;

select set_config('request.jwt.claims','{"role":"service_role"}',true);
select lives_ok($$select bios_internal.transition_entity((select id from bios_knowledge.entities where knowledge_scope='shared' order by created_at,id limit 1),'active','approve','entity-test')$$,'shared candidate activates');
select lives_ok($$select bios_internal.transition_entity((select id from bios_knowledge.entities where knowledge_scope='shared' order by created_at,id offset 1 limit 1),'active','approve','entity-test')$$,'second shared candidate activates');
select lives_ok($$select bios_internal.create_entity((select id from bios_knowledge.entity_types where code='person_type'),'shared',null,'Different Type Target',null,'entity-test')$$,'different-type candidate created');
select lives_ok($$select bios_internal.transition_entity((select id from bios_knowledge.entities where canonical_name='Different Type Target'),'active','approve','entity-test')$$,'different-type target activates');

select set_config('request.jwt.claims','{"sub":"91000000-0000-0000-0000-000000000001","role":"authenticated"}',true);
set local role authenticated;
select lives_ok($$select bios_internal.transition_entity((select id from bios_knowledge.entities where canonical_name='Tenant A Candidate'),'active','approve',null)$$,'tenant admin activates own candidate');
select lives_ok($$select bios_internal.update_entity_metadata((select id from bios_knowledge.entities where canonical_name='Tenant A Candidate'),'Tenant A Entity','Corrected description','correction',null)$$,'Entity metadata correction succeeds');
select results_eq($$select metadata->'changed_fields' from bios_governance.audit_events where resource_type='entity' and action='reference.metadata_updated' order by occurred_at desc limit 1$$,array['["canonical_name", "description"]'::jsonb],'Entity metadata audit lists approved fields');
select throws_ok($$update bios_knowledge.entities set tenant_id=(select id from bios_core.tenants where code='entity_tenant_b') where canonical_name='Tenant A Entity'$$,'42501',null,'direct ownership mutation is denied');
reset role;

select set_config('request.jwt.claims','{"role":"service_role"}',true);
select throws_ok($$select bios_internal.merge_entity((select id from bios_knowledge.entities where canonical_name='Shared Candidate' order by id limit 1),(select id from bios_knowledge.entities where canonical_name='Shared Candidate' order by id limit 1),'self','entity-test')$$,'P0001','Entity cannot merge into itself','self merge is rejected');
select throws_ok($$select bios_internal.merge_entity((select id from bios_knowledge.entities where canonical_name='Shared Candidate' order by id limit 1),(select id from bios_knowledge.entities where canonical_name='Different Type Target'),'wrong type','entity-test')$$,'P0001','incompatible Entity merge','cross-type merge is rejected');
select lives_ok($$select bios_internal.merge_entity((select id from bios_knowledge.entities where canonical_name='Shared Candidate' order by id limit 1),(select id from bios_knowledge.entities where canonical_name='Shared Candidate' order by id offset 1 limit 1),'duplicate resolution','entity-test')$$,'compatible shared merge succeeds');
select results_eq($$select status||':'||(merge_target_entity_id is not null)::text from bios_knowledge.entities where canonical_name='Shared Candidate' order by status desc limit 1$$,array['merged:true'],'merge sets status and direct target');
select throws_ok($$select bios_internal.merge_entity((select id from bios_knowledge.entities where status='active' and knowledge_scope='shared' limit 1),(select id from bios_knowledge.entities where status='merged' limit 1),'chain','entity-test')$$,'P0001','incompatible Entity merge','merged target is rejected');
select lives_ok($$select bios_internal.create_entity((select id from bios_knowledge.entity_types where code='organization_type'),'shared',null,'Resolver Candidate',null,'entity-test')$$,'resolver candidate fixture created');
create temp table entity_resolver_test_ids as select
  (select id from bios_knowledge.entities where status='merged' and knowledge_scope='shared') merged_id,
  (select merge_target_entity_id from bios_knowledge.entities where status='merged' and knowledge_scope='shared') merge_target_id,
  (select id from bios_knowledge.entities where canonical_name='Resolver Candidate') candidate_id,
  (select id from bios_knowledge.entities where canonical_name='Tenant A Entity') tenant_entity_id,
  (select id from bios_knowledge.entities where status='active' and knowledge_scope='shared' limit 1) active_shared_id;
grant select on entity_resolver_test_ids to authenticated;

select set_config('request.jwt.claims','{"sub":"91000000-0000-0000-0000-000000000004","role":"authenticated"}',true);
set local role authenticated;
select results_eq($$select count(*)::bigint from bios_knowledge.entities where knowledge_scope='shared'$$,array[2::bigint],'ordinary authenticated user sees active shared Entities but not merged row');
select lives_ok($$select * from bios_internal.resolve_entity((select merged_id from entity_resolver_test_ids))$$,'active Profile can call shared merged resolver');
select results_eq($$select requested_entity_id=(select merged_id from entity_resolver_test_ids) and resolved_entity_id=(select merge_target_id from entity_resolver_test_ids) from bios_internal.resolve_entity((select merged_id from entity_resolver_test_ids))$$,array[true],'merged shared UUID resolves one hop to active target');
select is_empty($$select * from bios_internal.resolve_entity((select candidate_id from entity_resolver_test_ids))$$,'candidate resolver returns no row');
select is_empty($$select * from bios_internal.resolve_entity('ffffffff-ffff-ffff-ffff-ffffffffffff')$$,'nonexistent resolver returns no row');
reset role;

select set_config('request.jwt.claims','{"sub":"91000000-0000-0000-0000-000000000005","role":"authenticated"}',true);
set local role authenticated;
select is_empty($$select * from bios_internal.resolve_entity((select active_shared_id from entity_resolver_test_ids))$$,'inactive BIOS Profile cannot resolve shared Entity');
reset role;

select set_config('request.jwt.claims','{"sub":"91000000-0000-0000-0000-000000000002","role":"authenticated"}',true);
set local role authenticated;
select results_eq($$select count(*)::bigint from bios_knowledge.entities where knowledge_scope='tenant'$$,array[1::bigint],'same-tenant ordinary member reads active private Entity');
select results_eq($$select count(*)::bigint from bios_internal.resolve_entity((select tenant_entity_id from entity_resolver_test_ids))$$,array[1::bigint],'ordinary active member resolves own-Tenant active Entity without admin role');
reset role;

select set_config('request.jwt.claims','{"sub":"91000000-0000-0000-0000-000000000003","role":"authenticated"}',true);
set local role authenticated;
select is_empty($$select * from bios_internal.resolve_entity((select tenant_entity_id from entity_resolver_test_ids))$$,'other-Tenant caller receives no resolver row for a real private UUID');
select is_empty($$select 1 from bios_knowledge.entities where canonical_name='Tenant A Entity'$$,'cross-tenant Entity read is denied');
reset role;

select set_config('request.jwt.claims','{"role":"anon"}',true);
set local role anon;
select throws_ok($$select * from bios_internal.resolve_entity(gen_random_uuid())$$,'42501',null,'anonymous cannot execute resolver');
select throws_ok($$select * from bios_knowledge.entities$$,'42501',null,'anonymous cannot read Entities');
reset role;

select results_eq($$select count(*)::bigint from information_schema.parameters where specific_schema='bios_internal' and specific_name like 'resolve_entity_%' and parameter_mode='IN'$$,array[1::bigint],'resolver exposes exactly one input');
select is((select parameter_name||':'||data_type from information_schema.parameters where specific_schema='bios_internal' and specific_name like 'resolve_entity_%' and parameter_mode='OUT' order by ordinal_position limit 1),'requested_entity_id:uuid','resolver first output is requested_entity_id UUID');
select is((select parameter_name||':'||data_type from information_schema.parameters where specific_schema='bios_internal' and specific_name like 'resolve_entity_%' and parameter_mode='OUT' order by ordinal_position offset 1 limit 1),'resolved_entity_id:uuid','resolver second output is resolved_entity_id UUID');
select ok(has_function_privilege('authenticated','bios_internal.resolve_entity(uuid)','execute'),'authenticated has explicit resolver execution');
select ok(not has_function_privilege('public','bios_internal.resolve_entity(uuid)','execute'),'PUBLIC lacks resolver execution');
select is_empty($$select 1 from information_schema.parameters where specific_schema='bios_internal' and specific_name like 'resolve_entity_%' and parameter_name in ('tenant_id','profile_id','scope','role','membership_id','authorization')$$,'resolver exposes no caller authorization context');

select set_config('request.jwt.claims','{"role":"service_role"}',true);
select lives_ok($$select bios_internal.create_entity_alias((select id from bios_knowledge.entities where status='active' and knowledge_scope='shared' limit 1),'Example Co','name',null,null,0.8,null,null,'entity-test')$$,'candidate alias creation succeeds');
select results_eq($$select status from bios_knowledge.entity_aliases where alias_text='Example Co'$$,array['candidate'],'Alias creation starts candidate');
select lives_ok($$select bios_internal.transition_entity_alias((select id from bios_knowledge.entity_aliases where alias_text='Example Co'),'active','approve','entity-test')$$,'Alias activates under active Entity');
select throws_ok($$select bios_internal.create_entity_alias((select id from bios_knowledge.entities where status='active' and knowledge_scope='shared' limit 1),'Bad confidence','name',null,null,1.1,null,null,'entity-test')$$,'23514',null,'Alias confidence bound is enforced');
select throws_ok($$insert into bios_knowledge.entity_aliases(entity_id,alias_text,alias_type) values((select id from bios_knowledge.entities where status='active' limit 1),'Bad type','invalid')$$,'23514',null,'Alias type vocabulary is enforced');
select lives_ok($$select bios_internal.create_entity_alias((select id from bios_knowledge.entities where status='active' and knowledge_scope='shared' limit 1),'Example Co','name',null,null,null,null,null,'entity-test')$$,'overlapping duplicate may exist as candidate');
select throws_ok($$select bios_internal.transition_entity_alias((select id from bios_knowledge.entity_aliases where alias_text='Example Co' and status='candidate'),'active','approve duplicate','entity-test')$$,'P0001','overlapping active alias episode exists','overlapping identical active alias is rejected with null contexts/bounds equal');
select lives_ok($$select bios_internal.create_entity_alias((select id from bios_knowledge.entities where status='active' and knowledge_scope='shared' order by id desc limit 1),'Example Co','name',null,null,null,null,null,'entity-test')$$,'same alias text is allowed for a different Entity');
select lives_ok($$select bios_internal.update_entity_alias_confidence((select id from bios_knowledge.entity_aliases where status='active' limit 1),0.9,'review','entity-test')$$,'Alias confidence correction is governed and audited');
select throws_ok($$update bios_knowledge.entity_aliases set alias_text='Rewritten' where status='active'$$,'P0001','Alias identity and context are immutable','Alias text/context cannot be rewritten');

select results_eq($$select count(*)::bigint from bios_governance.audit_events where action='entity.merged'$$,array[1::bigint],'successful merge creates one deterministic audit event');
select results_eq($$select count(*)::bigint from bios_governance.audit_events where action='entity.unmerged'$$,array[0::bigint],'no unmerge audit exists before unmerge');
select lives_ok($$select bios_internal.unmerge_entity((select id from bios_knowledge.entities where status='merged'),'reverse decision','entity-test')$$,'governed shared unmerge succeeds');
select results_eq($$select status||':'||(merge_target_entity_id is null)::text||':'||(merged_at is null)::text from bios_knowledge.entities where canonical_name='Shared Candidate' order by updated_at desc limit 1$$,array['active:true:true'],'unmerge restores active state and clears merge fields');
select results_eq($$select count(*)::bigint from bios_governance.audit_events where action='entity.unmerged'$$,array[1::bigint],'unmerge audit is atomic');
select throws_ok($$delete from bios_knowledge.entities$$,'P0001','Entity foundation rows cannot be deleted','physical Entity deletion is trigger-protected');
select throws_ok($$insert into bios_governance.audit_events(scope_type,actor_type,actor_identifier,action,resource_type,outcome) values('platform','service','test','entity.deleted','entity','succeeded')$$,'23514',null,'unknown Entity audit action is rejected');
select throws_ok($$insert into bios_governance.audit_events(scope_type,actor_type,actor_identifier,action,resource_type,outcome) values('platform','service','test','reference.created','entity_relationship','succeeded')$$,'23514',null,'unknown Entity resource type is rejected');
select results_eq($$select count(*)::bigint from pg_catalog.pg_tables where (schemaname,tablename) in (('bios_core','profiles'),('bios_core','tenants'),('bios_core','tenant_memberships'),('bios_core','roles'),('bios_core','membership_roles'),('bios_governance','audit_events'),('bios_core','geographies'),('bios_core','geography_relationships'),('bios_core','markets'),('bios_core','market_geographies'),('bios_core','market_groups'),('bios_core','market_group_members'),('bios_core','languages'),('bios_core','market_languages'),('bios_core','domains'),('bios_core','domain_nodes'),('bios_core','domain_node_relationships'),('bios_knowledge','entity_types'),('bios_knowledge','entities'),('bios_knowledge','entity_aliases'))$$,array[20::bigint],'all Migration 001–004 foundation tables remain present');

select * from finish();
rollback;
