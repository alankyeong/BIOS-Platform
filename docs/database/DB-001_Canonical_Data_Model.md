# DB-001 — Canonical Data Model

| Field | Value |
|---|---|
| Document ID | DB-001 |
| Title | BIOS Canonical Data Model |
| Version | 1.0 |
| Status | Canonical |
| Effective date | 2026-08-02 |
| Owner | BIOS Executive Office — Data Architecture and Engineering |
| Dependencies | ADR-001, ARCH-001, ARCH-002, ENG-001, CANON-001 |
| Supersedes | None |
| Review cadence | Before every schema migration and after material Atlas resolution |
| Related documents | [README](../../README.md), [ENG-001](../engineering/ENG-001_BIOS_Engineering_Handbook.md), [CANON-001](../engineering/CANON-001_Repository_and_Engineering_Standards.md), [ADR-001](../decisions/ADR-001_PostgreSQL_and_Supabase.md), [ARCH-001](../architecture/ARCH-001_Canonical_Platform_Architecture.md), [ARCH-002](../architecture/ARCH-002_Architecture_Assumption_Register.md) |

## 1. Purpose

This document defines the canonical Phase 1 PostgreSQL data model at a level sufficient to plan migrations without writing SQL. It translates [ARCH-001](../architecture/ARCH-001_Canonical_Platform_Architecture.md) into permitted structural concepts while keeping unvalidated Atlas assumptions replaceable.

This is a logical model, not a migration. “Phase 1 core” means required during Phase 1, not necessarily Migration 001.

## 2. Modeling principles

1. PostgreSQL is the canonical transactional system of record; Supabase is the initial platform layer.
2. Tenant is the hard ownership and security boundary.
3. Missing tenant context denies access; null tenant ownership never implies sharing.
4. Shared reference records and tenant-private records use explicit scope and distinct policy.
5. Markets, groupings, languages, domains, categories, entity types, and source types are governed records, not fixed enums.
6. Core relationships are normalized; JSONB is restricted to genuinely variable, governed extension values.
7. Evidence originals and transformations are separate and versioned.
8. Provenance and temporal meaning are structural.
9. Derived intelligence retains tenant ownership and upstream links.
10. Deletion defaults to archive, revoke, or supersede when a record has informed intelligence or decisions.

## 3. Schema placement and exposure

| Schema | Owner and purpose | Exposure posture |
|---|---|---|
| `auth` | Supabase-managed authentication, including `auth.users` | Supabase-managed; BIOS migrations must not recreate or directly expose it |
| `bios_core` | Tenancy, profiles, memberships, geography, market, language, domain, pack, and configuration registries | Access through owned API/RPC or explicitly exposed RLS-protected objects |
| `bios_knowledge` | Entities, sources, documents, evidence, representations, and provenance | Private by default; selectively exposed through RLS-protected contracts |
| `bios_intelligence` | Signals, patterns, findings, decision contexts, recommendations, decisions | Tenant-private; server-mediated writes for governed transitions |
| `bios_governance` | Assumptions, reviews, and audit metadata | Restricted writes; controlled tenant and governance reads |
| `bios_internal` | Ingestion operations, agent runs, outbox/jobs, and platform-only state | Never directly exposed to untrusted clients |
| `public` | Deliberately approved compatibility views or RPC entry points only | No canonical base tables by default |
| `storage` and other Supabase schemas | Supabase-managed platform services | Used through documented platform contracts |

Schema placement is a recommendation to be confirmed in Migration 001 design. Vendor-managed schemas remain outside BIOS ownership. Search documents, vectors, and warehouse models are projections, not canonical tables.

## 4. Identity boundary

```text
Supabase Auth                    BIOS application model

auth.users (Supabase-owned) ───→ bios_core.profiles
                                      │
                                      ├→ tenant_memberships → membership_roles
                                      │
                                      └→ workspace_memberships
```

`auth.users` authenticates a person or machine identity. `profiles` stores BIOS-owned display and application metadata. Authorization derives from active tenant/workspace membership and roles. BIOS does not duplicate password, provider, token, or MFA state.

## 5. Scope, identity, time, and deletion conventions

Unless a table-specific rule overrides them:

- Primary identifiers are generated UUIDs with no mutable business meaning.
- Governed registries may also carry unique stable codes.
- Tenant-scoped rows contain a non-null `tenant_id` and use RLS.
- Shared rows carry explicit `knowledge_scope = shared` or live in a table defined as shared; sharing is never inferred from a null tenant on a mixed-scope table.
- Lifecycle values are governed checks or reference records, not application-only strings.
- `created_at` and `updated_at` are system timestamps; `created_by` identifies profile, service, or agent context where applicable.
- Domain time uses explicit fields such as `observed_at`, `published_at`, `valid_from`, `valid_to`, `effective_at`, and `decided_at`.
- Records used in provenance are archived or superseded, not physically deleted through ordinary application operations.
- Hard deletion is restricted to approved retention/privacy workflows that preserve required audit evidence.

