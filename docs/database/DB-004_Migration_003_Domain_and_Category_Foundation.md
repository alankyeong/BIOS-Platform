# DB-004 — BIOS Migration 003: Domain & Category Foundation

| Field | Value |
|---|---|
| Document ID | DB-004 |
| Title | BIOS Migration 003 — Domain & Category Foundation |
| Version | 1.0 |
| Status | Canonical |
| Effective date | 2026-08-03 |
| Owner | BIOS Executive Office — Data Architecture and Engineering |
| Dependencies | ADR-001, ARCH-001, ARCH-002, DB-001, DB-002 v1.1, DB-003 v1.1, ENG-001, CANON-001 |
| Supersedes | None |
| Review cadence | Before SQL implementation, before merge, and after relevant Atlas resolution |
| Related documents | [README](../../README.md), [ENG-001](../engineering/ENG-001_BIOS_Engineering_Handbook.md), [CANON-001](../engineering/CANON-001_Repository_and_Engineering_Standards.md), [ADR-001](../decisions/ADR-001_PostgreSQL_and_Supabase.md), [ARCH-001](../architecture/ARCH-001_Canonical_Platform_Architecture.md), [ARCH-002](../architecture/ARCH-002_Architecture_Assumption_Register.md), [DB-001](DB-001_Canonical_Data_Model.md), [DB-002](DB-002_Migration_001_Core_Platform_Foundation.md), [DB-003](DB-003_Migration_002_Geography_Market_and_Language_Foundation.md) |

## 1. Purpose

DB-004 defines exactly what the third executable PostgreSQL/Supabase migration is permitted to create. Migration 003 establishes a reusable, category-neutral Domain and Domain-node foundation for later BIOS Entity, Evidence, Intelligence, and Decision layers.

The model supports arbitrary consumer and commercial categories without named-category hard-coding. Dairy and every other named vertical are illustrative only and create no seed, column, table, constraint, or lifecycle requirement.

This is an implementation design specification. It contains no SQL.

## 2. Canonical concepts

- **Domain:** a governed subject or ontology boundary.
- **Domain Node:** a governed category, subcategory, concept, segment, or other node belonging to exactly one Domain. Migration 003 does not classify which of those meanings applies.
- **Domain-node relationship:** a typed, historical hierarchy edge within one Domain.

Domain and Domain Node are distinct. Hierarchy is expressed through relationships, never fixed-depth columns or `parent_id`.

## 3. Exact migration boundary

Migration 003 may create exactly three tables:

1. `bios_core.domains`
2. `bios_core.domain_nodes`
3. `bios_core.domain_node_relationships`

Canonical support:

| Table | Canonical authority | Assessment |
|---|---|---|
| `bios_core.domains` | ARCH-001 Domain architecture; DB-001 Phase 1 core | Authorized |
| `bios_core.domain_nodes` | ARCH-001 category-neutral hierarchy; DB-001 Phase 1 core | Authorized |
| `bios_core.domain_node_relationships` | DB-001 hierarchy/graph relationship model | Authorized |

Supporting objects are limited to constraints, indexes, RLS policies, grants, narrow trusted mutation functions, timestamp/immutability protection, cycle/status-dependency checks, additive audit resource types, and narrow supporting triggers/functions. No extension is authorized.

## 4. Explicit exclusions

Migration 003 must not create:

- Market Pack, Domain Pack, pack definition/version/activation, or Market–Domain association;
- attribute definition, generic EAV, localized-label, or tenant-private ontology structures;
- Entity, alias, entity relationship, Source, document, Evidence, representation, or provenance structures;
- Signal, Pattern, Finding, Decision Context, Recommendation, or Decision structures;
- ontology axioms, inference rules, reasoning engines, vectors, agents, connectors, or ingestion records;
- Client-specific or named-category-specific tables or columns.

## 5. Common conventions

