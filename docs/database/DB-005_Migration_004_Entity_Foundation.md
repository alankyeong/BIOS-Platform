# DB-005 — BIOS Migration 004: Entity Foundation

| Field | Value |
|---|---|
| Document ID | DB-005 |
| Title | BIOS Migration 004 — Entity Foundation |
| Version | 1.3 |
| Status | Canonical |
| Effective date | 2026-08-04 |
| Owner | BIOS Executive Office — Data Architecture and Engineering |
| Dependencies | ADR-001, ARCH-001, ARCH-002, DB-001, DB-002 v1.1, DB-003 v1.1, DB-004 v1.0, ENG-001, CANON-001 |
| Supersedes | DB-005 v1.2 |
| Review cadence | Before SQL implementation, before merge, and after relevant Atlas resolution |
| Related documents | [ENG-001](../engineering/ENG-001_BIOS_Engineering_Handbook.md), [CANON-001](../engineering/CANON-001_Repository_and_Engineering_Standards.md), [ADR-001](../decisions/ADR-001_PostgreSQL_and_Supabase.md), [ARCH-001](../architecture/ARCH-001_Canonical_Platform_Architecture.md), [ARCH-002](../architecture/ARCH-002_Architecture_Assumption_Register.md), [DB-001](DB-001_Canonical_Data_Model.md), [DB-002](DB-002_Migration_001_Core_Platform_Foundation.md), [DB-003](DB-003_Migration_002_Geography_Market_and_Language_Foundation.md), [DB-004](DB-004_Migration_003_Domain_and_Category_Foundation.md) |

## 1. Purpose

DB-005 defines the smallest coherent fourth PostgreSQL/Supabase migration for stable Entity identity. It allows later Sources, Evidence, Signals, Findings, and Decision Contexts to refer to durable real-world or analytical identities without making identity dependent on a Market, Domain, category, source, or tenant-specific schema fork.

This is an implementation design specification. It contains no SQL and authorizes no implementation until the Executive Office approves the decisions in Section 16.

## 2. Canonical principles

1. An Entity is stable identity, not a name, claim, observation, or taxonomy node.
2. Entity type is governed data, not an application enum or table-per-type design.
3. Shared and tenant-private identity are explicit scopes with different authority and visibility.
4. Tenant-private identity belongs to exactly one Tenant and cannot be promoted to shared in Migration 004.
5. Entity identity is independent of Markets and Domains; those are future many-to-many claims.
6. Names and aliases aid identification but are neither globally unique nor sufficient proof of identity.
7. Merge is an auditable identity decision, not destructive reassignment or deletion.
8. Audit proves governance activity; it does not replace evidentiary provenance.
9. Category, source, market, language, and commercial examples never become fixed schema.
10. Atlas assumptions A-029, A-031, A-041, and A-042 remain unvalidated merely because the schema can represent their candidate model.

## 3. Object assessment and exact migration boundary

| Provisional object | Classification | Dependency reasoning |
|---|---|---|
| `bios_knowledge.entity_types` | REQUIRED IN MIGRATION 004 | `entities` requires a governed type FK; a hard-coded application enum would violate ARCH-001 and DB-001. |
| `bios_knowledge.entities` | REQUIRED IN MIGRATION 004 | This is the stable identity boundary and the purpose of Migration 004. |
| `bios_knowledge.entity_aliases` | REQUIRED IN MIGRATION 004 | Cross-language, cross-market, and source variation cannot safely overload canonical name; aliases are required for minimal human-governed identity resolution. |
| `bios_knowledge.entity_relationships` | DEFER | A relationship is a claim requiring governed type, direction, scope compatibility, temporal meaning, and evidence/provenance. Evidence infrastructure does not yet exist. |
| `bios_knowledge.entity_market_presence` | DEFER | Market presence is an evidence-backed temporal claim, not Entity identity. Migration 002 Markets remain available for a later additive link. |
| `bios_knowledge.entity_domain_memberships` | DEFER | Domain classification is an evidence-backed claim and may target a Domain or Domain Node. Migration 003 references remain available for a later additive link. |

Migration 004 may create exactly three tables:

1. `bios_knowledge.entity_types`
2. `bios_knowledge.entities`
3. `bios_knowledge.entity_aliases`

Supporting objects are limited to required constraints, indexes, foreign keys, RLS policies, grants, narrow trusted functions, lifecycle/immutability/timestamp protections, additive audit vocabulary, and narrow concurrency controls. No extension is authorized.

## 4. Explicit exclusions

Migration 004 must not create Entity relationships, relationship-type registries, Market presence, Domain membership, Sources, source documents, Evidence, evidence representations, provenance edges, Signals, Patterns, Findings, Decision Contexts, Recommendations, Decisions, packs, attributes/EAV, ontology reasoning, connectors, agents, vectors, promotion workflows, Client, or Workspace structures.

