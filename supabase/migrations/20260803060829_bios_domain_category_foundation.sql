-- DB-004 v1.0: BIOS Migration 003 -- Domain & Category Foundation

alter table bios_governance.audit_events
  drop constraint audit_resource_check,
  add constraint audit_resource_check check (
    resource_type ~ '^[a-z][a-z0-9_]*$' and resource_type in (
      'tenant','profile','tenant_membership','role','membership_role','platform',
      'geography','geography_relationship','market','market_geography',
      'market_group','market_group_member','language','market_language',
      'domain','domain_node','domain_node_relationship'
    )
  );

create table bios_core.domains (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  name text not null,
  description text,
  status text not null default 'draft',
  created_at timestamptz not null default transaction_timestamp(),
  updated_at timestamptz not null default transaction_timestamp(),
  activated_at timestamptz,
  deprecated_at timestamptz,
  constraint domains_code_check check (code ~ '^[a-z][a-z0-9_]{1,62}[a-z0-9]$'),
  constraint domains_name_check check (name=btrim(name) and char_length(name) between 1 and 200),
  constraint domains_description_check check (description is null or (description=btrim(description) and char_length(description) between 1 and 1000)),
  constraint domains_status_check check (status in ('draft','active','deprecated')),
  constraint domains_lifecycle_check check (
    (status='draft' and activated_at is null and deprecated_at is null) or
    (status='active' and activated_at is not null and deprecated_at is null) or
    (status='deprecated' and activated_at is not null and deprecated_at is not null)
  )
);
create index domains_status_idx on bios_core.domains(status);
create index domains_name_lower_idx on bios_core.domains(lower(name));

create table bios_core.domain_nodes (
  id uuid primary key default gen_random_uuid(),
  domain_id uuid not null references bios_core.domains(id) on delete restrict,
  code text not null,
  name text not null,
  description text,
  status text not null default 'draft',
  created_at timestamptz not null default transaction_timestamp(),
  updated_at timestamptz not null default transaction_timestamp(),
  activated_at timestamptz,
  deprecated_at timestamptz,
  constraint domain_nodes_domain_code_key unique(domain_id,code),
  constraint domain_nodes_id_domain_key unique(id,domain_id),
  constraint domain_nodes_code_check check (code ~ '^[a-z][a-z0-9_]{1,62}[a-z0-9]$'),
  constraint domain_nodes_name_check check (name=btrim(name) and char_length(name) between 1 and 200),
  constraint domain_nodes_description_check check (description is null or (description=btrim(description) and char_length(description) between 1 and 1000)),
  constraint domain_nodes_status_check check (status in ('draft','active','deprecated')),
  constraint domain_nodes_lifecycle_check check (
    (status='draft' and activated_at is null and deprecated_at is null) or
    (status='active' and activated_at is not null and deprecated_at is null) or
    (status='deprecated' and activated_at is not null and deprecated_at is not null)
  )
);
create index domain_nodes_domain_status_idx on bios_core.domain_nodes(domain_id,status);
create index domain_nodes_domain_name_lower_idx on bios_core.domain_nodes(domain_id,lower(name));

create table bios_core.domain_node_relationships (
  id uuid primary key default gen_random_uuid(),
  domain_id uuid not null references bios_core.domains(id) on delete restrict,
  subject_node_id uuid not null,
  object_node_id uuid not null,
  relationship_type text not null default 'contains',
  valid_from timestamptz not null default transaction_timestamp(),
  valid_to timestamptz,
  created_at timestamptz not null default transaction_timestamp(),
  updated_at timestamptz not null default transaction_timestamp(),
  constraint domain_node_relationships_subject_fk foreign key(subject_node_id,domain_id) references bios_core.domain_nodes(id,domain_id) on delete restrict,
  constraint domain_node_relationships_object_fk foreign key(object_node_id,domain_id) references bios_core.domain_nodes(id,domain_id) on delete restrict,
  constraint domain_node_relationships_distinct_check check(subject_node_id<>object_node_id),
  constraint domain_node_relationships_type_check check(relationship_type='contains'),
  constraint domain_node_relationships_validity_check check(valid_to is null or valid_to>valid_from)
);
create unique index domain_node_relationships_active_uidx on bios_core.domain_node_relationships(domain_id,subject_node_id,object_node_id,relationship_type) where valid_to is null;
create index domain_node_relationships_active_subject_idx on bios_core.domain_node_relationships(domain_id,subject_node_id,object_node_id) where valid_to is null;
create index domain_node_relationships_active_object_idx on bios_core.domain_node_relationships(domain_id,object_node_id,subject_node_id) where valid_to is null;