## 6. Phase allocation

### 6.1 Phase 1 core schema

- Tenant security boundary, BIOS profiles, memberships, roles, and optional workspaces.
- Geography, market, market grouping, and language registries.
- Domain and domain-node registry.
- Entity registry, aliases, relationships, and market/domain links.
- Sources, source documents, evidence, representations, scope links, and provenance.
- Signals, patterns, findings, decision contexts, recommendations, decisions, and their typed links.
- Minimal human review and audit structures required by implemented workflows.

### 6.2 Phase 1 extension/configuration schema

- Market Packs, Domain Packs, tenant configuration, governed attribute definitions and values.
- Automated source connector definitions when the first connector exists.
- Operational ingestion records when ingestion automation exists.
- Project Atlas assumptions and assumption evidence if Atlas is operated inside BIOS rather than repository documents.

### 6.3 Deferred/future schema

- Agent orchestration and detailed `agent_runs`.
- Advanced ontology axioms and reasoning structures.
- Automated pattern-generation jobs and model-training metadata.
- General recommendation workflow engine.
- Vector embeddings/index management.
- Knowledge-promotion workflow.
- Specialized search, graph, warehouse, queue, and geographic partition structures.

Deferred capabilities may be represented in audit or external tools until their first approved workflow requires canonical persistence.

## 7. Table specification notation

For compactness, each table specification contains all required dimensions:

- **Scope** includes shared or tenant-scoped and RLS expectation.
- **Keys/relationships** includes primary strategy, foreign keys, and cardinality.
- **Fields/lifecycle/time** includes important attributes, status, and temporal semantics.
- **Provenance/deletion** describes lineage and retention.
- **Atlas** lists assumptions that constrain the design.

## 8. Tenancy and authorization

### 8.1 `bios_core.tenants` — Phase 1 core / Migration 001

- **Purpose:** primary security and data-ownership boundary.
- **Scope:** platform-governed registry; tenant rows are visible only to authorized members or administrators; RLS required.
- **Keys/relationships:** UUID `id`; unique stable `code`; one tenant has many memberships, workspaces, configurations, and tenant-private records.
- **Fields/lifecycle/time:** name, code, status (`provisioning`, `active`, `suspended`, `archived`), default locale/time zone, classification policy reference, created/activated/archived times.
- **Provenance/deletion:** creation and status changes audited; archive rather than delete after tenant data exists.
- **Atlas:** A-041.

### 8.2 `bios_core.profiles` — Phase 1 core / Migration 001

- **Purpose:** BIOS-owned representation of an authenticated identity.
- **Scope:** global identity metadata with self/admin policy; not a tenant authorization source; RLS required if client-exposed.
- **Keys/relationships:** UUID `id`; unique FK `auth_user_id → auth.users.id`; one profile has many memberships and may author records.
- **Fields/lifecycle/time:** display name, preferred language, status, created/updated times. No credentials or provider tokens.
- **Provenance/deletion:** profile changes audited; deactivation/anonymization follows retention policy.
- **Atlas:** A-041.

### 8.3 `bios_core.tenant_memberships` — Phase 1 core / Migration 001

- **Purpose:** attaches a profile to a tenant and forms the normal authorization principal.
- **Scope:** tenant-scoped; member self-read and authorized administration; RLS required.
- **Keys/relationships:** UUID `id`; FKs to tenant and profile; unique active membership per tenant/profile; tenant and profile each have many memberships.
- **Fields/lifecycle/time:** status (`invited`, `active`, `suspended`, `revoked`), invitation/activation/revocation times, optional validity interval.
- **Provenance/deletion:** every lifecycle transition audited; revoke rather than delete.
- **Atlas:** A-041.

### 8.4 `bios_core.roles` and `bios_core.membership_roles` — Phase 1 core / Migration 001

- **Purpose:** governed role definitions and many-to-many assignment to tenant memberships.
- **Scope:** platform roles are shared; tenant-defined roles, if later allowed, are explicitly tenant-owned. Assignments are tenant-scoped; RLS required.
- **Keys/relationships:** UUID role and assignment IDs; stable role code; assignment FKs to membership and role; one membership may hold many roles.
- **Fields/lifecycle/time:** role name, capability definition/reference, status, assignment validity and grantor.
- **Provenance/deletion:** changes and grants/revocations audited; referenced roles are deprecated, not deleted.
- **Atlas:** A-037, A-041. Fine-grained capabilities may be added after authorization requirements are validated.

### 8.5 `bios_core.workspaces` — Phase 1 candidate / Migration 001 conditional

- **Purpose:** optional organizational and collaboration scope inside a tenant.
- **Scope:** tenant-scoped; RLS required.
- **Keys/relationships:** UUID `id`; non-null FK to tenant under the Phase 1 candidate; one tenant has many workspaces.
- **Fields/lifecycle/time:** name, stable tenant-local code, status, settings reference, created/archived times.
- **Provenance/deletion:** lifecycle audited; archive rather than delete after content exists.
- **Atlas:** A-041. This table must not encode Client semantics.

