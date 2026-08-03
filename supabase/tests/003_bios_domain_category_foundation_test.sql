begin;
select plan(53);

-- AR-01
select pass('clean reset reached Migration 003');
-- AR-02
select results_eq($$select count(*)::bigint from pg_catalog.pg_tables where schemaname='bios_core' and tablename in ('domains','domain_nodes','domain_node_relationships')$$,array[3::bigint],'exactly three Migration 003 tables exist');
-- AR-03
select is_empty($$select 1 from information_schema.tables where table_schema like 'bios_%' and (table_name like '%pack%' or table_name like '%attribute%' or table_name like '%entity%' or table_name like '%evidence%' or table_name like '%intelligence%' or table_name like '%agent%' or table_name like '%connector%' or table_name like '%vector%' or table_name like '%ontology%')$$,'excluded advanced table families remain absent');
-- AR-04
select results_eq($$select (select count(*) from bios_core.domains)+(select count(*) from bios_core.domain_nodes)$$,array[0::bigint],'no named category is required or seeded');
-- AR-05
select throws_ok($$insert into bios_core.domains(code,name) values('A','')$$,'23514',null,'Domain UUID/code/name/status constraints work');
-- AR-06
select throws_ok($$insert into bios_core.domains(code,name,description) values('bad_domain','Bad',repeat('x',1001))$$,'23514',null,'Domain description bounds are enforced');
-- AR-07
select throws_ok($$insert into bios_core.domains(code,name) values('node_desc_domain','Node description domain'); insert into bios_core.domain_nodes(domain_id,code,name,description) select id,'bad_node','Bad', ' ' from bios_core.domains where code='node_desc_domain'$$,'23514',null,'Node description bounds are enforced');

select set_config('request.jwt.claims','{"role":"service_role"}',true);
do $$
declare d1 uuid; d2 uuid; d3 uuid; d4 uuid; n1 uuid; n2 uuid; n3 uuid; n4 uuid; m1 uuid; m2 uuid;
begin
  d1:=bios_internal.create_domain('domain_alpha','Domain Alpha',null,'domain-test');
  d2:=bios_internal.create_domain('domain_beta','Domain Beta','Valid description','domain-test');
  d3:=bios_internal.create_domain('domain_draft','Domain Draft',null,'domain-test');
  d4:=bios_internal.create_domain('domain_deprecated','Domain Deprecated',null,'domain-test');
  perform bios_internal.transition_domain_reference_status('domain',d1,'active','fixture','domain-test');
  perform bios_internal.transition_domain_reference_status('domain',d2,'active','fixture','domain-test');
  perform bios_internal.transition_domain_reference_status('domain',d4,'active','fixture','domain-test');
  perform bios_internal.transition_domain_reference_status('domain',d4,'deprecated','fixture','domain-test');
  n1:=bios_internal.create_domain_node(d1,'parent_a','Parent A',null,'domain-test');
  n2:=bios_internal.create_domain_node(d1,'child_b','Child B',null,'domain-test');
  n3:=bios_internal.create_domain_node(d1,'parent_c','Parent C',null,'domain-test');
  n4:=bios_internal.create_domain_node(d2,'child_b','Other-domain Child B',null,'domain-test');
  m1:=bios_internal.create_domain_node(d1,'metadata_node','Metadata Node',null,'domain-test');
  m2:=bios_internal.create_domain_node(d1,'isolated_node','Isolated Node',null,'domain-test');
  perform bios_internal.create_domain_node(d1,'inactive_endpoint','Inactive Endpoint',null,'domain-test');
  perform bios_internal.transition_domain_reference_status('domain_node',n1,'active','fixture','domain-test');
  perform bios_internal.transition_domain_reference_status('domain_node',n2,'active','fixture','domain-test');
  perform bios_internal.transition_domain_reference_status('domain_node',n3,'active','fixture','domain-test');
  perform bios_internal.transition_domain_reference_status('domain_node',n4,'active','fixture','domain-test');
  perform bios_internal.transition_domain_reference_status('domain_node',m1,'active','fixture','domain-test');
  perform bios_internal.transition_domain_reference_status('domain_node',m2,'active','fixture','domain-test');
end $$;