It must not create placeholder Source/Evidence identifiers, unenforced polymorphic references, automatic matching, automatic merge, fuzzy-search infrastructure, or entity-type-specific tables.

## 5. Common conventions

| Concern | Migration 004 rule |
|---|---|
| Primary key | BIOS-owned generated UUID with no business meaning |
| Stable code | 3–64 lowercase characters matching `^[a-z][a-z0-9_]{1,62}[a-z0-9]$` |
| Display name | Trimmed text, 1–200 characters |
| Description | Null or trimmed, non-empty text of at most 1,000 characters |
| Time | `timestamptz`; database-set `created_at`; database-maintained `updated_at` |
| Shared scope | Explicit `knowledge_scope = shared`; platform authority only |
| Tenant scope | Explicit `knowledge_scope = tenant` plus non-null `tenant_id` |
| Physical deletion | Unsupported through governed application paths |
| Mutation | Narrow governed operations; no direct untrusted table mutation |
| Provenance | Deferred claims remain absent; audit records governance operations only |

## 6. Entity-type governance

`entity_types` is a shared platform registry. It defines broad identity classes required to govern Entity creation; it is not a commercial ontology, Domain taxonomy, inheritance tree, or validation-rule engine.

Entity types use immutable UUID and globally unique immutable code. Name and description are correctable. Lifecycle is `draft → active → deprecated`, with deprecated terminal. Creation always starts draft. Entity creation requires an active type. A type cannot be deprecated while any candidate or active Entity references it. Type changes do not cascade.

Migration 004 creates zero production type rows. No initial vocabulary is technically required because types can be created through the governed platform path before Entities. Tests use synthetic types. Any later infrastructure seed requires separately reviewed stable codes and deterministic seed governance. Named commercial types are business reference data, not migration infrastructure.

Authenticated users may read active types. Anonymous access and tenant-admin/platform-untrusted mutation are denied. Trusted platform administration creates, corrects, activates, and deprecates types with audit.

## 7. Table specifications

### 7.1 `bios_knowledge.entity_types`

| Field | Null | Rule |
|---|---:|---|
| `id` | No | Generated UUID primary key; immutable |
| `code` | No | Globally unique immutable stable code using Section 5 |
| `name` | No | Trimmed 1–200 characters |
| `description` | Yes | Section 5 description rule |
| `status` | No | `draft`, `active`, or `deprecated`; default `draft` |
| `created_at` | No | Database-set; immutable |
| `updated_at` | No | Database-maintained |
| `activated_at` | Yes | Required for active/deprecated |
| `deprecated_at` | Yes | Required only for deprecated |

Required indexes cover code uniqueness, status, and administrative name lookup. No hierarchy, parent, schema manifest, or type-specific attributes are authorized.

### 7.2 `bios_knowledge.entities`

| Field | Null | Rule |
|---|---:|---|
| `id` | No | Generated UUID primary key; immutable stable identity |
| `entity_type_id` | No | Immutable FK to active governed Entity Type at creation/activation |
| `knowledge_scope` | No | Exactly `shared` or `tenant`; immutable |
| `tenant_id` | Conditional | Null exactly when scope is shared; non-null exactly when scope is tenant; immutable FK |
| `canonical_name` | No | Trimmed 1–200 characters; correctable; never identity or unique |
| `description` | Yes | Section 5 description rule; correctable |
| `status` | No | `candidate`, `active`, `merged`, or `archived`; default `candidate` |
| `merge_target_entity_id` | Conditional | Required exactly when merged; null otherwise; immutable while merged |
| `created_at` | No | Database-set; immutable |
| `updated_at` | No | Database-maintained on every governed mutation |
| `activated_at` | Yes | Required after first activation; retained after merge/archive |
| `merged_at` | Yes | Required exactly while merged |
| `archived_at` | Yes | Required exactly while archived |

Canonical name is not globally, tenant-locally, type-locally, or scope-locally unique. Distinct real-world Entities may share a name. Duplicate detection is a governed review concern, not a uniqueness constraint.

Entity identity is Market-independent and Domain-independent. Migration 004 stores no Market ID, Domain ID, Domain-node ID, country code, priority, category, or named vertical on the Entity row.

Immutable fields are `id`, `entity_type_id`, `knowledge_scope`, `tenant_id`, and `created_at`. Correctable metadata is `canonical_name` and `description`. Type correction requires a separately approved future identity-reclassification workflow; ordinary metadata correction cannot change type.

Creation always produces `candidate`. Shared candidates require platform authority. Tenant-private candidates require an active authorized tenant administrator acting only for that Tenant. Activation is separate and audited. Ordinary authenticated users cannot create or mutate Entities.

### 7.3 `bios_knowledge.entity_aliases`