### 8.6 `bios_core.workspace_memberships` — Phase 1 candidate / Migration 001 conditional

- **Purpose:** narrows tenant membership authorization to a workspace.
- **Scope:** tenant-scoped; RLS required.
- **Keys/relationships:** UUID `id`; FK to workspace and tenant membership; unique active pair; a membership may join many workspaces.
- **Fields/lifecycle/time:** status, role override/reference if approved, validity interval.
- **Provenance/deletion:** grant/revoke audited; revoke rather than delete.
- **Atlas:** A-041.

**Client:** no Phase 1 core table is approved. If commercial client tracking is required before semantics are resolved, it belongs in the commercial system of record or a reversible external mapping—not as a synonym for Tenant.

## 9. Geography, markets, groupings, and languages

### 9.1 `bios_core.geographies` and `bios_core.geography_relationships` — Phase 1 core

- **Purpose:** governed places and configurable hierarchy/containment relationships.
- **Scope:** shared reference; platform-curated reads; tenant overrides use mappings, not mutation.
- **Keys/relationships:** UUID IDs with stable standard codes where available; typed parent/child relationship supports many hierarchy schemes.
- **Fields/lifecycle/time:** name, geography type, external codes, relationship type, validity interval, status.
- **Provenance/deletion:** source and effective dates required; supersede rather than erase historical boundaries.
- **Atlas:** A-026, A-030, A-036.

### 9.2 `bios_core.markets` — Phase 1 core

- **Purpose:** configurable commercial/analytical operating scopes.
- **Scope:** shared registry with optional tenant availability/configuration; platform-governed.
- **Keys/relationships:** UUID `id`, unique code; optional primary geography link through association; many markets may reference overlapping geographies.
- **Fields/lifecycle/time:** name, status, operational priority as governed data, effective dates.
- **Provenance/deletion:** definition source and change history; deactivate/supersede, do not delete referenced markets.
- **Atlas:** A-026, A-036. No priority country is a constraint.

### 9.3 `bios_core.market_geographies` — Phase 1 core

- **Purpose:** maps markets to geographies without asserting identity.
- **Scope:** shared, governed.
- **Keys/relationships:** composite uniqueness over market, geography, relationship type, and valid interval; many-to-many.
- **Fields/lifecycle/time:** relationship type (`primary`, `included`, `excluded`, or governed equivalent), validity, source.
- **Provenance/deletion:** version relationships; retain historical mappings.
- **Atlas:** A-026, A-030, A-036.

### 9.4 `bios_core.market_groups` and `bios_core.market_group_members` — Phase 1 core

- **Purpose:** configurable analytical, operational, geographic, reporting, or portfolio groupings.
- **Scope:** may be shared or explicitly tenant-scoped; scope is mandatory and policy-specific; tenant rows use RLS.
- **Keys/relationships:** UUID group and membership IDs; members reference markets; nested groups are deferred unless required.
- **Fields/lifecycle/time:** group type, name, status, valid interval, ordered membership where needed.
- **Provenance/deletion:** membership changes versioned/audited; archive groups used in decisions.
- **Atlas:** A-026, A-036, A-037. “Greater China” is a group configuration, not a hard-coded market parent.

### 9.5 `bios_core.languages` and `bios_core.market_languages` — Phase 1 core

- **Purpose:** governed language/script/locale registry and market usage relationships.
- **Scope:** shared reference.
- **Keys/relationships:** UUID IDs with unique BCP 47 or approved stable code; many-to-many market/language links.
- **Fields/lifecycle/time:** language name, script/locale metadata, usage role (`primary`, `official`, `operational`, `supported`), validity and status.
- **Provenance/deletion:** source required; deactivate/supersede referenced codes.
- **Atlas:** A-028, A-038.

## 10. Domains, categories, and packs

### 10.1 `bios_core.domains` — Phase 1 core

- **Purpose:** governed subject/ontology boundary independent of any specific category.
- **Scope:** shared definitions with explicit tenant-private domains permitted when needed; tenant rows use RLS.
- **Keys/relationships:** UUID `id`, stable scope-local code; one domain has many nodes and pack versions.
- **Fields/lifecycle/time:** name, description, scope, status, version lineage, effective dates.
- **Provenance/deletion:** owner and source required; supersede/archive after use.
- **Atlas:** A-025, A-027, A-035.

### 10.2 `bios_core.domain_nodes` and `bios_core.domain_node_relationships` — Phase 1 core

- **Purpose:** represent categories, subcategories, concepts, and configurable taxonomy/ontology structure.
- **Scope:** inherits domain scope; tenant-scoped nodes use RLS.
- **Keys/relationships:** UUID IDs; node belongs to one domain; typed relationships support hierarchy or mappings; many-to-many where necessary.
- **Fields/lifecycle/time:** node type, code, labels by language through label records or localized metadata, status, validity.
- **Provenance/deletion:** source and version required; no destructive removal after use.
- **Atlas:** A-025, A-027, A-030, A-035. Advanced ontology axioms are deferred.