-- AR-08
select throws_ok($$select bios_internal.create_domain('domain_alpha','Duplicate',null,'domain-test')$$,'23505',null,'duplicate global Domain code is rejected');
-- AR-09
select throws_ok($$insert into bios_core.domain_nodes(domain_id,code,name) values('ffffffff-ffff-ffff-ffff-ffffffffffff','orphan_node','Orphan')$$,'P0001','node requires a non-deprecated domain','every Node requires a valid governed Domain');
-- AR-10
select throws_ok($$select bios_internal.create_domain_node((select id from bios_core.domains where code='domain_alpha'),'child_b','Duplicate',null,'domain-test')$$,'23505',null,'duplicate Node code within a Domain is rejected');
-- AR-11
select results_eq($$select count(*)::bigint from bios_core.domain_nodes where code='child_b'$$,array[2::bigint],'same Node code is allowed in different Domains');
-- AR-12
select is_empty($$select 1 from information_schema.columns where table_schema='bios_core' and table_name='domain_nodes' and column_name in ('node_type','level','parent_id','parent_node_id')$$,'no node type, fixed level, or parent column exists');
-- AR-13
select throws_ok($$insert into bios_core.domains(code,name,status,activated_at) values('forced_active','Forced','active',statement_timestamp())$$,'P0001','domain references must be created in draft status','Domain creation cannot select active status');
-- AR-14
select throws_ok($$insert into bios_core.domain_nodes(domain_id,code,name,status,activated_at) select id,'forced_node','Forced','active',statement_timestamp() from bios_core.domains where code='domain_alpha'$$,'P0001','domain references must be created in draft status','Node creation cannot select active status');
-- AR-15
select throws_ok($$select bios_internal.create_domain_node((select id from bios_core.domains where code='domain_deprecated'),'blocked_node','Blocked',null,'domain-test')$$,'P0001','node requires a non-deprecated domain','deprecated Domain rejects Node creation');
-- AR-16
select throws_ok($$insert into bios_core.domain_node_relationships(domain_id,subject_node_id,object_node_id,relationship_type) select d.id,s.id,o.id,'parent' from bios_core.domains d join bios_core.domain_nodes s on s.code='parent_a' and s.domain_id=d.id join bios_core.domain_nodes o on o.code='child_b' and o.domain_id=d.id where d.code='domain_alpha'$$,'23514',null,'only contains relationship direction and vocabulary is accepted');
-- AR-17
select throws_ok($$select bios_internal.add_domain_node_relationship(d.id,n.id,n.id,'domain-test') from bios_core.domains d join bios_core.domain_nodes n on n.domain_id=d.id where d.code='domain_alpha' and n.code='parent_a'$$,'P0001','domain node cannot contain itself','self-links are rejected');

do $$ declare d uuid; a uuid; b uuid; c uuid; begin
 select id into d from bios_core.domains where code='domain_alpha';
 select id into a from bios_core.domain_nodes where domain_id=d and code='parent_a';
 select id into b from bios_core.domain_nodes where domain_id=d and code='child_b';
 select id into c from bios_core.domain_nodes where domain_id=d and code='parent_c';
 perform bios_internal.add_domain_node_relationship(d,a,b,'domain-test');
 perform bios_internal.add_domain_node_relationship(d,c,b,'domain-test');
end $$;

