# DB-003 — BIOS Migration 002: Geography, Market & Language Foundation

| Field | Value |
|---|---|
| Document ID | DB-003 |
| Title | BIOS Migration 002 — Geography, Market & Language Foundation |
| Version | 1.1 |
| Status | Canonical |
| Effective date | 2026-08-03 |
| Owner | BIOS Executive Office — Data Architecture and Engineering |
| Dependencies | ADR-001, ARCH-001, ARCH-002, DB-001, DB-002 v1.1, ENG-001, CANON-001 |
| Supersedes | DB-003 v1.0 |
| Review cadence | Before implementation admission and after relevant Atlas resolution |
| Related documents | [README](../../README.md), [ENG-001](../engineering/ENG-001_BIOS_Engineering_Handbook.md), [CANON-001](../engineering/CANON-001_Repository_and_Engineering_Standards.md), [ADR-001](../decisions/ADR-001_PostgreSQL_and_Supabase.md), [ARCH-001](../architecture/ARCH-001_Canonical_Platform_Architecture.md), [ARCH-002](../architecture/ARCH-002_Architecture_Assumption_Register.md), [DB-001](DB-001_Canonical_Data_Model.md), [DB-002](DB-002_Migration_001_Core_Platform_Foundation.md) |

## 1. Purpose

DB-003 defines exactly what the second executable PostgreSQL/Supabase migration is permitted to create. Migration 002 establishes shared, governed Geography, Market, Market-group, and Language reference structures required by later BIOS knowledge, evidence, intelligence, and decision layers.

Migration 002 does not encode current commercial priorities as permanent architecture. It creates no tenant-private Market configuration, Domain/Category model, multilingual processing workflow, evidence, intelligence, agent, vector, connector, Client, or Workspace structure.

This is an implementation design specification. It contains no SQL.

## 2. Canonical principles

1. Geography and Market are distinct concepts.
2. A Market is a commercial or analytical scope, not a country alias.
3. Market and Geography relate many-to-many.
4. Greater China is an ordinary configurable Market group containing Mainland China, Hong Kong, and Taiwan—not a country, parent Geography, parent Market, or special schema object.
5. Priority 1 and Priority 2 are operational configuration, not reference identity or schema constraints.
6. Language identifiers are governed; translation and normalization remain deferred.
7. All Migration 002 data is shared platform reference data.
8. Tenant roles grant no authority over shared platform references.
9. Atlas assumptions remain unvalidated merely because the database can represent them.
10. The design remains expandable beyond the initial operating markets.

## 3. Exact migration boundary

Migration 002 may create exactly eight tables:

1. `bios_core.geographies`
2. `bios_core.geography_relationships`
3. `bios_core.markets`
4. `bios_core.market_geographies`
5. `bios_core.market_groups`
6. `bios_core.market_group_members`
7. `bios_core.languages`
8. `bios_core.market_languages`

It may add only the constraints, indexes, RLS policies, grants, narrow trusted mutation helpers, timestamp/immutability protections, and additive DB-002 audit-vocabulary extensions required by this document. No new PostgreSQL extension is authorized.

Migration 002 must not create Client, Workspace, Domain, Category, pack, ontology, entity, source, document, evidence, provenance, signal, pattern, finding, Decision Context, recommendation, decision, connector, ingestion, agent, vector, flexible-attribute, knowledge-promotion, translation, or normalization objects.

## 4. Common conventions

| Concern | Rule |
|---|---|
| Primary identifier | BIOS-owned UUID independent of external standards |
| Stable code | 3–64 lowercase characters matching `^[a-z][a-z0-9_]{1,62}[a-z0-9]$` |
| Display name | Trimmed text, 1–200 characters |
| Description | Optional trimmed text, maximum 1,000 characters |
| Lifecycle | `draft → active → deprecated`; deprecated is terminal in Migration 002 |
| Time | `timestamptz`; database-generated `created_at` and `updated_at` |
| Relationship history | Immutable endpoint episode with `valid_from` and nullable `valid_to` |
| Active episode | `valid_to` is null; scheduled future activation is not supported |
| Scope | Shared platform reference; no `tenant_id` |
| Mutation | Trusted BIOS service or exceptional platform administration only |
| Physical deletion | Not supported through the Migration 002 governed application model |