### 10.3 `bios_core.pack_definitions`, `pack_versions`, and `tenant_pack_activations` — Phase 1 extension

- **Purpose:** version Market Packs and Domain Packs and govern tenant activation.
- **Scope:** pack definitions may be shared or tenant-private; activations are tenant-scoped with RLS.
- **Keys/relationships:** UUID IDs; pack type, target market/domain, ordered immutable versions; activation references tenant, version, and optional workspace.
- **Fields/lifecycle/time:** semantic version, status (`draft`, `approved`, `deprecated`), configuration manifest, effective interval.
- **Provenance/deletion:** approver, checksum, and supersession required; activated versions immutable.
- **Atlas:** A-026, A-035, A-036, A-037. Manifest JSONB is allowed only behind a validated schema.

### 10.4 `bios_core.attribute_definitions` and typed/JSONB extension values — Phase 1 extension

- **Purpose:** represent genuinely variable domain/entity/evidence attributes without core schema churn.
- **Scope:** definition scope explicit; tenant definitions and values use RLS.
- **Keys/relationships:** definition belongs to domain/pack and targets an approved object type; values reference definition and target through constrained per-target tables or owned adapters.
- **Fields/lifecycle/time:** data type, validation constraints, unit, cardinality, status, definition version; value and validity.
- **Provenance/deletion:** source, creator, and definition version required; supersede values rather than rewrite history where decision-relevant.
- **Atlas:** A-027, A-035. A generic unconstrained entity-attribute-value table is prohibited.

## 11. Entities

### 11.1 `bios_knowledge.entities` — Phase 1 core

- **Purpose:** stable identity for analyzed organizations, brands, products, people, places, channels, and other governed types.
- **Scope:** explicitly shared or tenant-scoped; tenant entities carry non-null tenant ownership and RLS.
- **Keys/relationships:** UUID `id`; governed entity-type FK; self/other relations through relationship table; many links to evidence, markets, and domains.
- **Fields/lifecycle/time:** canonical name, entity type, scope, status (`candidate`, `active`, `merged`, `archived`), valid interval, merge target.
- **Provenance/deletion:** creation/match/merge source and reviewer required; merge is auditable and reversible; no deletion after citation.
- **Atlas:** A-029, A-031, A-041.

### 11.2 `bios_knowledge.entity_aliases` — Phase 1 core

- **Purpose:** market-, language-, source-, or time-specific names for an entity.
- **Scope:** inherits entity scope; RLS for tenant aliases.
- **Keys/relationships:** UUID `id`; many aliases per entity; optional language, market, and source-document references.
- **Fields/lifecycle/time:** alias text, alias type, normalized key, confidence, validity.
- **Provenance/deletion:** match method and reviewer recorded; supersede incorrect aliases.
- **Atlas:** A-028, A-031, A-038.

### 11.3 `bios_knowledge.entity_relationships` — Phase 1 core

- **Purpose:** typed, directed or symmetric relationships between entities.
- **Scope:** explicit shared or tenant scope compatible with endpoints; tenant-derived relationships remain tenant-owned and use RLS.
- **Keys/relationships:** UUID `id`; subject and object entity FKs; governed relationship type; many-to-many.
- **Fields/lifecycle/time:** relationship type, confidence, status, valid interval.
- **Provenance/deletion:** evidence links or source required; corrections supersede prior relationships.
- **Atlas:** A-030, A-031, A-042.

### 11.4 `bios_knowledge.entity_market_presence` and `entity_domain_memberships` — Phase 1 core

- **Purpose:** qualify entity participation by market and domain/category.
- **Scope:** inherits entity/claim scope; tenant rows use RLS.
- **Keys/relationships:** UUID IDs; many-to-many entity/market and entity/domain-node links.
- **Fields/lifecycle/time:** role/classification, confidence, status, valid interval.
- **Provenance/deletion:** evidence/source and method required; supersede rather than overwrite.
- **Atlas:** A-026, A-030, A-031, A-035.

## 12. Sources and ingestion

### 12.1 `bios_knowledge.sources` — Phase 1 core

- **Purpose:** governed origin, publisher, feed, repository, interview, or observation channel.
- **Scope:** explicit shared or tenant-scoped; rights/classification control visibility; tenant rows use RLS.
- **Keys/relationships:** UUID `id`; governed source type; one source has many documents and optional connector definitions.
- **Fields/lifecycle/time:** name, source type, URI/origin metadata, owner/publisher, license/classification, reliability metadata, status.
- **Provenance/deletion:** creation and rights basis required; deactivate, never erase cited sources.
- **Atlas:** A-029, A-042.

### 12.2 `bios_internal.source_connectors` — Phase 1 extension / deferred from Migration 001

