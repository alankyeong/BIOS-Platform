begin;
select plan(32);

-- Preserve database errors as comparable TAP output so one broken RLS policy does
-- not prevent the rest of this supplementary authorization matrix from running.
create function pg_temp.safe_text_rows(p_sql text) returns setof text
language plpgsql as $function$
begin
  return query execute p_sql;
exception when others then
  return next '__ERROR__ '||sqlstate||': '||sqlerrm;
end
$function$;

-- HA-03C-SV03: supplementary authorization regression coverage across M001--M007.
-- Fixtures are synthetic and transaction-scoped. They are inserted by the test
-- owner before switching to authenticated for the actual RLS assertions.
insert into auth.users(id,email,encrypted_password,aud,role) values
 ('d8000000-0000-0000-0000-000000000001','ha03-active-a@example.test','x','authenticated','authenticated'),
 ('d8000000-0000-0000-0000-000000000002','ha03-active-b@example.test','x','authenticated','authenticated'),
 ('d8000000-0000-0000-0000-000000000003','ha03-revoked@example.test','x','authenticated','authenticated'),
 ('d8000000-0000-0000-0000-000000000004','ha03-suspended@example.test','x','authenticated','authenticated'),
 ('d8000000-0000-0000-0000-000000000005','ha03-inactive-profile@example.test','x','authenticated','authenticated');

insert into bios_core.profiles(id,auth_user_id,display_name,status) values
 ('d8010000-0000-0000-0000-000000000001','d8000000-0000-0000-0000-000000000001','HA03 Active A','active'),
 ('d8010000-0000-0000-0000-000000000002','d8000000-0000-0000-0000-000000000002','HA03 Active B','active'),
 ('d8010000-0000-0000-0000-000000000003','d8000000-0000-0000-0000-000000000003','HA03 Revoked','active'),
 ('d8010000-0000-0000-0000-000000000004','d8000000-0000-0000-0000-000000000004','HA03 Suspended','active'),
 ('d8010000-0000-0000-0000-000000000005','d8000000-0000-0000-0000-000000000005','HA03 Inactive Profile','suspended');

insert into bios_core.tenants(id,code,name,status,activated_at) values
 ('d8100000-0000-0000-0000-000000000001','ha03_tenant_a','HA03 Tenant A','active',statement_timestamp()),
 ('d8100000-0000-0000-0000-000000000002','ha03_tenant_b','HA03 Tenant B','active',statement_timestamp());

insert into bios_core.tenant_memberships(id,tenant_id,profile_id,status,activated_at,suspended_at,revoked_at,valid_from) values
 ('d8110000-0000-0000-0000-000000000001','d8100000-0000-0000-0000-000000000001','d8010000-0000-0000-0000-000000000001','active',statement_timestamp(),null,null,statement_timestamp()),
 ('d8110000-0000-0000-0000-000000000002','d8100000-0000-0000-0000-000000000002','d8010000-0000-0000-0000-000000000002','active',statement_timestamp(),null,null,statement_timestamp()),
 ('d8110000-0000-0000-0000-000000000003','d8100000-0000-0000-0000-000000000001','d8010000-0000-0000-0000-000000000003','revoked',statement_timestamp(),null,statement_timestamp(),statement_timestamp()),
 ('d8110000-0000-0000-0000-000000000004','d8100000-0000-0000-0000-000000000001','d8010000-0000-0000-0000-000000000004','suspended',statement_timestamp(),statement_timestamp(),null,statement_timestamp()),
 ('d8110000-0000-0000-0000-000000000005','d8100000-0000-0000-0000-000000000001','d8010000-0000-0000-0000-000000000005','active',statement_timestamp(),null,null,statement_timestamp());

insert into bios_core.membership_roles(tenant_id,tenant_membership_id,role_id) values
 ('d8100000-0000-0000-0000-000000000001','d8110000-0000-0000-0000-000000000001',(select id from bios_core.roles where code='tenant_admin')),
 ('d8100000-0000-0000-0000-000000000002','d8110000-0000-0000-0000-000000000002',(select id from bios_core.roles where code='viewer'));

insert into bios_core.languages(id,tag,base_language_subtag,display_name,status,activated_at) values
 ('d8200000-0000-0000-0000-000000000001','hz','hz','HA03 Language','active',statement_timestamp());