| Concern | Migration 003 rule |
|---|---|
| Primary key | BIOS-owned UUID generated independently of business meaning |
| Stable code | 3–64 lowercase characters matching `^[a-z][a-z0-9_]{1,62}[a-z0-9]$` |
| Name | Trimmed text, 1–200 characters |
| Description | Nullable; when non-null, equals its trimmed value, contains 1–1,000 characters, and is never whitespace-only |
| Lifecycle | `draft → active → deprecated`; deprecated is terminal |
| Time | `timestamptz`; `created_at` is database-set and immutable; `updated_at` is database-maintained on every governed row mutation |
| Scope | Shared platform reference only; no `tenant_id` |
| Mutation | Trusted BIOS service or exceptional platform administration only |
| Physical deletion | Not supported through the governed Migration 003 application model |
| Relationship history | Immutable episode with `valid_from` and nullable `valid_to` |
| Active episode | `valid_to` is null; scheduled future activation is not supported |

## 6. Implementation decisions requiring approval

### M003-D01 — Domain scope — APPROVED

Implement shared platform-governed Domains only. Tenant-private/custom Domains are deferred until tenant configuration, ownership, review, and ontology-governance workflows exist. No nullable `tenant_id` or mixed-scope table is permitted.

### M003-D02 — Domain identity — APPROVED

Use a BIOS-owned UUID primary key and globally unique immutable BIOS `code`. Display `name` and nullable `description` are governed correctable metadata, never identity. A non-null description must equal its trimmed value, contain at least one character, and contain no more than 1,000 characters. Use the common lifecycle and code regex in Section 5.

### M003-D03 — Domain-node type vocabulary — APPROVED

Omit `node_type` entirely. Migration 003 needs stable node identity and hierarchy, not a speculative classification among category, subcategory, concept, or segment. A governed type may be added later when a concrete workflow supplies semantics and validation.

### M003-D04 — Domain-node code uniqueness — APPROVED

Require an immutable code unique within its Domain: `UNIQUE(domain_id, code)` at the logical level. Codes are not globally unique because identical text can represent different concepts in different Domain boundaries. Code format and length use Section 5.

### M003-D05 — Relationship vocabulary — APPROVED

Permit exactly `contains`. Direction is precise: the subject Domain Node contains the object Domain Node. Self-links are prohibited. No equivalence, broader/narrower, causal, association, substitution, or mapping relationship is introduced.

### M003-D06 — Polyhierarchy — APPROVED

Use a directed acyclic graph. A Node may have zero, one, or multiple active parent Nodes within its Domain. The relationship table is authoritative; there is no `parent_id` and no fixed depth. Transitive cycles are prohibited.

### M003-D07 — Cross-Domain relationships — APPROVED

Prohibit cross-Domain edges. Both endpoints must belong to the relationship row’s same non-null Domain. Cross-Domain mappings are deferred until mapping requirements and relationship semantics are Atlas-validated.

### M003-D08 — Lifecycle — APPROVED

Use `draft → active → deprecated`, with `deprecated` terminal and no reactivation in Migration 003. Governed Domain and Node creation always produces `draft`; creation operations do not accept caller-selected `active` or `deprecated` status. Activation is a separate governed operation. Lifecycle changes update `updated_at`, are validated/audited, and never cascade.

### M003-D09 — Relationship history — APPROVED

Use immutable relationship episodes with `valid_from` and nullable `valid_to`. Relationship episodes have no draft lifecycle: successful creation is immediately active with `valid_to` null and database-set `valid_from`. Creation requires active Domain and endpoints and does not accept caller-selected future activation. Ending is the only governed state change; it sets `valid_to`, updates `updated_at`, retains history, and permits a later new episode. Duplicate active edges are rejected. Full bitemporality, scheduled activation, and retroactive correction are deferred.

### M003-D10 — Multilingual labels — APPROVED

Store one canonical governed `name` on Domain and Domain Node. Separate localized-label tables and JSONB translations are deferred until a concrete multilingual taxonomy workflow exists. Migration 002 Language identity remains available for that future model.

### M003-D11 — Market–Domain coupling — APPROVED

No Market–Domain or Market–Node association is created. Market/category combinations belong to later packs, configuration, Entity/Evidence links, or Decision scope and are not foundational identity.

### M003-D12 — Seed governance — APPROVED