- **Purpose:** configuration for automated acquisition adapters.
- **Scope:** tenant-scoped or platform-operated with explicit allowed tenants; restricted, never client-exposed.
- **Keys/relationships:** UUID `id`; connector type and source FK; credentials referenced by secret handle, never stored directly.
- **Fields/lifecycle/time:** configuration version, schedule, status, last health state.
- **Provenance/deletion:** changes and executions audited; revoke/archive on retirement.
- **Atlas:** A-026, A-036, A-037. Create only with the first automated connector.

### 12.3 `bios_knowledge.source_documents` — Phase 1 core

- **Purpose:** immutable/versioned acquired source artifact and canonical metadata.
- **Scope:** explicit shared or tenant-scoped; tenant documents use RLS; storage object policy must match row policy.
- **Keys/relationships:** UUID `id`; source FK; optional predecessor/supersedes link; content-address/checksum uniqueness within authorized scope.
- **Fields/lifecycle/time:** title, original language, publication/observed/acquired times, source URI, storage reference, checksum, media type, classification, status.
- **Provenance/deletion:** acquisition actor/method and rights required; quarantine or tombstone rather than delete after citation; binary may follow retention policy.
- **Atlas:** A-028, A-029, A-030, A-038.

### 12.4 `bios_internal.ingestion_records` — Phase 1 extension / deferred from Migration 001

- **Purpose:** idempotent operational history of acquire, extract, normalize, classify, and link attempts.
- **Scope:** tenant-scoped when processing tenant material; restricted internal access and RLS/privileged policies.
- **Keys/relationships:** UUID `id`; connector/source/document and retry/idempotency links; one document may have many processing attempts.
- **Fields/lifecycle/time:** stage, status, idempotency key, start/end time, configuration version, safe error metadata.
- **Provenance/deletion:** append operational attempts; retain by operational policy without source content in logs.
- **Atlas:** A-028, A-032, A-036. Create with automated ingestion.

## 13. Evidence and provenance

### 13.1 `bios_knowledge.evidence` — Phase 1 core

- **Purpose:** citable observation, excerpt, fact, or artifact used by intelligence.
- **Scope:** explicitly shared or tenant-scoped; tenant evidence has non-null tenant ownership and RLS.
- **Keys/relationships:** UUID `id`; source document or authorized observation provenance required; many-to-many links to entities, markets, domains.
- **Fields/lifecycle/time:** evidence type, canonical locator/excerpt reference, original language, status (`draft`, `active`, `corrected`, `superseded`, `withdrawn`), observed/published/valid times, confidence/quality metadata, classification.
- **Provenance/deletion:** extraction method, actor, source locator, version and correction chain required; no destructive update after use.
- **Atlas:** A-028–A-030, A-038, A-042.

### 13.2 `bios_knowledge.evidence_representations` — Phase 1 core

- **Purpose:** versioned original, normalized, transliterated, or translated content representation.
- **Scope:** inherits evidence scope; RLS for tenant representations.
- **Keys/relationships:** UUID `id`; evidence FK; optional source-representation FK; many immutable versions per evidence/language/type.
- **Fields/lifecycle/time:** representation type, language/locale, content or protected storage reference, method/model/configuration version, confidence, review status, created time.
- **Provenance/deletion:** immutable after publication; correction creates a new representation and supersession link; original representation retained.
- **Atlas:** A-028, A-038.

### 13.3 Evidence scope-link tables — Phase 1 core

`evidence_entities`, `evidence_markets`, and `evidence_domains` provide explicit many-to-many links.

- **Scope:** inherits evidence tenant/scope; RLS required for tenant links.
- **Keys/relationships:** composite uniqueness plus UUID if links need independent provenance; FKs to evidence and target; domain links may target domain nodes.
- **Fields/lifecycle/time:** link role, confidence, validity/status.
- **Provenance/deletion:** linking method/actor and review state required; supersede incorrect links.
- **Atlas:** A-026–A-031, A-035, A-038.

### 13.4 `bios_knowledge.provenance_edges` — Phase 1 core

- **Purpose:** constrained derivation/citation graph connecting supported canonical object types.
- **Scope:** explicit tenant or shared; edge scope must be no broader than the most restrictive endpoint; tenant edges use RLS.
- **Keys/relationships:** UUID `id`; typed upstream/downstream references implemented through constrained per-type link tables or validated registry—not unenforced arbitrary IDs.
- **Fields/lifecycle/time:** relationship type (`derived_from`, `supports`, `contradicts`, `supersedes`, or governed equivalent), method/version, actor/agent, created time.
- **Provenance/deletion:** append-oriented; no ordinary hard deletion.
- **Atlas:** A-029, A-030, A-038, A-039, A-042.

## 14. Intelligence chain

### 14.1 `bios_intelligence.signals` and `signal_evidence` — Phase 1 core