| Field | Null | Rule |
|---|---:|---|
| `id` | No | Generated UUID primary key; immutable |
| `entity_id` | No | Immutable FK; alias inherits Entity scope and Tenant ownership |
| `alias_text` | No | Trimmed 1–500 characters |
| `alias_type` | No | Bounded vocabulary: `name`, `abbreviation`, `former_name`, `transliteration`, `trade_name`, `other` |
| `language_id` | Yes | FK to a Migration 002 Language that must be active when the alias is created or activated |
| `market_id` | Yes | FK to a Migration 002 Market that must be active when the alias is created or activated; context only, not Entity presence |
| `confidence` | Yes | Numeric from 0 through 1 inclusive; null means not scored, never zero-by-default |
| `status` | No | `candidate`, `active`, or `superseded`; default `candidate` |
| `valid_from` | Yes | Optional real-world name applicability start |
| `valid_to` | Yes | Null or later than `valid_from`; optional applicability end |
| `created_at` | No | Database-set; immutable |
| `updated_at` | No | Database-maintained |
| `activated_at` | Yes | Required for active/superseded after activation |
| `superseded_at` | Yes | Required exactly when superseded |

No persisted normalized key is authorized in Migration 004. Unicode normalization, punctuation, script, locale, and fuzzy-match behavior require representative multilingual validation under A-028/A-031. Administrative indexes may support exact/case-folded lookup without making the result identity or match proof.

An alias belongs to one Entity and cannot be moved. Scope and Tenant are derived through that FK and are not duplicated ambiguously. Optional Language and Market describe alias context only. Both references must be active when the alias is created or activated. Later deprecation of the referenced Language or Market does not delete or supersede the alias, invalidate its historical context, or cascade its lifecycle. Source-document linkage, extraction method, and evidentiary provenance are deferred until Source Documents/Evidence exist; no placeholder is created.

Active duplicate aliases for the same Entity, type, language context, Market context, text, and overlapping applicability are rejected. For duplicate detection, two null Language contexts are the same unspecified-Language context, two null Market contexts are the same unspecified-Market context, null `valid_from` means unbounded past, and null `valid_to` means unbounded future. Two otherwise identical active alias episodes may not have overlapping applicability intervals. The same text may legitimately identify different Entities. DB-005 does not prescribe a particular PostgreSQL constraint or index implementation. Supersession retains the row; correction of identity-significant alias text/context creates a new candidate alias and supersedes the old one rather than rewriting history.

## 8. Lifecycle and merge semantics

### 8.1 Entity lifecycle

Permitted transitions are:

```text
candidate → active → archived
candidate → archived
active → merged
merged → active       (governed unmerge)
```

No other transition is permitted. Archived is terminal. A merged Entity remains historically addressable by its UUID and is not deleted.

Activation requires an active Entity Type. Tenant-private activation requires an active Tenant and authorized tenant administration. Shared activation requires platform administration. Archival never cascades to aliases or future references.

### 8.2 Merge target

A merge target must:

- exist and be active;
- differ from the source;
- have the same immutable Entity Type;
- have the same `knowledge_scope`;
- for tenant scope, have the same non-null `tenant_id`;
- not itself be merged or archived.

Merge chains are prohibited. A merged source points directly to one active canonical target. Concurrent merge operations are serialized over both Entity UUIDs in deterministic UUID order to prevent opposing merges and cycles.

Merge does not reassign, copy, broaden, or delete aliases. It does not rewrite future relationships, Market presence, Domain memberships, Evidence, or intelligence. Future consumers must preserve the cited Entity UUID and may resolve the current merge target explicitly. Automatic reassignment is prohibited.

Unmerge is permitted in Migration 004 only through exceptional platform administration for shared Entities or an equally governed tenant-private administrative path. It changes the source from merged to active, clears target/time consistently, and audits the reversal. Unmerge requires the source Entity's referenced Entity Type to be active at the time of unmerge; a deprecated Entity Type must never regain an active Entity through unmerge. It does not undo external operations, because Migration 004 creates none.

Migration 004 authorizes unmerge only under the Entity dependency model existing through Migration 004. Any later migration introducing Entity-dependent relationships, Market presence, Domain membership, Sources/Evidence, provenance, intelligence, or decision structures must explicitly revalidate, constrain, or supersede this unmerge contract before that migration is admitted. DB-005 does not define those future dependency behaviors.

### 8.3 Historical/current Entity UUID resolution

Migration 004 provides one narrow read-only identity resolver. Its sole business input is `entity_id` UUID. It accepts no caller-supplied Tenant, profile, scope, role, membership, or authorization value. Authorization is derived internally.

For an authorized active Entity, it returns one row containing only `requested_entity_id` equal to the input UUID and `resolved_entity_id` equal to that same UUID. For an authorized merged Entity, it returns only the requested historical UUID and its directly referenced active merge-target UUID. Resolution is one hop because merge chains are prohibited; it does not recursively chase arbitrary chains.

Candidate, archived, nonexistent, and unauthorized tenant-private UUIDs return no row. Inactive or missing tenant membership also returns no row. These outcomes are deliberately indistinguishable to prevent Entity-existence and cross-tenant disclosure. Normal database or system failures remain errors.