insert into bios_knowledge.sources(id,code,canonical_name,knowledge_scope,tenant_id,status,activated_at) values
 ('d8300000-0000-0000-0000-000000000001','ha03_shared','HA03 Shared','shared',null,'active',statement_timestamp()),
 ('d8300000-0000-0000-0000-000000000002','ha03_tenant_a','HA03 Tenant A Source','tenant','d8100000-0000-0000-0000-000000000001','active',statement_timestamp()),
 ('d8300000-0000-0000-0000-000000000003','ha03_tenant_b','HA03 Tenant B Source','tenant','d8100000-0000-0000-0000-000000000002','active',statement_timestamp()),
 ('d8300000-0000-0000-0000-000000000004','ha03_candidate_a','HA03 Candidate A','tenant','d8100000-0000-0000-0000-000000000001','candidate',null);

insert into bios_knowledge.source_documents(id,source_id,knowledge_scope,tenant_id,canonical_title,language_mode,language_id,access_classification) values
 ('d8400000-0000-0000-0000-000000000001','d8300000-0000-0000-0000-000000000001','shared',null,'HA03 Shared Public','single','d8200000-0000-0000-0000-000000000001','public'),
 ('d8400000-0000-0000-0000-000000000002','d8300000-0000-0000-0000-000000000001','shared',null,'HA03 Shared Licensed','single','d8200000-0000-0000-0000-000000000001','licensed'),
 ('d8400000-0000-0000-0000-000000000003','d8300000-0000-0000-0000-000000000001','shared',null,'HA03 Shared Restricted','single','d8200000-0000-0000-0000-000000000001','restricted'),
 ('d8400000-0000-0000-0000-000000000004','d8300000-0000-0000-0000-000000000002','tenant','d8100000-0000-0000-0000-000000000001','HA03 A Public','single','d8200000-0000-0000-0000-000000000001','public'),
 ('d8400000-0000-0000-0000-000000000005','d8300000-0000-0000-0000-000000000002','tenant','d8100000-0000-0000-0000-000000000001','HA03 A Confidential','single','d8200000-0000-0000-0000-000000000001','tenant_confidential'),
 ('d8400000-0000-0000-0000-000000000006','d8300000-0000-0000-0000-000000000002','tenant','d8100000-0000-0000-0000-000000000001','HA03 A Candidate','single','d8200000-0000-0000-0000-000000000001','tenant_confidential'),
 ('d8400000-0000-0000-0000-000000000007','d8300000-0000-0000-0000-000000000003','tenant','d8100000-0000-0000-0000-000000000002','HA03 B Confidential','single','d8200000-0000-0000-0000-000000000001','tenant_confidential');
update bios_knowledge.source_documents
set status='active',activated_at=statement_timestamp()
where id in (
 'd8400000-0000-0000-0000-000000000001','d8400000-0000-0000-0000-000000000002',
 'd8400000-0000-0000-0000-000000000003','d8400000-0000-0000-0000-000000000004',
 'd8400000-0000-0000-0000-000000000005','d8400000-0000-0000-0000-000000000007');

insert into bios_knowledge.evidence(id,knowledge_scope,tenant_id,evidence_text,text_kind,language_id,access_classification,status,activated_at) values
 ('d8500000-0000-0000-0000-000000000001','shared',null,'HA03 shared public evidence','normalized_statement','d8200000-0000-0000-0000-000000000001','public','active',statement_timestamp()),
 ('d8500000-0000-0000-0000-000000000002','shared',null,'HA03 shared restricted evidence','normalized_statement','d8200000-0000-0000-0000-000000000001','restricted','active',statement_timestamp()),
 ('d8500000-0000-0000-0000-000000000003','tenant','d8100000-0000-0000-0000-000000000001','HA03 A active evidence','verbatim_excerpt','d8200000-0000-0000-0000-000000000001','tenant_confidential','active',statement_timestamp()),
 ('d8500000-0000-0000-0000-000000000004','tenant','d8100000-0000-0000-0000-000000000001','HA03 A candidate evidence','normalized_statement','d8200000-0000-0000-0000-000000000001','tenant_confidential','candidate',null),
 ('d8500000-0000-0000-0000-000000000005','tenant','d8100000-0000-0000-0000-000000000002','HA03 B active evidence','verbatim_excerpt','d8200000-0000-0000-0000-000000000001','tenant_confidential','active',statement_timestamp());