create function bios_internal.govern_domain_reference_row() returns trigger
language plpgsql set search_path='' as $$
begin
  if tg_op='INSERT' then
    if new.status<>'draft' or new.activated_at is not null or new.deprecated_at is not null then
      raise exception 'domain references must be created in draft status';
    end if;
    if tg_table_name='domain_nodes' then
      if not exists(
        select 1 from bios_core.domains where id=new.domain_id and status in ('draft','active')
      ) then raise exception 'node requires a non-deprecated domain'; end if;
    end if;
    return new;
  end if;
  if new.id<>old.id or new.created_at<>old.created_at or new.code<>old.code then
    raise exception 'domain reference identity is immutable';
  end if;
  if tg_table_name='domain_nodes' then
    if new.domain_id<>old.domain_id then raise exception 'node domain is immutable'; end if;
  end if;
  if old.status='deprecated' and new.status<>old.status then raise exception 'deprecated status is terminal'; end if;
  if new.status<>old.status then
    if not ((old.status='draft' and new.status='active') or (old.status='active' and new.status='deprecated')) then
      raise exception 'invalid domain reference lifecycle transition';
    end if;
    if tg_table_name='domain_nodes' then
      if new.status='active' and not exists(
        select 1 from bios_core.domains where id=new.domain_id and status='active'
      ) then raise exception 'node activation requires an active domain'; end if;
      if new.status='deprecated' and exists(
        select 1 from bios_core.domain_node_relationships
        where domain_id=new.domain_id and valid_to is null and (subject_node_id=new.id or object_node_id=new.id)
      ) then raise exception 'node deprecation requires no active incident relationships'; end if;
    elsif tg_table_name='domains' then
      if new.status='deprecated' and exists(
        select 1 from bios_core.domain_nodes where domain_id=new.id and status='active'
      ) then raise exception 'domain deprecation requires no active nodes'; end if;
    else
      raise exception 'unsupported domain reference trigger relation';
    end if;
  elsif new.activated_at is distinct from old.activated_at or new.deprecated_at is distinct from old.deprecated_at then
    raise exception 'lifecycle timestamps change only with status';
  end if;
  return new;
end $$;

create function bios_internal.govern_domain_relationship_row() returns trigger
language plpgsql set search_path='' as $$
begin
  if tg_op='UPDATE' then
    if new.id<>old.id or new.domain_id<>old.domain_id or new.subject_node_id<>old.subject_node_id or
       new.object_node_id<>old.object_node_id or new.relationship_type<>old.relationship_type or
       new.valid_from<>old.valid_from or new.created_at<>old.created_at then
      raise exception 'domain relationship episode identity is immutable';
    end if;
    if old.valid_to is not null or new.valid_to is null then raise exception 'only active relationship closure is permitted'; end if;
  end if;
  return new;
end $$;

create function bios_internal.touch_domain_updated_at() returns trigger
language plpgsql set search_path='' as $$
begin new.updated_at=statement_timestamp(); return new; end $$;

create trigger domains_govern before insert or update on bios_core.domains for each row execute function bios_internal.govern_domain_reference_row();
create trigger domains_touch before update on bios_core.domains for each row execute function bios_internal.touch_domain_updated_at();
create trigger domains_no_delete before delete on bios_core.domains for each row execute function bios_internal.reject_delete();
create trigger domain_nodes_govern before insert or update on bios_core.domain_nodes for each row execute function bios_internal.govern_domain_reference_row();
create trigger domain_nodes_touch before update on bios_core.domain_nodes for each row execute function bios_internal.touch_domain_updated_at();
create trigger domain_nodes_no_delete before delete on bios_core.domain_nodes for each row execute function bios_internal.reject_delete();
create trigger domain_node_relationships_govern before update on bios_core.domain_node_relationships for each row execute function bios_internal.govern_domain_relationship_row();
create trigger domain_node_relationships_touch before update on bios_core.domain_node_relationships for each row execute function bios_internal.touch_domain_updated_at();
create trigger domain_node_relationships_no_delete before delete on bios_core.domain_node_relationships for each row execute function bios_internal.reject_delete();

create function bios_internal.create_domain(p_code text,p_name text,p_description text,p_actor_identifier text,p_correlation_id uuid default gen_random_uuid()) returns uuid
language plpgsql security definer set search_path='' as $$
declare v_id uuid;
begin
  perform bios_internal.assert_reference_actor(p_actor_identifier);
  insert into bios_core.domains(code,name,description) values(p_code,p_name,p_description) returning id into v_id;
  perform bios_internal.write_reference_audit(p_actor_identifier,'reference.created','domain',v_id,p_correlation_id,'{}');
  return v_id;
end $$;