The resolver is not an Entity search API, governance-record reader, alias lookup, Evidence API, provenance API, or tenant-discovery API. It returns no name, type, status, scope, Tenant, merge time, alias, description, audit metadata, or other governance field.

## 9. Alias lifecycle

Permitted transitions are `candidate → active → superseded` and `candidate → superseded`. Superseded is terminal. Alias activation requires its Entity to be active. A merged or archived Entity accepts no new alias and no alias activation. Entity merge/archive does not cascade alias state.

Alias text or context correction creates a new candidate row and explicitly supersedes the prior row. Confidence may be corrected through a governed review before supersession, with audit. Audit is not evidence for the alias claim.

## 10. Shared and tenant-private security model

Migration 004 selects one mixed table with an explicit scope discriminator because the Entity identity contract and lifecycle are identical across scopes. Safety depends on database-enforced scope/ownership consistency, not nullable-tenant inference.

Required invariants:

- `shared` means `tenant_id` is null and only platform-governed workflows may create/mutate;
- `tenant` means `tenant_id` is non-null and references exactly one Tenant;
- scope and Tenant cannot change after creation;
- tenant-private Entities and aliases are visible only with an active membership in their Tenant;
- no cross-tenant read, link, merge, alias move, or existence disclosure is permitted;
- tenant-private identity cannot be promoted to shared or copied automatically;
- shared Entity reads do not reveal tenant-private aliases or existence;
- mixed-scope merge is prohibited.

RLS is mandatory on `entities` and `entity_aliases`. `entity_types` uses the shared-reference read pattern. Anonymous access is denied to all three tables. Authenticated users may read active shared Entity Types, active shared Entities, and their active aliases. Active tenant members may read active Entities/aliases in their Tenant. Tenant administrators may additionally read candidate, merged, archived, and superseded tenant-owned records required for governance.

A merged Entity UUID remains resolvable through the narrow contract in Section 8.3 so future Evidence and provenance records can retain the originally cited UUID and determine its current direct merge target. This contract does not grant broad authenticated visibility into merged governance records, reveal cross-tenant identity, or define a future Evidence API.

For shared Entities, resolution requires an authenticated caller whose BIOS Profile is active; no Tenant membership is required. For tenant-private Entities, resolution requires an authenticated caller whose BIOS Profile is active and who has an active membership in the owning Tenant. Tenant-admin role is not required solely for resolution, so an ordinary active member may resolve identity within their own Tenant. This narrow capability grants no candidate, merged, or archived governance-record read, tenant administration, or mutation authority. Missing, suspended, ended, or otherwise inactive membership denies resolution immediately. Cross-tenant resolution is prohibited.

The resolver is a narrowly hardened SECURITY DEFINER function with fixed empty `search_path`, fully qualified object references, and internally derived authorization. It uses `auth.uid()` to derive caller identity and re-derives the active BIOS Profile and any required active Tenant membership from Migration 001 structures. It accepts no caller-supplied authorization context. `PUBLIC` execution is revoked, anonymous execution is denied, and execution is granted explicitly to `authenticated`; an established trusted BIOS service/platform path may also use it where already authorized. It may bypass ordinary row visibility only to evaluate and return the two-UUID mapping in Section 8.3.

The resolver is read-only and creates no BIOS governance audit event. Future operational or access telemetry outside the Migration 004 governance-audit contract is not prohibited.

Ordinary authenticated users have no mutation authority. Active tenant administrators may use narrow governed functions for tenant-private candidate creation, metadata correction, alias governance, activation, archive, merge, and unmerge only within their own Tenant. Tenant-admin status confers no shared or cross-tenant authority. Shared mutation is restricted to trusted BIOS service/exceptional platform administration.

Any SECURITY DEFINER function uses fixed empty `search_path`, fully qualified objects, positive actor/membership/role/status validation, least-privilege grants, and atomic audit. `PUBLIC` execution is revoked. Service-role possession does not replace business authorization; operations require the established named server-side path and safe actor identifier.

## 11. Audit obligations

Reuse existing actions where semantics match:

- `reference.created`
- `reference.status_changed`
- `reference.metadata_updated`

Add exactly two Entity-specific actions because merge and reversal are identity decisions, not ordinary status changes:

- `entity.merged`
- `entity.unmerged`

Add exactly these resource types:

- `entity_type`
- `entity`
- `entity_alias`

Creation, activation/archive, type lifecycle, alias lifecycle, metadata correction, merge, and unmerge write one deterministic successful audit event atomically with the governed change. Failed operations leave neither governed state nor a success event. Merge metadata includes source Entity, target Entity, scope, Tenant when applicable, reason, and correlation ID; it contains no unrestricted row snapshots. Metadata remains a JSON object within DB-002's 8,192-byte serialized bound.

Physical deletion is unsupported and has no action. Audit events record governance activity and are not Source/Evidence provenance.

## 12. Deferred relationship and claim objects

### 12.1 Entity relationships

