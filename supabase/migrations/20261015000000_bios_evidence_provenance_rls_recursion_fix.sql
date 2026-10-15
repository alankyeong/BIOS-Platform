-- HA-03C-SV03 corrective migration: break the M006 Evidence/provenance RLS cycle.
-- DB-009 remains on hold. M001--M007 are intentionally unchanged.

create function bios_internal.can_read_evidence(p_evidence_id uuid) returns boolean
language sql stable security definer set search_path='' as $$
  select exists(
    select 1
    from bios_knowledge.evidence e
    where e.id=p_evidence_id
      and (
        (
          e.status='active'
          and (
            (e.knowledge_scope='shared' and e.access_classification='public')
            or (e.knowledge_scope='tenant' and bios_internal.has_active_membership(e.tenant_id))
          )
          and exists(
            select 1
            from bios_knowledge.evidence_provenance ep
            join bios_knowledge.source_documents d on d.id=ep.source_document_id
            where ep.evidence_id=e.id
              and d.status='active'
              and (
                (e.knowledge_scope='shared' and d.knowledge_scope='shared' and d.access_classification='public')
                or (
                  e.knowledge_scope='tenant'
                  and (
                    (d.knowledge_scope='shared' and d.access_classification='public')
                    or (d.knowledge_scope='tenant' and d.tenant_id=e.tenant_id and d.access_classification='tenant_confidential')
                  )
                )
              )
          )
        )
        or (
          e.knowledge_scope='tenant'
          and bios_internal.has_active_membership(e.tenant_id)
          and bios_internal.has_capability(e.tenant_id,'manage_memberships')
          and exists(
            select 1
            from bios_knowledge.evidence_provenance ep
            join bios_knowledge.source_documents d on d.id=ep.source_document_id
            where ep.evidence_id=e.id
              and (
                (d.knowledge_scope='shared' and d.status='active' and d.access_classification='public')
                or (
                  d.knowledge_scope='tenant'
                  and d.tenant_id=e.tenant_id
                  and d.status='active'
                  and d.access_classification='tenant_confidential'
                )
              )
          )
        )
      )
  )
$$;

revoke all on function bios_internal.can_read_evidence(uuid) from public,anon,authenticated;
grant execute on function bios_internal.can_read_evidence(uuid) to authenticated,service_role;

drop policy evidence_provenance_authorized_read on bios_knowledge.evidence_provenance;
create policy evidence_provenance_authorized_read
on bios_knowledge.evidence_provenance
for select to authenticated
using (bios_internal.can_read_evidence(evidence_id));