For a relationship episode, `valid_from` defaults to transaction time, `valid_to` must be null or later than `valid_from`, and only `valid_to` plus audit-maintained `updated_at` may change. Ending and later re-adding a relationship creates separate historical episodes.

## 5. Approved implementation decisions

### M002-D01 — Geography coding standard — APPROVED

Use a BIOS-owned UUID as the canonical relationship identifier and a globally unique immutable BIOS `code`. External identifiers are not primary keys and are deferred to a normalized later model when authority and version semantics are approved. Migration 002 adds no ISO-specific columns and assumes no universal external code.

### M002-D02 — Market identity — APPROVED

Use a BIOS-owned UUID and globally unique immutable BIOS Market `code`. Identity is independent of country codes, display labels, priority, and Geography membership.

### M002-D03 — Market priority — APPROVED AS DEFERRED

Migration 002 contains no priority field or priority table. Priority belongs to later governed platform configuration.

### M002-D04 — Market-group scope — APPROVED

Migration 002 implements only shared platform-governed Market groups. Tenant-private groups remain deferred; no mixed scope or nullable tenant ownership is allowed.

### M002-D05 — Language standard — APPROVED WITH REFINEMENT

Use a BIOS canonical Language tag based on a restricted BCP 47-compatible subset supporting only:

- `language`
- `language-Script`
- `language-Region`
- `language-Script-Region`

The canonical stored form must match:

```text
^[a-z]{2,3}(-[A-Z][a-z]{3})?(-([A-Z]{2}|[0-9]{3}))?$
```

Canonicalization occurs before persistence. PostgreSQL validates the already-canonical BIOS representation and its agreement with separately stored base-language, optional script, and optional region components. It does not implement the complete BCP 47 canonicalization algorithm.

Variants, extensions, private-use tags, grandfathered tags, and broader BCP 47 support are deferred and may be added later. `en`, `ja`, `ko`, `ms`, `id`, `th`, `vi`, `hi`, `zh-Hans`, and `zh-Hant` are illustrative only and are not automatically seeded.

### M002-D06 — Reference seed governance — APPROVED

The executable migration creates no Geography, Market, group, Language, or relationship business rows. Stable production reference rows require a separate reviewed deterministic seed process. P1/P2 context is never reference identity. Test fixtures belong under `supabase/tests/` or approved fixture support.

### M002-D07 — Geography relationship vocabulary — APPROVED

The only Migration 002 Geography relationship type is `contains`. The subject contains the object. Self-links and cycles are prohibited; a Geography may have zero, one, or many containers. Additional types require an additive migration.

### M002-D08 — Market-Geography relationship vocabulary — APPROVED

The only roles are `primary` and `included`. A Market may have at most one active primary Geography and any number of included Geographies. A primary link requires an active included link for the same pair. One Geography may participate in many Markets.

### M002-D09 — Market-group semantics — APPROVED AS SIMPLIFIED

Market groups contain stable identity, descriptive metadata, lifecycle, and membership only. No mandatory business-purpose taxonomy exists. Analytical, operational, reporting, portfolio, and other purpose semantics are deferred. Greater China requires no type.

### M002-D10 — Market-Language semantics — APPROVED AS SIMPLIFIED

`market_languages` records only many-to-many Market–Language episodes. It contains no usage role or primary-Language invariant. Official, supported, ingestion, primary, and other workflow semantics remain deferred.

### M002-D11 — Audit vocabulary — APPROVED

Migration 002 adds exactly these action codes:

- `reference.created`
- `reference.status_changed`
- `reference.metadata_updated`
- `reference.relationship_added`
- `reference.relationship_ended`

It adds exactly these resource types:

- `geography`
- `geography_relationship`
- `market`
- `market_geography`
- `market_group`
- `market_group_member`
- `language`
- `market_language`

`reference.metadata_updated` applies only to trusted correction of approved non-identity metadata. It never authorizes identity mutation. Safe metadata identifies approved fields changed, reason where supplied, and bounded governance information; unrestricted before/after snapshots are prohibited. All metadata inherits DB-002’s JSON-object and 8,192-byte limits.

## 6. Table specifications

### 6.1 `bios_core.geographies`

Shared registry of governed places beyond countries.