insert into bios_knowledge.evidence_provenance(id,evidence_id,source_document_id,anchor_kind) values
 ('d8510000-0000-0000-0000-000000000001','d8500000-0000-0000-0000-000000000001','d8400000-0000-0000-0000-000000000001','document'),
 ('d8510000-0000-0000-0000-000000000002','d8500000-0000-0000-0000-000000000002','d8400000-0000-0000-0000-000000000001','document'),
 ('d8510000-0000-0000-0000-000000000003','d8500000-0000-0000-0000-000000000003','d8400000-0000-0000-0000-000000000005','document'),
 ('d8510000-0000-0000-0000-000000000004','d8500000-0000-0000-0000-000000000004','d8400000-0000-0000-0000-000000000005','document'),
 ('d8510000-0000-0000-0000-000000000005','d8500000-0000-0000-0000-000000000005','d8400000-0000-0000-0000-000000000007','document');

insert into bios_knowledge.processing_runs(id,input_source_document_id,knowledge_scope,tenant_id,operation_kind,processor_identifier,processor_version,actor_identifier,correlation_id,purpose,outcome,completed_at) values
 ('d8600000-0000-0000-0000-000000000001','d8400000-0000-0000-0000-000000000001','shared',null,'extract_text','ha03','1','fixture','ha03-shared','authorization regression','succeeded',statement_timestamp()),
 ('d8600000-0000-0000-0000-000000000002','d8400000-0000-0000-0000-000000000005','tenant','d8100000-0000-0000-0000-000000000001','extract_text','ha03','1','fixture','ha03-a','authorization regression','succeeded',statement_timestamp()),
 ('d8600000-0000-0000-0000-000000000003','d8400000-0000-0000-0000-000000000007','tenant','d8100000-0000-0000-0000-000000000002','extract_text','ha03','1','fixture','ha03-b','authorization regression','succeeded',statement_timestamp()),
 ('d8600000-0000-0000-0000-000000000004','d8400000-0000-0000-0000-000000000001','shared',null,'extract_text','ha03','1','fixture','ha03-candidate','authorization regression','succeeded',statement_timestamp());

insert into bios_knowledge.document_representations(id,source_document_id,producing_run_id,knowledge_scope,tenant_id,representation_kind,language_id,media_type,content_text,content_sha256,access_classification,status,activated_at) values
 ('d8700000-0000-0000-0000-000000000001','d8400000-0000-0000-0000-000000000001','d8600000-0000-0000-0000-000000000001','shared',null,'extracted_text','d8200000-0000-0000-0000-000000000001','text/plain','HA03 shared representation',encode(digest(convert_to('HA03 shared representation','UTF8'),'sha256'),'hex'),'public','active',statement_timestamp()),
 ('d8700000-0000-0000-0000-000000000002','d8400000-0000-0000-0000-000000000005','d8600000-0000-0000-0000-000000000002','tenant','d8100000-0000-0000-0000-000000000001','extracted_text','d8200000-0000-0000-0000-000000000001','text/plain','HA03 A representation',encode(digest(convert_to('HA03 A representation','UTF8'),'sha256'),'hex'),'tenant_confidential','active',statement_timestamp()),
 ('d8700000-0000-0000-0000-000000000003','d8400000-0000-0000-0000-000000000007','d8600000-0000-0000-0000-000000000003','tenant','d8100000-0000-0000-0000-000000000002','extracted_text','d8200000-0000-0000-0000-000000000001','text/plain','HA03 B representation',encode(digest(convert_to('HA03 B representation','UTF8'),'sha256'),'hex'),'tenant_confidential','active',statement_timestamp()),
 ('d8700000-0000-0000-0000-000000000004','d8400000-0000-0000-0000-000000000001','d8600000-0000-0000-0000-000000000004','shared',null,'extracted_text','d8200000-0000-0000-0000-000000000001','text/plain','HA03 candidate representation',encode(digest(convert_to('HA03 candidate representation','UTF8'),'sha256'),'hex'),'public','candidate',null);