Deferred until a governed relationship-type registry, evidence/source dependency, direction/symmetry rules, scope inheritance, temporal validity, and correction model are approved. Migration 004 neither stores arbitrary relationship codes nor treats merge as an Entity relationship.

### 12.2 Market presence

Deferred until Evidence can support the many-to-many temporal claim. Entity identity remains independent of Market. Alias `market_id` is only name context and must never be queried as proof of presence.

### 12.3 Domain membership

Deferred until Evidence can support classification and BIOS decides whether claims target Domain, Domain Node, or both. Entity identity remains category-neutral. Alias rows contain no Domain context.

## 13. Provenance limitation

Migration 004 can safely persist governed identity proposals, review state, canonical labels, contextual aliases, and auditable merge decisions. It cannot establish that an Entity exists, operates in a Market, belongs to a category, has a relationship, or is supported by a particular source.

Source-document and Evidence linkage will be additive. No arbitrary UUID, JSON reference, text locator, or audit metadata substitutes for a future enforced provenance relationship.

## 14. Atlas control

| Assumption | Migration 004 relationship | Validation effect |
|---|---|---|
| A-028 | Optional Language context is representable; normalization remains deferred | None; multilingual resolution remains unvalidated |
| A-029 | Explicit shared/private scope and RLS are represented | None; production mixed-scope safety still requires threat-model evidence |
| A-030 | Minimal lifecycle/supersession time is represented | None; richer temporal requirements remain open |
| A-031 | Candidate cross-context identity registry is represented | None; representative entity-resolution validation remains required |
| A-035 | Future Domain links can target stable Entities | None; no pack or link is implemented |
| A-041 | Tenant is used as the private ownership boundary | None beyond the accepted Migration 001 security rule |
| A-042 | Direct tenant-to-shared promotion remains prohibited | Risk is contained; promotion remains disabled |

## 15. Acceptance-test plan

All executable tests belong in `supabase/tests/`; this document writes none.