| Field | Type | Null | Default | Rule |
|---|---|---:|---|---|
| `id` | `uuid` | No | Generated UUID | Immutable primary key |
| `code` | `text` | No | None | Globally unique immutable BIOS code |
| `name` | `text` | No | None | 1–200 trimmed characters |
| `geography_type` | `text` | No | None | `country`, `territory`, `administrative_region`, `subnational_geography`, `macro_region`, or `other` |
| `description` | `text` | Yes | Null | Maximum 1,000 characters |
| `status` | `text` | No | `draft` | Common lifecycle |
| `created_at` | `timestamptz` | No | Transaction time | Immutable |
| `updated_at` | `timestamptz` | No | Transaction time | Audit-maintained |
| `activated_at` | `timestamptz` | Yes | Null | Required for active/deprecated |
| `deprecated_at` | `timestamptz` | Yes | Null | Required only when deprecated |

Primary key and unique code constraints apply. Index `(status, geography_type)` and administrative name lookup. `id`/`code` are identity and immutable. `name`, `description`, and `geography_type` may be corrected only by trusted administration after validation and `reference.metadata_updated` audit. Status changes use `reference.status_changed`. No physical deletion is available.

Authenticated users read active rows; anonymous and untrusted/tenant-admin writes are denied. Atlas: A-026, A-036.

### 6.2 `bios_core.geography_relationships`

Shared many-to-many Geography relationship episodes.

| Field | Type | Null | Default | Rule |
|---|---|---:|---|---|
| `id` | `uuid` | No | Generated UUID | Immutable primary key |
| `subject_geography_id` | `uuid` | No | None | Immutable containing-Geography FK |
| `object_geography_id` | `uuid` | No | None | Immutable contained-Geography FK |
| `relationship_type` | `text` | No | `contains` | Exact D07 vocabulary |
| `valid_from` | `timestamptz` | No | Transaction time | Immutable episode start |
| `valid_to` | `timestamptz` | Yes | Null | Episode end |
| `created_at` | `timestamptz` | No | Transaction time | Immutable |
| `updated_at` | `timestamptz` | No | Transaction time | Audit-maintained |

FKs do not cascade. Self-links and transitive cycles are rejected. A partial unique index prevents duplicate active subject/object/type episodes. Active child/container indexes are required. Adding/ending emits the corresponding relationship audit action. Endpoints/start are immutable; no physical deletion is available. Atlas: A-026, A-030, A-036.

### 6.3 `bios_core.markets`

Shared commercial/analytical scopes distinct from Geography.

| Field | Type | Null | Default | Rule |
|---|---|---:|---|---|
| `id` | `uuid` | No | Generated UUID | Immutable primary key |
| `code` | `text` | No | None | Globally unique immutable BIOS code |
| `name` | `text` | No | None | 1–200 trimmed characters |
| `description` | `text` | Yes | Null | Maximum 1,000 characters |
| `status` | `text` | No | `draft` | Common lifecycle |
| `created_at` | `timestamptz` | No | Transaction time | Immutable |
| `updated_at` | `timestamptz` | No | Transaction time | Audit-maintained |
| `activated_at` | `timestamptz` | Yes | Null | Required for active/deprecated |
| `deprecated_at` | `timestamptz` | Yes | Null | Required only when deprecated |

Primary key, unique code, lifecycle checks, status index, and administrative name lookup apply. No priority, country-code, tenant, or category field exists. `id`/`code` are immutable; `name`/`description` corrections require trusted administration and `reference.metadata_updated`. Referenced rows deprecate rather than delete. Atlas: A-026, A-036.

### 6.4 `bios_core.market_geographies`

Shared many-to-many Market coverage episodes.

| Field | Type | Null | Default | Rule |
|---|---|---:|---|---|
| `id` | `uuid` | No | Generated UUID | Immutable primary key |
| `market_id` | `uuid` | No | None | Immutable Market FK |
| `geography_id` | `uuid` | No | None | Immutable Geography FK |
| `relationship_role` | `text` | No | `included` | `primary` or `included` |
| `valid_from` | `timestamptz` | No | Transaction time | Immutable start |
| `valid_to` | `timestamptz` | Yes | Null | Episode end |
| `created_at` | `timestamptz` | No | Transaction time | Immutable |
| `updated_at` | `timestamptz` | No | Transaction time | Audit-maintained |