-- Active Tenant A administrator: shared/public plus own-Tenant rows, including governed candidates.
select set_config('request.jwt.claims','{"sub":"d8000000-0000-0000-0000-000000000001","role":"authenticated"}',true);
set local role authenticated;
select results_eq($$select code from bios_knowledge.sources where code like 'ha03_%' order by code$$,array['ha03_candidate_a','ha03_shared','ha03_tenant_a'],'active A source RLS excludes Tenant B and permits own candidate to administrator');
select results_eq($$select canonical_title from bios_knowledge.source_documents where canonical_title like 'HA03 %' order by canonical_title$$,array['HA03 A Candidate','HA03 A Confidential','HA03 A Public','HA03 Shared Public'],'active A document RLS enforces Tenant and shared classification');
select results_eq($$select * from pg_temp.safe_text_rows($q$select evidence_text from bios_knowledge.evidence where evidence_text like 'HA03 %' order by evidence_text$q$)$$,array['HA03 A active evidence','HA03 A candidate evidence','HA03 shared public evidence'],'active A evidence RLS includes own governed candidate only');
select results_eq($$select * from pg_temp.safe_text_rows($q$select count(*)::text from bios_knowledge.evidence_provenance where id::text like 'd851%'$q$)$$,array['3'],'provenance visibility follows authorized Evidence exactly');
select results_eq($$select content_text from bios_knowledge.document_representations where content_text like 'HA03 %' order by content_text$$,array['HA03 A representation','HA03 shared representation'],'active A representation RLS enforces Tenant, status, classification, and parent Document');
select throws_ok($$select 1 from bios_knowledge.processing_runs where id::text like 'd860%'$$,'42501',null,'authenticated role cannot read privileged Processing Runs');

-- Active Tenant B viewer: no Tenant A leakage and no candidate override.
select set_config('request.jwt.claims','{"sub":"d8000000-0000-0000-0000-000000000002","role":"authenticated"}',true);
set local role authenticated;
select results_eq($$select code from bios_knowledge.sources where code like 'ha03_%' order by code$$,array['ha03_shared','ha03_tenant_b'],'active B source RLS excludes Tenant A');
select results_eq($$select canonical_title from bios_knowledge.source_documents where canonical_title like 'HA03 %' order by canonical_title$$,array['HA03 B Confidential','HA03 Shared Public'],'active B document RLS excludes Tenant A and non-public shared Documents');
select results_eq($$select * from pg_temp.safe_text_rows($q$select evidence_text from bios_knowledge.evidence where evidence_text like 'HA03 %' order by evidence_text$q$)$$,array['HA03 B active evidence','HA03 shared public evidence'],'active B evidence RLS excludes Tenant A and restricted shared Evidence');
select results_eq($$select * from pg_temp.safe_text_rows($q$select count(*)::text from bios_knowledge.evidence_provenance where id::text like 'd851%'$q$)$$,array['2'],'active B provenance follows its Evidence visibility');
select results_eq($$select content_text from bios_knowledge.document_representations where content_text like 'HA03 %' order by content_text$$,array['HA03 B representation','HA03 shared representation'],'active B representation RLS excludes Tenant A');

-- Revoked, suspended, and inactive-profile principals lose all Tenant authorization.
select set_config('request.jwt.claims','{"sub":"d8000000-0000-0000-0000-000000000003","role":"authenticated"}',true);
set local role authenticated;
select is_empty($$select 1 from bios_knowledge.sources where tenant_id='d8100000-0000-0000-0000-000000000001'$$,'revoked membership cannot read Tenant sources');
select is_empty($$select 1 from bios_knowledge.source_documents where tenant_id='d8100000-0000-0000-0000-000000000001'$$,'revoked membership cannot read Tenant Documents');
select results_eq($$select * from pg_temp.safe_text_rows($q$select count(*)::text from bios_knowledge.evidence where tenant_id='d8100000-0000-0000-0000-000000000001'$q$)$$,array['0'],'revoked membership cannot read Tenant Evidence');
select results_eq($$select * from pg_temp.safe_text_rows($q$select count(*)::text from bios_knowledge.evidence_provenance ep join bios_knowledge.evidence e on e.id=ep.evidence_id where e.tenant_id='d8100000-0000-0000-0000-000000000001'$q$)$$,array['0'],'revoked membership cannot read Tenant provenance');
select is_empty($$select 1 from bios_knowledge.document_representations where tenant_id='d8100000-0000-0000-0000-000000000001'$$,'revoked membership cannot read Tenant representations');