create function bios_internal.create_domain_node(p_domain_id uuid,p_code text,p_name text,p_description text,p_actor_identifier text,p_correlation_id uuid default gen_random_uuid()) returns uuid
language plpgsql security definer set search_path='' as $$
declare v_id uuid;
begin
  perform bios_internal.assert_reference_actor(p_actor_identifier);
  insert into bios_core.domain_nodes(domain_id,code,name,description) values(p_domain_id,p_code,p_name,p_description) returning id into v_id;
  perform bios_internal.write_reference_audit(p_actor_identifier,'reference.created','domain_node',v_id,p_correlation_id,jsonb_build_object('domain_id',p_domain_id));
  return v_id;
end $$;

create function bios_internal.transition_domain_reference_status(p_resource_type text,p_resource_id uuid,p_new_status text,p_reason text,p_actor_identifier text,p_correlation_id uuid default gen_random_uuid()) returns void
language plpgsql security definer set search_path='' as $$
declare v_old text;
begin
  perform bios_internal.assert_reference_actor(p_actor_identifier);
  case p_resource_type
    when 'domain' then select status into strict v_old from bios_core.domains where id=p_resource_id for update;
    when 'domain_node' then select status into strict v_old from bios_core.domain_nodes where id=p_resource_id for update;
    else raise exception 'unsupported domain reference type';
  end case;
  if not ((v_old='draft' and p_new_status='active') or (v_old='active' and p_new_status='deprecated')) then
    raise exception 'invalid domain reference lifecycle transition';
  end if;
  case p_resource_type
    when 'domain' then update bios_core.domains set status=p_new_status,activated_at=coalesce(activated_at,transaction_timestamp()),deprecated_at=case when p_new_status='deprecated' then transaction_timestamp() end where id=p_resource_id;
    when 'domain_node' then update bios_core.domain_nodes set status=p_new_status,activated_at=coalesce(activated_at,transaction_timestamp()),deprecated_at=case when p_new_status='deprecated' then transaction_timestamp() end where id=p_resource_id;
  end case;
  perform bios_internal.write_reference_audit(p_actor_identifier,'reference.status_changed',p_resource_type,p_resource_id,p_correlation_id,jsonb_build_object('from_status',v_old,'to_status',p_new_status,'reason',p_reason));
end $$;

create function bios_internal.update_domain_metadata(p_id uuid,p_name text,p_description text,p_reason text,p_actor_identifier text,p_correlation_id uuid default gen_random_uuid()) returns void
language plpgsql security definer set search_path='' as $$
declare v_old bios_core.domains%rowtype; v_changed text[];
begin
  perform bios_internal.assert_reference_actor(p_actor_identifier);
  select * into strict v_old from bios_core.domains where id=p_id for update;
  v_changed=array_remove(array[case when v_old.name is distinct from p_name then 'name' end,case when v_old.description is distinct from p_description then 'description' end],null);
  if cardinality(v_changed)=0 then raise exception 'no approved metadata change supplied'; end if;
  update bios_core.domains set name=p_name,description=p_description where id=p_id;
  perform bios_internal.write_reference_audit(p_actor_identifier,'reference.metadata_updated','domain',p_id,p_correlation_id,jsonb_build_object('changed_fields',v_changed,'reason',p_reason));
end $$;

create function bios_internal.update_domain_node_metadata(p_id uuid,p_name text,p_description text,p_reason text,p_actor_identifier text,p_correlation_id uuid default gen_random_uuid()) returns void
language plpgsql security definer set search_path='' as $$
declare v_old bios_core.domain_nodes%rowtype; v_changed text[];
begin
  perform bios_internal.assert_reference_actor(p_actor_identifier);
  select * into strict v_old from bios_core.domain_nodes where id=p_id for update;
  v_changed=array_remove(array[case when v_old.name is distinct from p_name then 'name' end,case when v_old.description is distinct from p_description then 'description' end],null);
  if cardinality(v_changed)=0 then raise exception 'no approved metadata change supplied'; end if;
  update bios_core.domain_nodes set name=p_name,description=p_description where id=p_id;
  perform bios_internal.write_reference_audit(p_actor_identifier,'reference.metadata_updated','domain_node',p_id,p_correlation_id,jsonb_build_object('changed_fields',v_changed,'reason',p_reason));
end $$;