FKs do not cascade. Partial unique indexes prevent duplicate active pair/role episodes and more than one active primary per Market. Trusted mutation enforces that primary also has active included coverage. Endpoint/role/start are immutable; ending preserves history; no physical deletion is available. Atlas: A-026, A-030, A-036.

### 6.5 `bios_core.market_groups`

Shared group identity and lifecycle without purpose taxonomy.

| Field | Type | Null | Default | Rule |
|---|---|---:|---|---|
| `id` | `uuid` | No | Generated UUID | Immutable primary key |
| `code` | `text` | No | None | Globally unique immutable BIOS code |
| `name` | `text` | No | None | 1–200 trimmed characters |
| `description` | `text` | Yes | Null | Maximum 1,000 characters |
| `status` | `text` | No | `draft` | Common lifecycle |
| `created_at` | `timestamptz` | No | Transaction time | Immutable |
| `updated_at` | `timestamptz` | No | Transaction time | Audit-maintained |
| `activated_at` | `timestamptz` | Yes | Null | Required for active/deprecated |
| `deprecated_at` | `timestamptz` | Yes | Null | Required only when deprecated |

Primary key, unique code, lifecycle checks, status index, and name lookup apply. There is no type, tenant, nesting, priority, or Greater China special field. `id`/`code` are immutable; `name`/`description` corrections require `reference.metadata_updated`. No physical deletion is available. Atlas: A-026, A-036, A-037.

### 6.6 `bios_core.market_group_members`

Shared many-to-many group-membership episodes.

| Field | Type | Null | Default | Rule |
|---|---|---:|---|---|
| `id` | `uuid` | No | Generated UUID | Immutable primary key |
| `market_group_id` | `uuid` | No | None | Immutable group FK |
| `market_id` | `uuid` | No | None | Immutable Market FK |
| `valid_from` | `timestamptz` | No | Transaction time | Immutable start |
| `valid_to` | `timestamptz` | Yes | Null | Episode end |
| `created_at` | `timestamptz` | No | Transaction time | Immutable |
| `updated_at` | `timestamptz` | No | Transaction time | Audit-maintained |

FKs do not cascade. A partial unique index prevents duplicate active group/Market episodes. Active membership indexes work in both directions. Ending preserves history and permits a later episode. Member ordering is deferred. No physical deletion is available. Atlas: A-026, A-030, A-036.

### 6.7 `bios_core.languages`

Shared governed BIOS Language profiles for future multilingual workflows.

| Field | Type | Null | Default | Rule |
|---|---|---:|---|---|
| `id` | `uuid` | No | Generated UUID | Immutable primary key |
| `tag` | `text` | No | None | Unique canonical restricted-subset tag |
| `base_language_subtag` | `text` | No | None | 2–3 lowercase ASCII letters |
| `script_subtag` | `text` | Yes | Null | Four title-case ASCII letters |
| `region_subtag` | `text` | Yes | Null | Two uppercase ASCII letters or three digits |
| `display_name` | `text` | No | None | 1–200 trimmed characters |
| `native_name` | `text` | Yes | Null | Maximum 200 trimmed characters |
| `status` | `text` | No | `draft` | Common lifecycle |
| `created_at` | `timestamptz` | No | Transaction time | Immutable |
| `updated_at` | `timestamptz` | No | Transaction time | Audit-maintained |
| `activated_at` | `timestamptz` | Yes | Null | Required for active/deprecated |
| `deprecated_at` | `timestamptz` | Yes | Null | Required only when deprecated |

Primary key and unique tag apply. Checks enforce the restricted regex, component regexes, exact tag reconstruction, bounds, status, and lifecycle. `id`, tag, and parsed components are immutable; display/native names may be corrected through trusted administration with `reference.metadata_updated`. No physical deletion is available. Atlas: A-028, A-038.

### 6.8 `bios_core.market_languages`

Shared many-to-many Market–Language episodes without usage semantics.