select set_config('request.jwt.claims','{"sub":"d8000000-0000-0000-0000-000000000004","role":"authenticated"}',true);
set local role authenticated;
select is_empty($$select 1 from bios_knowledge.sources where tenant_id='d8100000-0000-0000-0000-000000000001'$$,'suspended membership cannot read Tenant sources');
select is_empty($$select 1 from bios_knowledge.source_documents where tenant_id='d8100000-0000-0000-0000-000000000001'$$,'suspended membership cannot read Tenant Documents');
select results_eq($$select * from pg_temp.safe_text_rows($q$select count(*)::text from bios_knowledge.evidence where tenant_id='d8100000-0000-0000-0000-000000000001'$q$)$$,array['0'],'suspended membership cannot read Tenant Evidence');
select is_empty($$select 1 from bios_knowledge.document_representations where tenant_id='d8100000-0000-0000-0000-000000000001'$$,'suspended membership cannot read Tenant representations');

select set_config('request.jwt.claims','{"sub":"d8000000-0000-0000-0000-000000000005","role":"authenticated"}',true);
set local role authenticated;
select is(bios_internal.current_profile_id(),null::uuid,'inactive profile is not an authorization principal');
select is_empty($$select 1 from bios_core.tenants where id='d8100000-0000-0000-0000-000000000001'$$,'inactive profile cannot read its nominal Tenant');
select results_eq($$select * from pg_temp.safe_text_rows($q$select count(*)::text from bios_knowledge.evidence where tenant_id='d8100000-0000-0000-0000-000000000001'$q$)$$,array['0'],'inactive profile cannot read Tenant Evidence');
select is_empty($$select 1 from bios_knowledge.document_representations where id::text like 'd870%'$$,'inactive profile cannot read any Representation, including shared');

-- Privileged function and direct-mutation boundaries under a real authenticated principal.
select set_config('request.jwt.claims','{"sub":"d8000000-0000-0000-0000-000000000002","role":"authenticated"}',true);
set local role authenticated;
select ok(not has_function_privilege('authenticated','bios_internal.create_evidence(text,uuid,text,text,uuid,text,timestamptz,timestamptz,uuid,uuid,text,integer,integer,text,integer,integer,bigint,bigint,text,text,text,text)','execute'),'Evidence creation remains service-role only');
select ok(not has_function_privilege('authenticated','bios_internal.start_processing_run(uuid,uuid,text,uuid,text,text,text,text,text,jsonb,text,text,text)','execute'),'processing start remains service-role only');
select throws_ok($$select bios_internal.start_processing_run('d8400000-0000-0000-0000-000000000001',null,'shared',null,'extract_text','unauthorized','1',null,null,'{}','actor','corr','purpose')$$,'42501',null,'authenticated execution of processing function is denied');
select throws_ok($$insert into bios_knowledge.evidence(knowledge_scope,evidence_text,text_kind,language_id,access_classification) values('shared','unauthorized','normalized_statement','d8200000-0000-0000-0000-000000000001','public')$$,'42501',null,'authenticated direct Evidence insertion is denied');
select throws_ok($$insert into bios_knowledge.document_representations(source_document_id,producing_run_id,knowledge_scope,representation_kind,language_id,media_type,content_text,content_sha256,access_classification) values('d8400000-0000-0000-0000-000000000001','d8600000-0000-0000-0000-000000000001','shared','extracted_text','d8200000-0000-0000-0000-000000000001','text/plain','unauthorized',encode(digest(convert_to('unauthorized','UTF8'),'sha256'),'hex'),'public')$$,'42501',null,'authenticated direct Representation insertion is denied');
select throws_ok($$select bios_internal.create_source('ha03_cross_tenant','Cross Tenant',null,null,'tenant','d8100000-0000-0000-0000-000000000001',null)$$,'P0001','same-Tenant administrator required','authenticated source function cannot cross Tenant boundary');

-- Tenant A administrator retains the intentionally delegated, same-Tenant source boundary.
select set_config('request.jwt.claims','{"sub":"d8000000-0000-0000-0000-000000000001","role":"authenticated"}',true);
set local role authenticated;
select lives_ok($$select bios_internal.create_source('ha03_admin_created','Administrator Created',null,null,'tenant','d8100000-0000-0000-0000-000000000001',null)$$,'same-Tenant administrator may use delegated source function');
select results_eq($$select actor_type||':'||actor_profile_id::text from bios_governance.audit_events where resource_type='source' and resource_id=(select id from bios_knowledge.sources where code='ha03_admin_created')$$,array['user:d8010000-0000-0000-0000-000000000001'],'delegated source mutation records the authenticated profile');

select * from finish();
rollback;