- **Purpose:** noteworthy evidence-backed change or indicator and its supporting/contradicting evidence.
- **Scope:** tenant-scoped by default; a separately curated shared signal requires shared-only provenance; RLS required.
- **Keys/relationships:** UUID signal ID; non-null tenant; many evidence links with role and weight.
- **Fields/lifecycle/time:** title/statement, signal type, status (`draft`, `review`, `active`, `superseded`, `rejected`), confidence, observed/valid interval.
- **Provenance/deletion:** creator/method and evidence required before active state; supersede/archive after use.
- **Atlas:** A-028, A-029, A-039, A-041.

### 14.2 `bios_intelligence.patterns` and `pattern_signals` — Phase 1 core, automation deferred

- **Purpose:** supported recurrence or relationship across signals.
- **Scope:** tenant-scoped by default; RLS required.
- **Keys/relationships:** UUID pattern ID; non-null tenant; many-to-many signal links with relationship role.
- **Fields/lifecycle/time:** statement, pattern type, method, status, confidence, valid interval.
- **Provenance/deletion:** supporting signals required before active state; author/reviewer and method version recorded; supersede/archive.
- **Atlas:** A-033, A-039. Human-authored patterns are allowed; automated generation is deferred.

### 14.3 `bios_intelligence.findings`, `finding_evidence`, and `finding_patterns` — Phase 1 core

- **Purpose:** analytical conclusion supported by evidence and/or patterns.
- **Scope:** tenant-scoped by default; RLS required.
- **Keys/relationships:** UUID finding ID; non-null tenant; many evidence and pattern links with support/contradiction role.
- **Fields/lifecycle/time:** statement, implication, confidence, status, effective/valid time, review state.
- **Provenance/deletion:** at least one upstream support path before active; method, author/agent, and reviewer recorded; supersede/archive.
- **Atlas:** A-028, A-034, A-039.

Tenant ownership compatibility is mandatory: a tenant-derived signal, pattern, or finding cannot become shared merely because all cited reference inputs are shared. Mixed shared/private inputs always produce tenant-private derived intelligence.

## 15. Decision architecture

### 15.1 `bios_intelligence.decision_contexts` — Phase 1 core

- **Purpose:** governed package of decision question, objective, scope, constraints, time horizon, stakeholders, and intelligence.
- **Scope:** tenant-scoped; non-null tenant and RLS required; never cross-tenant.
- **Keys/relationships:** UUID `id`; optional primary workspace candidate; many links to workspaces, markets, domains/nodes, entities, evidence, signals, patterns, and findings.
- **Fields/lifecycle/time:** title, decision question, objective, status (`draft`, `active`, `review`, `closed`, `archived`), horizon, opened/due/closed times, classification.
- **Provenance/deletion:** creator, scope changes, and upstream links audited; archive, never delete after recommendation or decision.
- **Atlas:** A-039, A-040, A-041.

### 15.2 Decision-context scope links — Phase 1 core

`decision_context_workspaces`, `decision_context_markets`, `decision_context_domains`, and `decision_context_entities` provide explicit many-to-many scope.

- **Scope:** tenant-scoped; linked workspace and context must share tenant; RLS required.
- **Keys/relationships:** association IDs or composite keys; role/priority allowed.
- **Fields/lifecycle/time:** scope role, inclusion/exclusion, validity/order where needed.
- **Provenance/deletion:** scope change history retained once used for a recommendation/decision.
- **Atlas:** A-026, A-035, A-040, A-041. Cross-workspace links are conditional on A-041; multi-market and multi-domain are allowed.

### 15.3 `bios_intelligence.recommendations` and supporting links — Phase 1 core when first workflow requires them

- **Purpose:** proposed action with rationale, alternatives, confidence, assumptions, and supporting findings.
- **Scope:** tenant-scoped; RLS required.
- **Keys/relationships:** UUID `id`; decision-context FK; many finding/evidence links; one context may have many recommendations and versions.
- **Fields/lifecycle/time:** action, rationale, alternatives, confidence, status (`draft`, `review`, `approved`, `rejected`, `superseded`), proposed/effective times.
- **Provenance/deletion:** author/agent, method/version, supporting chain, and human review required before consequential use; supersede/archive.
- **Atlas:** A-033, A-034, A-040, A-043. A generic workflow engine is deferred.

### 15.4 `bios_intelligence.decisions` — Phase 1 core when first workflow requires them

- **Purpose:** authorized choice and its accountable outcome.
- **Scope:** tenant-scoped; RLS required.
- **Keys/relationships:** UUID `id`; decision-context FK required; recommendation FK optional; owner membership required; one context may record multiple sequenced decisions.
- **Fields/lifecycle/time:** decision statement, rationale, status (`recorded`, `authorized`, `implemented`, `reversed`, `superseded`), decided/effective/review times, authority source.
- **Provenance/deletion:** decision owner/authorizer, authority, context, and supporting chain retained; never ordinarily delete.
- **Atlas:** A-040, A-041, A-043. A decision may exist without a BIOS recommendation if its authority and origin are recorded.

### 15.5 `bios_intelligence.decision_stakeholders` — Phase 1 core when decision workflow exists