The executable migration creates zero production Domain or Domain-node business rows. Reference taxonomy data requires a separate reviewed deterministic seed process. Tests may use synthetic Domains/Nodes. Named categories and commercial priority are never implied by seed presence.

### M003-D13 — Audit extension — APPROVED

Reuse the existing actions without adding any action:

- `reference.created`
- `reference.status_changed`
- `reference.metadata_updated`
- `reference.relationship_added`
- `reference.relationship_ended`

Add exactly these resource types:

- `domain`
- `domain_node`
- `domain_node_relationship`

The audit extension is additive in Migration 003 and must not edit earlier migration files. Physical deletion remains unsupported and has no action.

### M003-D14 — Activation and deprecation dependencies — APPROVED

This additional decision makes lifecycle SQL deterministic:

- Domains are created only as draft;
- Nodes are created only as draft and only under a draft or active Domain;
- Node creation under a deprecated Domain is rejected;
- activating a Node requires its Domain to be active;
- adding a hierarchy edge requires an active Domain and two active Nodes;
- a Domain cannot be deprecated while any Node in it is active;
- a Node cannot be deprecated while it participates in any active hierarchy edge as subject or object;
- callers end relevant edges explicitly before Node deprecation;
- deprecating a Domain or Node never cascades status/edge changes;
- ending an edge is independent of Node deprecation.

M003-D01 through M003-D14 have been approved by the BIOS Executive Office and no longer block SQL implementation.

## 7. Table specifications

### 7.1 `bios_core.domains`

#### Purpose and scope

Shared platform registry of governed subject/ontology boundaries. It contains no tenant, Market, category priority, or named-vertical field. RLS is required if API-exposed.

#### Fields

| Field | Type | Null | Default | Rule |
|---|---|---:|---|---|
| `id` | `uuid` | No | Generated UUID | Primary key; immutable |
| `code` | `text` | No | None | Globally unique; immutable |
| `name` | `text` | No | None | 1–200 trimmed characters |
| `description` | `text` | Yes | Null | Null or trimmed, non-empty, 1–1,000 characters |
| `status` | `text` | No | `draft` | `draft`, `active`, or `deprecated` |
| `created_at` | `timestamptz` | No | Transaction time | Immutable |
| `updated_at` | `timestamptz` | No | Transaction time | Database-maintained on metadata correction and lifecycle transition |
| `activated_at` | `timestamptz` | Yes | Null | Required for active/deprecated |
| `deprecated_at` | `timestamptz` | Yes | Null | Required only when deprecated |

#### Constraints and indexes

- Primary key on `id`; unique constraint on `code`.
- Checks enforce code/name bounds; description is null or trimmed, non-empty, and at most 1,000 characters; lifecycle vocabulary and transition/timestamp consistency are exact.
- Index on status and administrative name lookup; name is not identity.

#### Governance

`id` and `code` are immutable. `name` and `description` may be corrected by trusted platform administration after validation and `reference.metadata_updated` audit. Creation always starts draft and accepts no caller-selected status. Metadata correction and lifecycle transition update `updated_at`. Creation and status transition use their matching audit actions. Domain deprecation follows D14. No physical deletion is available.

Authenticated users may read active Domains. Anonymous reads and ordinary/tenant-admin writes are denied. Trusted service/platform administration uses the governed path. Atlas: A-025, A-027, A-035.

### 7.2 `bios_core.domain_nodes`

#### Purpose and scope

Shared governed nodes belonging to exactly one Domain. A Node may represent a category, subcategory, concept, segment, or other governed taxonomy node without storing a speculative type.

#### Fields

| Field | Type | Null | Default | Rule |
|---|---|---:|---|---|
| `id` | `uuid` | No | Generated UUID | Primary key; immutable |
| `domain_id` | `uuid` | No | None | Domain FK; immutable |
| `code` | `text` | No | None | Domain-local immutable stable code |
| `name` | `text` | No | None | 1–200 trimmed characters |
| `description` | `text` | Yes | Null | Null or trimmed, non-empty, 1–1,000 characters |
| `status` | `text` | No | `draft` | `draft`, `active`, or `deprecated` |
| `created_at` | `timestamptz` | No | Transaction time | Immutable |
| `updated_at` | `timestamptz` | No | Transaction time | Database-maintained on metadata correction and lifecycle transition |
| `activated_at` | `timestamptz` | Yes | Null | Required for active/deprecated |
| `deprecated_at` | `timestamptz` | Yes | Null | Required only when deprecated |