1. Clean reset succeeds through Migrations 001–004.
2. Exactly the three approved Migration 004 tables exist.
3. No deferred Entity relationship, Market-presence, Domain-membership, Source, Evidence, intelligence, pack, agent, connector, vector, Client, or Workspace object is introduced.
4. Migration 004 creates zero production Entity Type, Entity, or alias rows.
5. Entity Type UUID, code, name, description, status, and timestamp constraints work.
6. Entity Type code uses the common regex and is globally unique and immutable.
7. Entity Type creation always starts draft.
8. Entity Type lifecycle permits only draft-to-active-to-deprecated.
9. Entity Type deprecation is blocked while candidate/active Entities reference it.
10. Authenticated users read active Entity Types; anonymous reads and untrusted writes are denied.
11. Every Entity requires a valid governed Entity Type.
12. Entity creation requires an active Entity Type.
13. Entity UUID is generated and immutable.
14. Canonical name is trimmed, bounded, correctable, and not unique.
15. Entity description follows null/trim/non-empty/maximum rules.
16. Entity creation always starts candidate and accepts no caller-selected later status.
17. Entity scope accepts exactly shared or tenant.
18. Shared scope requires null Tenant and tenant scope requires non-null valid Tenant.
19. Entity scope and Tenant ownership are immutable.
20. Entity Type is immutable through ordinary Entity governance.
21. Entity identity contains no Market or Domain dependency.
22. Candidate-to-active transition succeeds when dependencies and authority are valid.
23. Candidate-to-archived and active-to-archived transitions succeed.
24. Invalid transitions and archived reactivation are rejected.
25. Lifecycle transitions maintain required timestamps and `updated_at`.
26. Shared Entity creation/mutation requires platform authority.
27. Tenant-private creation/mutation requires an active membership and tenant-admin role in the same Tenant.
28. Ordinary active tenant members cannot mutate Entity identity records.
29. Tenant admin cannot create or mutate shared Entities.
30. Tenant admin cannot select an arbitrary Tenant or act across Tenants.
31. Missing, suspended, or revoked membership denies tenant-private access immediately.
32. Same-tenant authorized reads succeed.
33. Cross-tenant Entity reads are denied without existence disclosure.
34. Anonymous Entity reads are denied.
35. Authenticated users read active shared Entities only.
36. Entity metadata correction updates only canonical name/description, maintains `updated_at`, and audits changed fields.
37. Physical deletion is denied through ordinary, tenant-admin, and service governed paths.
38. Merge rejects self-target.
39. Merge requires an active target.
40. Merge requires identical Entity Type.
41. Merge requires identical scope and, for private Entities, identical Tenant.
42. Merge rejects a merged or archived target and prevents merge chains.
43. Opposing/concurrent merges cannot create a cycle under deterministic locking.
44. Successful merge sets status, target, time, and audit atomically.
45. Merged source remains readable by authorized historical/governance paths.
46. A merged Entity UUID resolves through a narrow scope-compatible path without broad merged-record visibility or cross-tenant disclosure.
47. Merge does not move, copy, delete, or broaden aliases.
48. Unmerge restores the source to active, clears merge state consistently, and audits atomically.
49. Unmerge requires the source Entity Type to be active and rejects activation through a deprecated Type.
50. Unmerge authority is scope-appropriate and cross-tenant safe.
51. Alias requires a valid Entity and inherits its scope/visibility.
52. Alias text, type vocabulary, confidence, validity, status, and timestamp constraints work.
53. Alias creation starts candidate.
54. Alias activation requires an active Entity.
55. Alias activation/supersession lifecycle is exact; superseded is terminal.
56. Alias identity/context fields cannot be rewritten; correction creates a new candidate and supersedes history.
57. Active duplicate alias episodes treat null Language/Market contexts as equal and null interval bounds as unbounded, reject overlapping identical context within one Entity, and allow the same text across different Entities.
58. Optional Language and Market FKs require active governed references when the alias is created or activated.
59. Later Language or Market deprecation preserves the alias, its historical context, and its independent lifecycle without cascade.
60. Alias Market context does not create Entity Market presence.
61. Tenant-private alias RLS follows the owning Entity and prevents cross-tenant disclosure.
62. Shared alias reads require an active shared Entity and active alias.
63. Entity merge/archive never cascades alias lifecycle.
64. Required creation, status, metadata, merge, and unmerge audit actions are deterministic and atomic.
65. New resource/action codes are accepted and unknown codes remain rejected.
66. Privileged functions are not executable by `PUBLIC`.
67. SECURITY DEFINER functions use fixed search path, qualified objects, positive authorization, and least-privilege grants.
68. Audit metadata remains a bounded JSON object and does not contain unrestricted snapshots.
69. No Source/Evidence placeholder or unenforced polymorphic reference exists.
70. No tenant-private-to-shared promotion path exists.
71. Migration 001, Migration 002, and Migration 003 regression suites remain green.
72. Migration 004 structural assertions are scoped to Migration 004-owned objects.
73. Clean replay produces deterministic catalog, constraint, policy, and function structure.
74. An authenticated caller with an active BIOS Profile resolves an active shared Entity UUID to itself without Tenant membership.
75. An authenticated caller with an active BIOS Profile resolves a merged shared Entity UUID to its direct active merge target in one hop.
76. Resolver availability does not grant an ordinary authenticated caller broad read access to the merged shared Entity governance row.
77. An ordinary authenticated active member resolves a merged tenant-private Entity UUID within the owning Tenant without tenant-admin role.
78. A caller with membership only in another Tenant receives no resolver row for a tenant-private Entity.
79. Missing, suspended, ended, or otherwise inactive owning-Tenant membership returns no resolver row.
80. Anonymous callers cannot execute the resolver.
81. A candidate Entity UUID returns no resolver row.
82. An archived Entity UUID returns no resolver row.
83. A nonexistent Entity UUID returns no resolver row.
84. The resolver returns exactly `requested_entity_id` and `resolved_entity_id` and no governance fields.
85. `PUBLIC` cannot execute the resolver and `authenticated` receives the explicit narrow execution grant.
86. The resolver accepts only one business input, `entity_id` UUID, and exposes no caller-supplied Tenant, Profile, scope, role, membership, or authorization parameter.
87. Resolver responses make nonexistent and unauthorized tenant-private UUIDs indistinguishable and disclose no cross-tenant existence.
88. Successful resolver calls create no BIOS governance audit event.

## 16. Approved implementation decisions

M004-D01 through M004-D16 were approved by the BIOS Executive Office on 2026-08-04.

### M004-D01 — Exact table boundary — APPROVED

- **Decision:** Whether Migration 004 contains only Entity Types, Entities, and aliases.
- **Recommended option:** Approve exactly the three tables in Section 3; defer all claims/relationships.
- **Alternatives considered:** Entities alone; include all six DB-001 Entity tables.
- **Reason:** Types and aliases are required for coherent governed identity; the other objects require Evidence/provenance semantics.
- **Coupling/reversibility:** Low coupling and additive replacement path; highly reversible.

### M004-D02 — Entity Type registry and seed — APPROVED

- **Decision:** Govern type through a table and whether Migration 004 seeds types.
- **Recommended option:** Shared registry with no production seed.
- **Alternatives considered:** Application enum; hard-coded exhaustive ontology; infrastructure seed.
- **Reason:** A registry satisfies DB-001 without asserting an unvalidated commercial ontology; governed post-migration creation is sufficient.
- **Coupling/reversibility:** Registry is stable; vocabulary remains additive and replaceable.

### M004-D03 — Shared/private storage model — APPROVED

- **Decision:** One explicitly scoped Entity table or physically separate tables.
- **Recommended option:** One table with mandatory `knowledge_scope` and exact Tenant-consistency constraint.
- **Alternatives considered:** Separate shared/private tables; ambiguous nullable Tenant model.
- **Reason:** Identity/lifecycle are identical, while explicit scope plus RLS preserves ownership without duplicated contracts.
- **Coupling/reversibility:** Medium security coupling; explicit discriminator supports later physical separation.