- **Purpose:** records owner, authorizer, reviewer, contributor, and informed parties.
- **Scope:** tenant-scoped; RLS required.
- **Keys/relationships:** UUID `id`; context or decision and tenant-membership FK; optional external stakeholder reference only through an approved contact model.
- **Fields/lifecycle/time:** stakeholder role, status, validity.
- **Provenance/deletion:** assignment changes audited; retain historical owners.
- **Atlas:** A-040, A-041, A-043.

## 16. Governance and audit

### 16.1 `bios_governance.assumptions` and `assumption_evidence` — Phase 1 extension

- **Purpose:** operate the Atlas lifecycle inside BIOS if repository documents become insufficient.
- **Scope:** shared governance or explicitly tenant-scoped product assumptions; tenant rows use RLS.
- **Keys/relationships:** stable assumption code plus UUID; evidence links to governed evidence or external approved records.
- **Fields/lifecycle/time:** statement, classification, status, owner, criteria, review gate/date, supersedes link.
- **Provenance/deletion:** status transitions append history; resolved assumptions retained.
- **Atlas:** self-governing. Defer from Migration 001 while ARCH-002 is authoritative.

### 16.2 `bios_governance.human_reviews` — Phase 1 core only when a governed review transition is implemented

- **Purpose:** attributable review of evidence, intelligence, recommendations, or decisions.
- **Scope:** tenant-scoped unless reviewing shared governance; RLS and restricted writes required.
- **Keys/relationships:** UUID `id`; reviewer membership; constrained target type/id or per-target link tables; many reviews per target.
- **Fields/lifecycle/time:** review type, outcome, reason, policy/version, reviewed_at, supersedes review.
- **Provenance/deletion:** immutable event after submission; correction is a new review.
- **Atlas:** A-034, A-043. Avoid an unconstrained polymorphic FK.

### 16.3 `bios_internal.agent_runs` — Deferred

- **Purpose:** auditable execution record for bounded agent work.
- **Scope:** tenant-scoped and internal; RLS/privileged access; no untrusted direct write.
- **Keys/relationships:** UUID run ID; tenant, initiator membership/service, optional decision context; child runs only if orchestration is validated.
- **Fields/lifecycle/time:** purpose, model/config/prompt version, granted tools, input/output references, status, start/end, usage/cost, error classification, review state.
- **Provenance/deletion:** append execution history; sensitive content referenced, not copied unnecessarily; retention policy applies.
- **Atlas:** A-033, A-034, A-043. Not in Migration 001.

### 16.4 `bios_governance.audit_events` — Phase 1 core / Migration 001 minimal

- **Purpose:** append-oriented record of security and governance-significant actions.
- **Scope:** tenant-aware or platform-scope explicitly; restricted writes and controlled reads; ordinary users cannot mutate events.
- **Keys/relationships:** UUID `id`; tenant where applicable; actor profile/service, action, resource type/id, correlation ID.
- **Fields/lifecycle/time:** occurred_at, action, outcome, reason, safe before/after metadata, source address/client metadata where approved.
- **Provenance/deletion:** append-only; cryptographic hardening may follow; retained by policy and separated from application logs.
- **Atlas:** A-029, A-034, A-041–A-043.

## 17. Critical invariants

| Invariant | Phase 1 rule | Atlas dependency |
|---|---|---|
| Workspace ownership | Candidate rule: every workspace belongs to exactly one tenant; do not encode Client semantics | A-041; must be accepted before workspace constraints in Migration 001 |
| User membership | One profile may belong to many tenants and workspaces through independent memberships | A-041 |
| Evidence sharing | Tenant evidence is never directly readable by another tenant | A-029, A-041 |
| Shared reference knowledge | Must have explicit shared scope, rights, and shared provenance | A-029, A-042 |
| Tenant-derived shared knowledge | No Phase 1 promotion; future promotion requires tenant authorization, rights/privacy review, de-identification, human approval, new provenance, and audit | A-042 |
| Decision Context tenant scope | Exactly one tenant; never cross-tenant | Accepted security rule |
| Decision Context workspace scope | Single or multiple workspaces only within the same tenant; final Phase 1 policy unresolved | A-041 |
| Decision Context market/domain scope | May span multiple markets and multiple domains/categories through explicit links | A-026, A-035, A-040 |
| Consequential recommendation | Must have risk-appropriate human approval before external action | A-034, A-043 |
| Decision without recommendation | Allowed with decision context, authority source, owner, and provenance | A-040, A-043 |
| Evidence representations | Immutable versions; a correction creates a new version/supersession | A-028, A-038 |
| Evidence correction | Historical record and prior citations remain reconstructable | A-030, A-038 |
| Intelligence ownership | Signals, patterns, and findings are tenant-scoped by default | A-029, A-039, A-041 |
| Mixed-scope derivation | Shared reference plus tenant-private evidence yields tenant-private derived intelligence | A-029, A-042 |
| Ownership propagation | Every derived object and relationship must carry or deterministically enforce the same tenant as its tenant-private upstream inputs | Accepted security rule |
| Cross-tenant link | Prohibited except a governed platform reference link that cannot disclose tenant-private existence or content | A-029, A-041 |
| Original language | Original representation is retained and distinguishable from normalized/translated content | A-028, A-038 |
| Hard-coded markets/categories | Prohibited; use governed registries and relationships | A-025, A-026, A-035, A-036 |