#### Constraints and indexes

- Primary key on `id`; FK to Domain does not cascade.
- Unique `(domain_id, code)` and unique `(id, domain_id)` for same-Domain composite references.
- Checks enforce common code/name bounds; description is null or trimmed, non-empty, and at most 1,000 characters; status and lifecycle timestamps are exact.
- Indexes on `(domain_id, status)` and Domain-local administrative name lookup.

#### Governance

`id`, `domain_id`, and `code` are immutable. `name` and `description` may be corrected through trusted administration with `reference.metadata_updated`. Creation always starts draft, accepts no caller-selected status, requires a draft or active Domain, and rejects a deprecated Domain. Metadata correction and lifecycle transition update `updated_at`. Activation/deprecation follow D14. No node-type, multilingual labels, Market link, fixed level, or parent field exists. No physical deletion is available.

Authenticated users read active Nodes whose Domain is active. Anonymous and untrusted/tenant-admin writes are denied. Atlas: A-025, A-027, A-030, A-035.

### 7.3 `bios_core.domain_node_relationships`

#### Purpose and scope

Shared, same-Domain, historical hierarchy episodes forming a polyhierarchical DAG.

#### Fields

| Field | Type | Null | Default | Rule |
|---|---|---:|---|---|
| `id` | `uuid` | No | Generated UUID | Primary key; immutable |
| `domain_id` | `uuid` | No | None | Shared Domain of both endpoints; immutable |
| `subject_node_id` | `uuid` | No | None | Containing Node; immutable |
| `object_node_id` | `uuid` | No | None | Contained Node; immutable |
| `relationship_type` | `text` | No | `contains` | Exact D05 vocabulary |
| `valid_from` | `timestamptz` | No | Transaction time | Episode start; immutable |
| `valid_to` | `timestamptz` | Yes | Null | Episode end |
| `created_at` | `timestamptz` | No | Transaction time | Immutable |
| `updated_at` | `timestamptz` | No | Transaction time | Database-maintained; episode ending updates it with `valid_to` |

#### Constraints and indexes

- Primary key on `id`; Domain FK does not cascade.
- Composite FKs `(subject_node_id, domain_id)` and `(object_node_id, domain_id)` enforce same-Domain endpoints.
- Subject and object must differ.
- Partial unique index rejects duplicate active `(domain_id, subject_node_id, object_node_id, relationship_type)` episodes.
- Active child lookup index by `(domain_id, subject_node_id)` and parent lookup by `(domain_id, object_node_id)`.
- Checks enforce type and `valid_to > valid_from` when ended.
- Hierarchy mutation is serialized per Domain with a transaction-scoped PostgreSQL advisory lock derived deterministically from `domain_id`. The trusted add operation acquires that lock, validates active Domain/endpoints and same-Domain ownership, rejects self-link, recursively checks the active graph for a transitive cycle, rejects a duplicate active edge, inserts the immediately active episode, and emits the audit event atomically. The lock must not serialize unrelated Domains globally. SQL implementation may select the exact safe key derivation only if it is deterministic for `domain_id` and collision-safe for this governed use case.

#### Governance

Episodes have no draft lifecycle. Successful creation is immediately active with null `valid_to` and requires active Domain/endpoints. Endpoints, Domain, relationship type, and start are immutable. Governed ending is the only state change and updates both `valid_to` and `updated_at`. Add/end use existing relationship audit actions atomically. Ended history cannot be erased; later re-add creates a new episode. No physical deletion is available. Atlas: A-025, A-027, A-030, A-035.

## 8. Critical invariants