create function bios_internal.add_domain_node_relationship(p_domain_id uuid,p_subject_node_id uuid,p_object_node_id uuid,p_actor_identifier text,p_correlation_id uuid default gen_random_uuid()) returns uuid
language plpgsql security definer set search_path='' as $$
declare v_id uuid;
begin
  perform bios_internal.assert_reference_actor(p_actor_identifier);
  perform pg_advisory_xact_lock(hashtextextended('bios_domain_graph:'||p_domain_id::text,0));
  if not exists(select 1 from bios_core.domains where id=p_domain_id and status='active') then raise exception 'relationship requires an active domain'; end if;
  if not exists(select 1 from bios_core.domain_nodes where id=p_subject_node_id and domain_id=p_domain_id and status='active') or
     not exists(select 1 from bios_core.domain_nodes where id=p_object_node_id and domain_id=p_domain_id and status='active') then
    raise exception 'relationship requires active same-domain nodes';
  end if;
  if p_subject_node_id=p_object_node_id then raise exception 'domain node cannot contain itself'; end if;
  if exists(with recursive reachable(id) as (
    select r.object_node_id from bios_core.domain_node_relationships r where r.domain_id=p_domain_id and r.subject_node_id=p_object_node_id and r.valid_to is null
    union
    select r.object_node_id from bios_core.domain_node_relationships r join reachable q on r.subject_node_id=q.id where r.domain_id=p_domain_id and r.valid_to is null
  ) select 1 from reachable where id=p_subject_node_id) then raise exception 'domain relationship would create a cycle'; end if;
  if exists(select 1 from bios_core.domain_node_relationships where domain_id=p_domain_id and subject_node_id=p_subject_node_id and object_node_id=p_object_node_id and relationship_type='contains' and valid_to is null) then
    raise exception 'duplicate active domain relationship';
  end if;
  insert into bios_core.domain_node_relationships(domain_id,subject_node_id,object_node_id) values(p_domain_id,p_subject_node_id,p_object_node_id) returning id into v_id;
  perform bios_internal.write_reference_audit(p_actor_identifier,'reference.relationship_added','domain_node_relationship',v_id,p_correlation_id,jsonb_build_object('domain_id',p_domain_id,'subject_node_id',p_subject_node_id,'object_node_id',p_object_node_id,'relationship_type','contains'));
  return v_id;
end $$;

create function bios_internal.end_domain_node_relationship(p_relationship_id uuid,p_reason text,p_actor_identifier text,p_correlation_id uuid default gen_random_uuid()) returns void
language plpgsql security definer set search_path='' as $$
declare v_domain_id uuid; v_metadata jsonb;
begin
  perform bios_internal.assert_reference_actor(p_actor_identifier);
  select domain_id into strict v_domain_id from bios_core.domain_node_relationships where id=p_relationship_id;
  perform pg_advisory_xact_lock(hashtextextended('bios_domain_graph:'||v_domain_id::text,0));
  update bios_core.domain_node_relationships set valid_to=statement_timestamp() where id=p_relationship_id and valid_to is null;
  if not found then raise exception 'active domain relationship not found'; end if;
  select jsonb_build_object('domain_id',domain_id,'subject_node_id',subject_node_id,'object_node_id',object_node_id,'relationship_type',relationship_type,'valid_to',valid_to,'reason',p_reason) into v_metadata from bios_core.domain_node_relationships where id=p_relationship_id;
  perform bios_internal.write_reference_audit(p_actor_identifier,'reference.relationship_ended','domain_node_relationship',p_relationship_id,p_correlation_id,v_metadata);
end $$;

alter table bios_core.domains enable row level security;
alter table bios_core.domain_nodes enable row level security;
alter table bios_core.domain_node_relationships enable row level security;
create policy domains_active_read on bios_core.domains for select to authenticated using(status='active');
create policy domain_nodes_active_read on bios_core.domain_nodes for select to authenticated using(status='active' and exists(select 1 from bios_core.domains d where d.id=domain_id and d.status='active'));
create policy domain_node_relationships_active_read on bios_core.domain_node_relationships for select to authenticated using(valid_to is null and exists(select 1 from bios_core.domains d where d.id=domain_id and d.status='active') and exists(select 1 from bios_core.domain_nodes s where s.id=subject_node_id and s.status='active') and exists(select 1 from bios_core.domain_nodes o where o.id=object_node_id and o.status='active'));

grant select on bios_core.domains,bios_core.domain_nodes,bios_core.domain_node_relationships to authenticated;
revoke all on all functions in schema bios_internal from public;
grant execute on function bios_internal.create_domain(text,text,text,text,uuid),bios_internal.create_domain_node(uuid,text,text,text,text,uuid),bios_internal.transition_domain_reference_status(text,uuid,text,text,text,uuid),bios_internal.update_domain_metadata(uuid,text,text,text,text,uuid),bios_internal.update_domain_node_metadata(uuid,text,text,text,text,uuid),bios_internal.add_domain_node_relationship(uuid,uuid,uuid,text,uuid),bios_internal.end_domain_node_relationship(uuid,text,text,uuid) to service_role;

comment on table bios_core.domains is 'Shared platform-governed subject and ontology boundary registry.';
comment on table bios_core.domain_nodes is 'Shared governed taxonomy nodes belonging to exactly one Domain.';
comment on table bios_core.domain_node_relationships is 'Historical same-Domain polyhierarchical contains episodes forming a DAG.';