## 18. RLS policy expectations

Every exposed tenant-scoped table must enable RLS and define positive and negative policy tests.

Baseline rules:

1. No authenticated or anonymous access without an active authorized tenant membership.
2. Workspace restrictions narrow tenant access; they never broaden it.
3. Inserted `tenant_id` must equal the authorized operation context and cannot be client-selected arbitrarily.
4. Updates cannot move a row between tenants.
5. Relationship writes require authorization to both endpoints and tenant compatibility.
6. Shared reference reads use separate explicit policies; untrusted writes are prohibited.
7. Service-role bypass is restricted to named server workflows with audit.
8. Suspended/revoked memberships lose access immediately according to policy.
9. Tests include same-tenant allow, other-tenant deny, missing-context deny, role deny, and workspace-boundary cases.

## 19. Migration 001 recommendation

### 19.1 Smallest coherent scope

Migration 001 should establish only stable security and registry foundations:

1. Application schemas and required extensions approved by ADR-001.
2. `tenants`, `profiles`, `tenant_memberships`, `roles`, and `membership_roles`.
3. `workspaces` and `workspace_memberships` only after explicit acceptance of the A-041 Phase 1 candidate.
4. Minimal `audit_events` for membership and privileged changes.
5. RLS, constraints, indexes, and positive/negative isolation tests for those tables.

Geography, language, market, domain, entity, evidence, and intelligence tables should enter subsequent focused migrations after their exact constraints and seed governance are reviewed. They are Phase 1 core, but not prerequisites for proving the tenant boundary.

### 19.2 Explicitly deferred from Migration 001

| Concept | Recommendation | Reason |
|---|---|---|
| `agent_runs` | Defer | No validated specialist-agent workflow; A-033 |
| `source_connectors` | Defer | Manual ingestion can precede automated adapters |
| Flexible/domain attributes | Defer | Await representative Domain Pack needs; A-035 |
| Automated pattern generation | Defer | Human-authored patterns establish semantics first |
| Recommendation workflow engine | Defer | Store recommendation state later; avoid speculative workflow tables |
| Advanced ontology structures | Defer | A-027 unvalidated; simple domain nodes are sufficient initially |
| Vector infrastructure | Defer | A-032 requires workload evidence; vectors are projections |
| Atlas operational tables | Defer | ARCH-002 is the current authoritative register |
| Knowledge-promotion workflow | Defer/prohibit | A-042 unresolved and disclosure is low-reversibility |

### 19.3 Migration 001 blockers

- Confirm the A-041 candidate if Workspace tables are included: each workspace belongs to exactly one tenant; users join through tenant membership; no cross-tenant workspace or decision object.
- Approve the initial role/capability baseline and privileged administrative path.
- Approve schema exposure and RLS test strategy.
- Decide whether the first migration includes Workspace or leaves it for Migration 002 without affecting tenant foundations.

## 20. Data-model consistency rules

- Market Pack targets the same `markets` registry used by evidence and decision contexts.
- Domain Pack targets the same `domains/domain_nodes` registry used by entities, evidence, and decision contexts.
- Signal-to-evidence, Pattern-to-signal, and Finding-to-pattern/evidence links preserve the ARCH-001 chain.
- Recommendations belong to Decision Contexts; Decisions belong to Decision Contexts and may optionally reference Recommendations.
- Shared versus tenant-private scope follows ARCH-001 and A-029/A-042; no mixed null-tenant convention is allowed.
- PostgreSQL stores canonical objects; vectors, search indexes, files, and analytics are referenced projections or managed artifacts.
- No table names or constraints encode dairy, a named market, a priority tier, or a fixed language.

## 21. Open decisions reported, not resolved

1. **Tenant/Client/Workspace:** Client remains undefined; workspace cardinality is a reversible Phase 1 candidate under A-041.
2. **Workspace scope of Decision Context:** multi-workspace within one tenant is structurally possible but product policy is unapproved.
3. **Shared knowledge promotion:** explicitly disabled until A-042 is resolved.
4. **Ontology depth:** domain nodes are adequate for a reversible start; advanced semantics await A-027.
5. **Human review storage:** include only when the first governed transition needs it; policy semantics await A-034/A-043.
6. **Temporal depth:** essential timestamps and supersession are required; formal bitemporality awaits A-030 evidence.

## 22. Version history

| Version | Date | Change |
|---|---|---|
| 1.0 | 2026-08-02 | Initial canonical Phase 1 logical data model and reduced-scope Migration 001 recommendation |