| Invariant | Migration 003 rule |
|---|---|
| Node ownership | Every Node belongs to exactly one immutable Domain |
| Parent count | Zero, one, or multiple active parents allowed |
| Graph form | Directed acyclic graph; transitive cycles prohibited |
| Direction | Subject `contains` object |
| Cross-Domain edge | Prohibited structurally |
| Active edge endpoints | Domain and both Nodes must be active |
| Node activation | Requires active Domain |
| Domain deprecation | Blocked while any active Node remains; no cascade |
| Node deprecation | Blocked while any active incident edge remains; no cascade |
| Edge ending | Independent explicit operation |
| Code mutation | Prohibited |
| Name/description correction | Trusted, validated, constrained, and metadata-audited |
| Endpoint mutation | Prohibited |
| Relationship history erasure | Prohibited |
| Physical deletion | Unsupported through governed application paths |

## 9. Security and RLS

All three tables are shared platform reference data and contain no `tenant_id`. Migration 003 inherits the established Migration 002 shared-reference security model and introduces no new privilege architecture.

| Actor | Read active | Read draft/deprecated | Insert/update/end | Delete |
|---|---:|---:|---:|---:|
| Anonymous | No | No | No | No |
| Authenticated ordinary user | Yes | No | No | No |
| Tenant administrator | Yes | No | No | No |
| Trusted BIOS service | Purpose-scoped | Purpose-scoped | Governed path | No |
| Exceptional platform administration | Governed | Governed | Governed and audited | No |

Anonymous access is denied. Authenticated users may read active reference projections according to RLS. Ordinary authenticated users cannot mutate. Tenant-admin status confers no global Domain or taxonomy authority. Trusted BIOS service operations follow the established server-side shared-reference administration pattern; exceptional platform administration follows the existing governed privileged path.

Privileged functions must not be executable through `PUBLIC`. Any security-definer function must use the repository’s established fixed `search_path`, least-privilege grants, qualified object references, and security-hardening pattern. Service-role bypass remains server-side and does not itself provide business authorization. Trusted operations validate dependencies, apply the D06 per-Domain serialization/cycle protections, and write operation-specific audit events atomically. Migration 003 does not modify Migration 001 or Migration 002 authorization architecture.

## 10. Audit obligations

Migration 003 reuses existing actions and adds only D13 resource types.

| Operation | Action | Resource |
|---|---|---|
| Create Domain | `reference.created` | `domain` |
| Create Node | `reference.created` | `domain_node` |
| Change Domain/Node status | `reference.status_changed` | Corresponding base resource |
| Correct Domain/Node metadata | `reference.metadata_updated` | Corresponding base resource |
| Add hierarchy edge | `reference.relationship_added` | `domain_node_relationship` |
| End hierarchy edge | `reference.relationship_ended` | `domain_node_relationship` |
| Physical deletion | Not supported | None |

Safe metadata inherits DB-002’s JSON-object and 8,192-byte limits. Metadata correction identifies approved fields changed and reason where supplied, without unrestricted row snapshots. Edge events may identify endpoint and Domain UUIDs, type, and validity time.

## 11. Seed and multilingual governance

The schema migration creates zero business Domains or Nodes. Named category examples have no canonical seed status. Reference taxonomy seeds require reviewed source, stable codes, deterministic application, ownership, and version/change governance outside this migration. Test fixtures are synthetic and isolated.

Migration 003 stores one canonical governed name per Domain/Node. It creates no localized label field/table or JSONB translation. Migration 002 Language IDs remain available for a later additive label model.

## 12. Atlas control

| Assumption | Migration 003 relationship | Validation effect |
|---|---|---|
| A-025 | Common Domain/Node abstraction is represented | None; cross-category usefulness remains unvalidated |
| A-027 | Minimal hierarchy can support candidate common ontology work | None; no ontology efficacy is proved |
| A-030 | Relationship episodes provide reversible minimal history | None; richer temporal requirements remain open |
| A-031 | Future Entity–Domain membership can target stable Nodes | None |
| A-035 | Domain Packs may later target these references | None; no pack is implemented |
| A-039 | Future intelligence-chain objects may link governed categories | None |

## 13. Acceptance test plan

All database tests belong in `supabase/tests/`; this document writes none.