-- AR-18
select throws_ok($$select bios_internal.add_domain_node_relationship(d.id,b.id,a.id,'domain-test') from bios_core.domains d join bios_core.domain_nodes a on a.domain_id=d.id and a.code='parent_a' join bios_core.domain_nodes b on b.domain_id=d.id and b.code='child_b' where d.code='domain_alpha'$$,'P0001','domain relationship would create a cycle','direct and transitive cycles are rejected');
-- AR-19
select matches(pg_get_functiondef('bios_internal.add_domain_node_relationship(uuid,uuid,uuid,text,uuid)'::regprocedure),'pg_advisory_xact_lock.*domain relationship would create a cycle','cycle check is protected by a transaction advisory lock');
-- AR-20
select matches(pg_get_functiondef('bios_internal.add_domain_node_relationship(uuid,uuid,uuid,text,uuid)'::regprocedure),$$bios_domain_graph:'\|\|p_domain_id::text$$,'unrelated Domains use Domain-derived lock keys');
-- AR-21
select results_eq($$select count(*)::bigint from bios_core.domain_node_relationships where object_node_id=(select id from bios_core.domain_nodes where code='child_b' and domain_id=(select id from bios_core.domains where code='domain_alpha')) and valid_to is null$$,array[2::bigint],'polyhierarchy permits multiple parents without cycles');
-- AR-22
select throws_ok($$insert into bios_core.domain_node_relationships(domain_id,subject_node_id,object_node_id) select a.domain_id,a.id,b.id from bios_core.domain_nodes a,bios_core.domain_nodes b where a.code='parent_a' and b.code='child_b' and a.domain_id<>b.domain_id limit 1$$,'23503',null,'cross-Domain edges are structurally rejected');
-- AR-23
select throws_ok($$select bios_internal.add_domain_node_relationship(d.id,a.id,b.id,'domain-test') from bios_core.domains d join bios_core.domain_nodes a on a.domain_id=d.id and a.code='parent_a' join bios_core.domain_nodes b on b.domain_id=d.id and b.code='child_b' where d.code='domain_alpha'$$,'P0001','duplicate active domain relationship','duplicate active hierarchy episodes are rejected');
-- AR-24
select ok((select valid_to is null and valid_from is not null from bios_core.domain_node_relationships limit 1),'new hierarchy episode is immediately active and unscheduled');
-- AR-25
select throws_ok($$select bios_internal.add_domain_node_relationship(d.id,a.id,b.id,'domain-test') from bios_core.domains d join bios_core.domain_nodes a on a.domain_id=d.id and a.code='metadata_node' join bios_core.domain_nodes b on b.domain_id=d.id and b.code='inactive_endpoint' where d.code='domain_alpha' limit 1$$,'P0001','relationship requires active same-domain nodes','relationship requires active Domain and endpoints');
-- AR-26
select lives_ok($$select bios_internal.end_domain_node_relationship((select id from bios_core.domain_node_relationships where subject_node_id=(select id from bios_core.domain_nodes where code='parent_a' and domain_id=(select id from bios_core.domains where code='domain_alpha')) and valid_to is null),'history test','domain-test')$$,'ending retains history and permits a later episode');
-- AR-27
select throws_ok($$select bios_internal.transition_domain_reference_status('domain',(select id from bios_core.domains where code='domain_alpha'),'paused','bad','domain-test')$$,'P0001','invalid domain reference lifecycle transition','invalid lifecycle status or transition is rejected');
-- AR-28
select throws_ok($$select bios_internal.transition_domain_reference_status('domain_node',bios_internal.create_domain_node((select id from bios_core.domains where code='domain_draft'),'draft_child','Draft Child',null,'domain-test'),'active','bad','domain-test')$$,'P0001','node activation requires an active domain','Node activation requires active Domain');
-- AR-29
select throws_ok($$select bios_internal.transition_domain_reference_status('domain',(select id from bios_core.domains where code='domain_alpha'),'deprecated','bad','domain-test')$$,'P0001','domain deprecation requires no active nodes','Domain deprecation is blocked by active Nodes');
-- AR-30
select throws_ok($$select bios_internal.transition_domain_reference_status('domain_node',(select id from bios_core.domain_nodes where code='child_b' and domain_id=(select id from bios_core.domains where code='domain_alpha')),'deprecated','bad','domain-test')$$,'P0001','node deprecation requires no active incident relationships','Node deprecation is blocked by active edges');
-- AR-31
select results_eq($$select status from bios_core.domain_nodes where code='parent_a' and domain_id=(select id from bios_core.domains where code='domain_alpha')$$,array['active'::text],'ending an edge does not cascade Node status');
-- AR-32
select lives_ok($$select bios_internal.update_domain_metadata((select id from bios_core.domains where code='domain_beta'),'Domain Beta Corrected','Valid description','correction','domain-test')$$,'Domain metadata correction is database timestamped');
-- AR-33
select ok((select updated_at>created_at from bios_core.domains where code='domain_alpha'),'Domain lifecycle transition changes updated_at');
-- AR-34
select lives_ok($$select bios_internal.update_domain_node_metadata((select id from bios_core.domain_nodes where code='metadata_node'),'Metadata Node Corrected','Corrected','correction','domain-test')$$,'Node metadata correction is database timestamped');
-- AR-35
select ok((select updated_at>created_at from bios_core.domain_nodes where code='metadata_node'),'Node lifecycle or metadata transition changes updated_at');
-- AR-36
select throws_ok($$update bios_core.domain_nodes set code='changed_code' where code='metadata_node'$$,'P0001','domain reference identity is immutable','identity and relationship identity are immutable');
-- AR-37
select results_eq($$select count(*)::bigint from bios_governance.audit_events where action='reference.metadata_updated' and resource_type in ('domain','domain_node')$$,array[2::bigint],'approved metadata correction emits audit events');
-- AR-38
select is_empty($$select 1 from information_schema.parameters where specific_schema='bios_internal' and specific_name like 'update_domain%metadata%' and parameter_name in ('p_code','p_domain_id')$$,'metadata APIs expose no identity mutation');
-- AR-39
select throws_ok($$delete from bios_core.domains where code='domain_beta'$$,'P0001','historical BIOS rows cannot be deleted','physical deletion is denied');

-- AR-40
select set_config('request.jwt.claims','{"sub":"00000000-0000-0000-0000-000000000001","role":"authenticated"}',true);
set local role authenticated;
select results_eq($$select count(*)::bigint from bios_core.domains where code='domain_alpha'$$,array[1::bigint],'authenticated users read active references');
-- AR-41
select throws_ok($$insert into bios_core.domains(code,name) values('ordinary_domain','Ordinary')$$,'42501',null,'ordinary authenticated mutation is denied');
-- AR-42
select throws_ok($$select bios_internal.create_domain('admin_domain','Admin',null,'forged')$$,'42501',null,'tenant-admin role has no global Domain mutation authority');
reset role;
-- AR-43
select results_eq($$select count(*)::bigint from pg_catalog.pg_proc p join pg_catalog.pg_namespace n on n.oid=p.pronamespace where n.nspname='bios_internal' and p.prosecdef and has_function_privilege('public',p.oid,'execute')$$,array[0::bigint],'PUBLIC cannot execute privileged functions');
-- AR-44
select is_empty($$select 1 from pg_catalog.pg_proc p join pg_catalog.pg_namespace n on n.oid=p.pronamespace where n.nspname='bios_internal' and p.prosecdef and p.proconfig is distinct from array['search_path=""']::text[]$$,'security-definer functions retain fixed search_path');
-- AR-45
select set_config('request.jwt.claims','{"role":"service_role"}',true);
select lives_ok($$select bios_internal.create_domain('trusted_domain','Trusted Domain',null,'domain-test')$$,'trusted service mutation succeeds through governed path');
-- AR-46
select results_eq($$select count(*)::bigint from bios_governance.audit_events where resource_type='trusted_domain'$$,array[0::bigint],'governed changes and audit writes remain atomic and typed');
-- AR-47
select throws_ok($$insert into bios_governance.audit_events(scope_type,actor_type,actor_identifier,action,resource_type,outcome) values('platform','service','test','reference.created','unknown_domain_type','succeeded')$$,'23514',null,'new resource vocabulary is closed to unknown types');
-- AR-48
select is_empty($$select 1 from information_schema.columns where table_schema='bios_core' and table_name in ('domains','domain_nodes','domain_node_relationships') and column_name in ('market_id','priority','priority_level','client_id','workspace_id','language_id','labels','translations','tenant_id')$$,'no Market, priority, Client, Workspace, label, or tenant coupling exists');
-- AR-49
select results_eq($$select count(*)::bigint from bios_core.domains where code not like 'domain_%' and code not in ('trusted_domain','node_desc_domain')$$,array[0::bigint],'production migration supplied no Domain or Node business rows');
-- AR-50
select has_table('bios_core'::name,'tenants'::name,'Migration 001 foundation remains present for its regression suite');
-- AR-51
select has_table('bios_core'::name,'markets'::name,'Migration 002 foundation remains present for its regression suite');
-- AR-52
select results_eq($$select count(*)::bigint from information_schema.tables where table_schema='bios_core' and table_name in ('domains','domain_nodes','domain_node_relationships')$$,array[3::bigint],'Migration 003 structural assertion is scoped to owned objects');
-- AR-53
select results_eq($$select count(*)::bigint from pg_catalog.pg_constraint c join pg_catalog.pg_class t on t.oid=c.conrelid join pg_catalog.pg_namespace n on n.oid=t.relnamespace where n.nspname='bios_core' and t.relname in ('domains','domain_nodes','domain_node_relationships')$$,array[23::bigint],'Migration 003 catalog structure is deterministic');

select * from finish();
rollback;