### M004-D04 — Entity Type lifecycle — APPROVED

- **Decision:** Type fields, code format, lifecycle, dependency, and mutation.
- **Recommended option:** Section 6 and 7.1: common code/bounds, draft-active-deprecated, active dependency, no cascade; an Entity may activate or return to active through unmerge only while its referenced Type is active.
- **Alternatives considered:** Active-only immutable rows; delete unused types; application enum.
- **Reason:** Matches established reference governance and permits controlled evolution.
- **Coupling/reversibility:** Low; additive types and terminal deprecation are reversible through new migrations.

### M004-D05 — Entity identity and name uniqueness — APPROVED

- **Decision:** Stable identity fields and uniqueness of canonical name.
- **Recommended option:** UUID identity; immutable type/scope/Tenant; canonical name non-unique and correctable.
- **Alternatives considered:** Name-based identity; scope/type-local unique name; mutable type.
- **Reason:** Real Entities may share names and identity must survive label correction.
- **Coupling/reversibility:** UUID is durable; absence of name uniqueness avoids false coupling.

### M004-D06 — Entity lifecycle — APPROVED

- **Decision:** Creation state, permitted transitions, timestamps, and terminal state.
- **Recommended option:** Exact graph in Section 8.1; creation always candidate; archived terminal.
- **Alternatives considered:** Draft/active/deprecated reference lifecycle; reactivation; caller-selected active creation.
- **Reason:** DB-001 explicitly anticipates candidate/active/merged/archived and identity review precedes activation.
- **Coupling/reversibility:** Medium; explicit transition functions and timestamps preserve migration paths.

### M004-D07 — Merge and unmerge semantics — APPROVED

- **Decision:** Target compatibility, chains, locking, reassignment, and reversibility.
- **Recommended option:** Section 8.2: same type/scope/Tenant, active direct target, no chains/cascades, deterministic locking, governed unmerge requiring an active Type, and mandatory revalidation of unmerge before any later Entity-dependent migration is admitted.
- **Alternatives considered:** Cross-type merge; merge chains; destructive consolidation; irreversible merge.
- **Reason:** Prevents identity corruption and satisfies DB-001's auditable/reversible requirement.
- **Coupling/reversibility:** High identity impact but bounded by no automatic reassignment and explicit reversal.

### M004-D08 — Alias inclusion and lifecycle — APPROVED

- **Decision:** Include aliases now and define correction/history.
- **Recommended option:** Include contextual candidate/active/superseded aliases with immutable identity/context and new-row correction.
- **Alternatives considered:** Defer aliases; mutable alias rows; canonical-name-only Entity.
- **Reason:** Minimal cross-context resolution requires alternate names without overwriting identity history.
- **Coupling/reversibility:** Low-to-medium; aliases are additive and independently supersedable.

### M004-D09 — Alias vocabulary and normalization — APPROVED

- **Decision:** Alias types and normalized matching key.
- **Recommended option:** Exact bounded vocabulary in Section 7.3; no persisted normalized key.
- **Alternatives considered:** Free text; separate alias-type registry; database-generated lowercase key; multilingual fuzzy normalization.
- **Reason:** A small semantic vocabulary supports governance; normalization requires A-028/A-031 evidence.
- **Coupling/reversibility:** Vocabulary is additive; deferred normalization avoids hard-to-reverse matching assumptions.

### M004-D10 — Alias Language/Market context — APPROVED

- **Decision:** Optional contextual FKs and their meaning.
- **Recommended option:** Require active Language and Market references when an alias is created or activated; preserve them as non-cascading historical context after later reference deprecation; prohibit interpreting Market context as presence.
- **Alternatives considered:** Defer both; Language only; arbitrary locale/source text.
- **Reason:** Existing governed registries safely qualify names without creating claim tables.
- **Coupling/reversibility:** Low additive FKs; semantics are narrow.

### M004-D11 — Creation and mutation authority — APPROVED

- **Decision:** Tenant-admin and platform authority across scopes.
- **Recommended option:** Section 10's narrow governed tenant-private authority; shared governance remains platform-only; ordinary members read only.
- **Alternatives considered:** Platform-only all Entities; any member creates candidates; tenant-admin shared authority.
- **Reason:** Tenant-private identity must be operable without granting global authority.
- **Coupling/reversibility:** High security relevance; narrow functions and tests allow later capability refinement.

### M004-D12 — RLS visibility — APPROVED