| Field | Type | Null | Default | Rule |
|---|---|---:|---|---|
| `id` | `uuid` | No | Generated UUID | Immutable primary key |
| `market_id` | `uuid` | No | None | Immutable Market FK |
| `language_id` | `uuid` | No | None | Immutable Language FK |
| `valid_from` | `timestamptz` | No | Transaction time | Immutable start |
| `valid_to` | `timestamptz` | Yes | Null | Episode end |
| `created_at` | `timestamptz` | No | Transaction time | Immutable |
| `updated_at` | `timestamptz` | No | Transaction time | Audit-maintained |

FKs do not cascade. A partial unique index prevents duplicate active Market/Language episodes. Active indexes work in both directions. Endpoints/start are immutable; ending preserves history and permits a later episode. No physical deletion is available. Atlas: A-026, A-028, A-030, A-036, A-038.

## 7. Security, RLS, and audit

All eight tables are shared platform reference data and contain no tenant owner. RLS is required if exposed through Supabase APIs.

| Actor | Read active | Read draft/deprecated | Insert/update/end | Delete |
|---|---:|---:|---:|---:|
| Anonymous | No | No | No | No |
| Authenticated ordinary user | Yes | No | No | No |
| Tenant administrator | Yes | No | No | No |
| Trusted BIOS service | Purpose-scoped | Purpose-scoped | Governed path | No |
| Exceptional platform administration | Governed | Governed | Governed and audited | No |

Tenant-admin authority remains tenant-scoped and cannot mutate global references. Service-role credentials remain server-side and are not business authorization by themselves. Every trusted mutation validates action/resource vocabulary and writes its event atomically. Migration 002 creates no governed delete function; database-owner emergency recovery is outside the application contract.

| Operation | Audit action |
|---|---|
| Create base reference | `reference.created` |
| Change status | `reference.status_changed` |
| Correct approved metadata | `reference.metadata_updated` |
| Add relationship episode | `reference.relationship_added` |
| End relationship episode | `reference.relationship_ended` |
| Physical deletion | Not supported |

## 8. Greater China and priority

Greater China is represented by three ordinary Markets, one ordinary shared Market group, and three membership episodes. No Greater China Geography, parent Market, special type, or priority field is required.

P1/P2 data remains outside the reference schema. Seed presence never implies commercial validation or permanent priority.

## 9. Atlas control

| Assumption | Migration 002 relationship | Validation effect |
|---|---|---|
| A-026 | Configurable Markets/groups avoid Market-specific forks | None |
| A-028 | Language profiles prepare for multilingual workflows | None |
| A-030 | Relationship episodes provide minimal reversible time semantics | None |
| A-036 | Shared Markets/groups can later support Market Packs | None |
| A-037 | Tenant-private Market/group configuration remains deferred | None |
| A-038 | Stable Language identity prepares for multilingual provenance | None |

## 10. Migration 001 regression compatibility clarification

### 10.1 Executable finding

A clean local reset succeeded through Migrations 001 and 002, and the Migration 002 pgTAP suite passed. Two Migration 001 assertions failed because they globally scanned every `bios_%` object and therefore treated approved additive Migration 002 objects as forbidden.

These are test-scope defects, not Migration 002 SQL defects and not Migration 001 security regressions. After Migration 002, the canonical BIOS schema contains six Migration 001 tables plus eight Migration 002 tables, for fourteen BIOS tables.

### 10.2 Canonical regression principle

Migration 001’s security, tenancy, identity, authorization, audit, history, RLS, and six-table foundation invariants must continue to pass under later migrations.

Migration 001 regression tests may receive narrowly scoped maintenance when an assertion incorrectly assumes that later canonical migrations cannot add BIOS tables or columns. Such maintenance must:

- preserve the original Migration 001 security meaning;
- preserve the 49-test count unless separately approved;
- scope structural assertions to Migration 001-owned objects;
- never weaken tenant isolation, RLS, identity, authorization, audit, membership history, role history, or last-admin protection;
- not modify Migration 001 migration SQL; and
- not reinterpret approved later additions as Migration 001 defects.

### 10.3 Exactly authorized test maintenance

Only two narrow changes are authorized in `supabase/tests/001_bios_core_platform_foundation_test.sql`:

1. **Test 12:** count and require exactly the six Migration 001-owned foundation tables: `bios_core.profiles`, `bios_core.tenants`, `bios_core.tenant_memberships`, `bios_core.roles`, `bios_core.membership_roles`, and `bios_governance.audit_events`. Do not count Migration 002 tables against Migration 001.
2. **Test 13:** restrict the forbidden-column scan to those same six tables. Continue rejecting `password`, `encrypted_password`, `provider`, `mfa_state`, `token`, `workspace_id`, `client_id`, `market_id`, and `category_id` within Migration 001-owned tables. Approved `market_id` columns in Migration 002 tables are not Migration 001 regressions.

The remaining 47 assertions remain unchanged. No modification is authorized to `supabase/migrations/20260802072541_bios_core_platform_foundation.sql`, any Migration 001 RLS policy, or any other Migration 001 test.

This is test maintenance, not migration modification.

## 11. Migration 002 acceptance plan

All database tests belong in `supabase/tests/`; this document writes none.

1. Clean reset succeeds through Migrations 001 and 002.
2. Exactly the eight Migration 002 tables exist.
3. No excluded Domain/Category, Client/Workspace, evidence/intelligence, agent, vector, connector, or tenant-group table exists.
4. Geography and Market remain distinct.
5. Market–Geography many-to-many behavior works.
6. Greater China is represented through an ordinary group and three memberships.
7. No Market priority is structurally required.
8. Duplicate stable codes/tags are rejected.
9. Invalid codes, restricted canonical Language tags/components, Geography types, relationship vocabularies, statuses, and transitions are rejected.
10. Field bounds are enforced.
11. Invalid/self Geography endpoints and invalid FKs are rejected.
12. Geography cycles are rejected.
13. Duplicate active episodes are rejected; ended episodes permit later new episodes.
14. More than one active primary Geography per Market is rejected.
15. Primary Market-Geography requires active included coverage.
16. Market-Language many-to-many and active uniqueness work.
17. Relationship endpoints/type-or-role/start are immutable.
18. Base identity and Language canonical components are immutable.
19. Approved metadata correction emits `reference.metadata_updated`.
20. Metadata correction cannot mutate identity.
21. Governed physical deletion is denied.
22. Authenticated users read active references; anonymous users do not.
23. Ordinary users and tenant administrators cannot mutate shared references.
24. Trusted mutations are atomic and operation-specifically audited.
25. Approved audit codes work and unknown codes are rejected.
26. No executable seed requires P1/P2.
27. Test fixtures do not become production migration rows.
28. Migration 001’s 49-test regression suite passes after the approved forward-compatibility maintenance scopes structural assertions to Migration 001-owned objects; all substantive Migration 001 security and behavioral assertions remain unchanged.
29. The full Migration 002 suite passes.
30. Clean reset/replay produces the expected identical structure.

## 12. Migration safety and compatibility

- Migration 002 is forward-only and immutable after merge; corrections use later migrations.
- It does not edit Migration 001 tables, SQL, RLS, roles, or audit history; audit vocabulary extension is additive.
- Relationship endpoints/history are never overwritten or erased.
- No governed physical-delete permission or function exists.
- Reference seeds are deterministic, reviewed, and separate from priority/Atlas status.
- Local recovery is guarded reset/replay; shared/production use requires tested backup/restore and forward recovery.
- Migration 003 may add Domain/Category references additively; Migration 002 creates no Domain dependency.

## 13. SQL and executable-validation readiness

No architecture or SQL blocker remains. All required audited operations have approved actions, identity and episode invariants are deterministic, and the regression-test clarification preserves rather than weakens Migration 001.

Before implementation PR admission, executable validation must rerun and pass:

1. a clean database reset;
2. all 49 Migration 001 tests after only the two approved scope corrections; and
3. the full Migration 002 test suite.

## 14. Readiness recommendation

**READY FOR SQL IMPLEMENTATION / EXECUTABLE VALIDATION**

Downstream gates remain SQL security review, executable pgTAP/RLS validation, all 49 maintained Migration 001 tests passing, the full Migration 002 suite passing, clean local replay, and normal repository/pull-request review.

## 15. Version history

| Version | Date | Change |
|---|---|---|
| 1.1 | 2026-08-03 | Clarified forward-compatible Migration 001 regression testing after executable Migration 002 validation demonstrated that two global structural assertions incorrectly prohibited additive canonical schema evolution |
| 1.0 | 2026-08-03 | Initial canonical Migration 002 Geography, Market, Market-group, and Language foundation, including pre-admission corrections |