1. Clean reset succeeds through Migrations 001–003.
2. Exactly the three approved Migration 003 tables exist.
3. No pack, attribute/EAV, Entity, Evidence, Intelligence, agent, connector, vector, or advanced ontology table exists.
4. No named category is structurally required or seeded by migration.
5. Domain UUID/code/name/status constraints work.
6. Domain description accepts null and valid trimmed 1–1,000-character values but rejects empty, whitespace-only, untrimmed, and over-limit values.
7. Node description follows the same null/trim/non-empty/maximum rules.
8. Duplicate global Domain codes are rejected.
9. Every Node requires a valid Domain.
10. Duplicate Node codes within one Domain are rejected.
11. The same Node code is allowed in different Domains.
12. No node-type, fixed-level, or parent column exists.
13. Domain creation always starts draft and rejects caller-selected active/deprecated status.
14. Node creation always starts draft and rejects caller-selected active/deprecated status.
15. Node creation under a deprecated Domain is rejected; creation under draft/active Domain succeeds when otherwise authorized.
16. Only `contains` relationship type is accepted and subject/object direction matches the documented hierarchy.
17. Self-links are rejected.
18. Direct and transitive cycles are rejected.
19. Concurrent hierarchy additions cannot create a cycle under the per-Domain transaction advisory lock.
20. Hierarchy mutations in unrelated Domains are not globally serialized.
21. Zero, one, and multiple parents are permitted without cycles.
22. Cross-Domain edges are rejected structurally.
23. Duplicate active hierarchy episodes are rejected.
24. A created hierarchy episode is immediately active with null `valid_to`; caller-selected scheduled activation is rejected.
25. Relationship creation requires an active Domain and active subject/object Nodes.
26. Ending an edge updates `valid_to` and `updated_at`, retains history, and permits a later new episode.
27. Invalid lifecycle status and transition are rejected.
28. Activating a Node under a non-active Domain is rejected.
29. Deprecating a Domain with active Nodes is rejected.
30. Deprecating a Node with active incident edges is rejected.
31. Ending an edge does not cascade Node status.
32. Domain metadata correction changes database-maintained `updated_at`.
33. Domain lifecycle transition changes database-maintained `updated_at`.
34. Node metadata correction changes database-maintained `updated_at`.
35. Node lifecycle transition changes database-maintained `updated_at`.
36. Identity fields and relationship endpoints/type/start are immutable.
37. Approved metadata correction succeeds and emits `reference.metadata_updated`.
38. Metadata correction cannot mutate identity.
39. Physical deletion is denied through all governed actor paths.
40. Authenticated users read active references and anonymous reads are denied.
41. Ordinary authenticated-user mutation is denied.
42. Tenant-admin receives no global Domain/taxonomy mutation authority.
43. Privileged functions are not executable through `PUBLIC`.
44. Security-definer functions use the established fixed `search_path` and least-privilege hardening pattern.
45. Trusted service and exceptional administration mutation succeed only through their established governed paths.
46. Required reference audit actions are atomic with their governed changes.
47. New Domain resource types are accepted; unknown resource types are rejected.
48. No Market, P1/P2, Client, Workspace, or multilingual-label coupling is required.
49. Production migration creates no Domain or Node business rows.
50. Migration 001’s maintained 49-test regression suite remains green.
51. The full Migration 002 suite remains green.
52. Migration 003 structural assertions are scoped to Migration 003-owned objects.
53. Catalog/structural replay is deterministic.

## 14. Regression-testing principle

Later canonical migrations may add tables or columns without causing earlier tests to fail merely because those tests used global structural counts. Regression suites preserve the earlier migration’s security and behavioral meaning while scoping structural assertions to objects owned by that migration.

DB-004 identifies no actual forward-compatibility defect requiring changes to Migration 001 or Migration 002 tests. No earlier test or migration modification is authorized by this document.

## 15. Migration safety and compatibility