- **Decision:** Which lifecycle states each actor can read.
- **Recommended option:** Active shared visible to authenticated users; active tenant-private visible to active members; non-active private governance states visible only to same-tenant admins/platform paths; merged/current UUID resolution follows Sections 8.3 and 10 using one UUID input, two UUID outputs, active-Profile authentication, active owning-Tenant membership for private identity, no tenant-admin requirement solely for resolution, no-result non-disclosure, and a narrowly granted hardened SECURITY DEFINER function.
- **Alternatives considered:** All authenticated lifecycle states; platform-mediated reads only; all tenant members see candidates/history.
- **Reason:** Least privilege with enough administrative governance.
- **Coupling/reversibility:** Medium API behavior; policy remains additive through reviewed migrations.

### M004-D13 — Audit vocabulary — APPROVED

- **Decision:** Actions, resources, and metadata.
- **Recommended option:** Reuse three reference actions; add `entity.merged`/`entity.unmerged`; add three resource types.
- **Alternatives considered:** Treat merge only as status change; add alias-specific actions; generic privileged action only.
- **Reason:** Merge is a material identity decision requiring deterministic semantics.
- **Coupling/reversibility:** Low; additive vocabulary with stable audit history.

### M004-D14 — Field bounds and temporal rules — APPROVED

- **Decision:** Exact code/name/description/alias/confidence/time bounds.
- **Recommended option:** Sections 5 and 7, including alias length 500, confidence 0–1, null Language/Market contexts equal for duplicate detection, null interval bounds unbounded, and no overlapping otherwise-identical active alias episodes.
- **Alternatives considered:** Unbounded text; percentage confidence; mandatory validity.
- **Reason:** SQL requires deterministic constraints; optional validity avoids asserting unknown real-world dates.
- **Coupling/reversibility:** Low; future widening is additive, narrowing requires data review.

### M004-D15 — Deferred claims and provenance boundary — APPROVED

- **Decision:** Whether relationships, Market presence, or Domain membership enter Migration 004.
- **Recommended option:** Defer all three; prohibit placeholders and polymorphic references.
- **Alternatives considered:** Include unaudited candidate claims; allow free-text provenance; create empty link shells.
- **Reason:** These are claims, not identity, and Evidence does not yet exist.
- **Coupling/reversibility:** Deferral is least coupled and fully additive later.

### M004-D16 — Merge concurrency and lock order — APPROVED

- **Decision:** Concurrency strategy for pairwise merge/unmerge.
- **Recommended option:** Transaction advisory locking over both Entity UUIDs in deterministic UUID order before row locks and validation.
- **Alternatives considered:** Row locks only; single global lock; optimistic unique constraints only.
- **Reason:** Prevents opposing merges/cycles without globally serializing unrelated identity decisions.
- **Coupling/reversibility:** Implementation-local and replaceable behind governed functions.

## 17. SQL-blocker review

M004-D01 through M004-D16 were approved by the BIOS Executive Office on 2026-08-04. No known architecture SQL blocker remains for Migration 004.

The merged-Entity resolver security interface is canonically determined by Sections 8.3 and 10.

If SQL implementation, security review, executable test design, or migration replay discovers a new material ambiguity or architectural decision not explicitly governed by DB-005, implementation must stop rather than infer or invent architecture. The issue must return to the BIOS Executive Office for resolution before implementation continues. Outstanding implementation validation work is a future gate, not an unresolved architecture decision.

## 18. Readiness checklist

- [x] Governing documents and Migration 001–003 invariants reviewed.
- [x] Exact three-table recommendation stated.
- [x] All provisional objects classified.
- [x] Shared/private scope is explicit and denies null-Tenant inference.
- [x] Entity Type governance and zero-seed recommendation stated.
- [x] Entity lifecycle and merge candidate specified.
- [x] Alias scope, context, history, and Source-document deferral specified.
- [x] Claims/provenance boundary stated.
- [x] Security, RLS, audit, and deletion posture specified.
- [x] Eighty-eight acceptance requirements defined.
- [x] M004-D01 through M004-D16 approved by the BIOS Executive Office.
- [ ] SQL security review completed.
- [ ] Executable pgTAP/RLS tests completed.
- [ ] Clean local migration replay completed.

## 19. Recommendation

**CANONICAL — READY FOR MIGRATION 004 IMPLEMENTATION DESIGN-TO-SQL GATE**

DB-005 is now Canonical and M004-D01 through M004-D16 are approved. Migration 004 SQL implementation has not been completed; SQL security review, executable pgTAP/RLS tests, and clean local migration replay remain future implementation gates.

## 20. Version history

| Version | Date | Change |
|---|---|---|
| 1.3 | 2026-08-04 | Canonical clarification of merged Entity UUID resolver authorization, output, non-disclosure, and SECURITY DEFINER contract; no architecture boundary change |
| 1.2 | 2026-08-04 | Canonical admission following Executive Office approval of M004-D01 through M004-D16; no architecture boundary change |
| 1.1 | 2026-08-04 | Precision amendment: active-Type unmerge invariant, historical alias-reference lifecycle, merged-UUID resolution, deterministic null/temporal alias duplication, and future unmerge revalidation gate |
| 1.0 | 2026-08-03 | Initial proposed Migration 004 Entity Foundation implementation design |