- **Forward migration:** create the three tables and supporting objects, add audit resource codes, enable RLS, and fail on incompatible existing objects.
- **Local reset:** guarded local reset rebuilds Migrations 001–003 from source control with safe fixtures.
- **Immutability:** after merge/shared application, Migration 003 is immutable; corrections use later forward migrations.
- **Evolution:** types, localized labels, cross-Domain mappings, packs, tenant customizations, and Market relevance are additive future work requiring governance.
- **History:** endpoints and ended relationship episodes are never overwritten or erased.
- **Seeds:** reference seed application is deterministic, reviewed, and separate from commercial priority/Atlas validation.
- **Recovery:** current local recovery is reset/replay; shared/production use requires tested backup/restore and forward recovery.
- **Migration 001 compatibility:** no tenancy, identity, authorization, RLS, history, role, or audit behavior is weakened; audit resources extend additively.
- **Migration 002 compatibility:** Geography, Market, group, and Language structures remain unchanged; existing reference actions are reused.
- **Future Entity/Evidence compatibility:** later tables can reference `domains.id` and `domain_nodes.id` without changing Domain identity or hierarchy. Evidence-specific provenance and temporal semantics remain outside Migration 003.

## 16. SQL-blocker review

The specification defines every required bound, regex, null/empty rule, creation status, lifecycle transition, relationship activation state, hierarchy direction, parent cardinality, per-Domain cycle/concurrency rule, cross-Domain constraint, episode time rule, status dependency, audit action/resource, authorization path, seed rule, deletion rule, and immutability rule. `updated_at` behavior and privileged-function security inheritance are also deterministic.

M003-D01 through M003-D14 have been approved by the BIOS Executive Office. No unresolved SQL-blocking architecture decision remains, and SQL implementation may proceed strictly within DB-004. If implementation discovers a new material ambiguity, work must stop and the ambiguity must be reported rather than resolved by inventing architecture.

## 17. Readiness checklist

### Architecture and scope

- [x] Exactly three authorized Migration 003 tables are specified.
- [x] Domain and Domain Node are distinct; no category-specific structure exists.
- [x] All explicit exclusions remain outside scope.

### Domain and Node model

- [x] Identity, local/global code uniqueness, bounds, metadata correction, and lifecycle are deterministic.
- [x] Every Node belongs to exactly one Domain.
- [x] Node type and multilingual labels are deliberately deferred.
- [x] M003-D01–D04 and D10 approved.

### Hierarchy, polyhierarchy, and cross-Domain rules

- [x] One `contains` direction and episode model are exact.
- [x] DAG polyhierarchy permits zero/multiple parents and rejects cycles.
- [x] Composite ownership prevents cross-Domain edges.
- [x] M003-D05–D07 and D09 approved.

### Lifecycle and temporal history

- [x] Lifecycle, activation/deprecation dependencies, no-cascade behavior, and history are explicit.
- [x] M003-D08 and D14 approved.

### Security, RLS, audit, and seed governance

- [x] Shared scope has no nullable tenant ownership.
- [x] Anonymous/untrusted writes and physical deletion are denied.
- [x] Existing audit actions are reused with exactly three new resource types.
- [x] Migration creates zero business seed rows.
- [x] M003-D12 and D13 approved.
- [ ] SQL RLS/security implementation receives review.

### Atlas, testing, and compatibility

- [x] A-025, A-027, A-030, A-031, A-035, and A-039 remain unvalidated.
- [x] Fifty-three acceptance requirements are defined.
- [x] Migrations 001 and 002 are unchanged and regression-protected.
- [x] Future Entity/Evidence references remain additive.
- [ ] Executable pgTAP/RLS tests and clean replay pass.

### Market coupling

- [x] No Market–Domain association or priority is created.
- [x] M003-D11 approved.

## 18. Readiness recommendation

**READY FOR SQL IMPLEMENTATION**

DB-004 is approved and deterministic enough for SQL implementation strictly within its defined scope. Downstream gates remain SQL security review, executable pgTAP/RLS testing, Migration 001 and 002 regression suites passing, clean local replay, and normal repository/pull-request review.

## 19. Version history

| Version | Date | Change |
|---|---|---|
| 1.0 | 2026-08-03 | Initial canonical implementation design for Migration 003 Domain and Category foundation |
