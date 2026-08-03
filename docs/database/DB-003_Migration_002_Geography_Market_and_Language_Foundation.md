# DB-003 — BIOS Migration 002: Geography, Market & Language Foundation

| Field | Value |
|---|---|
| Document ID | DB-003 |
| Title | BIOS Migration 002 — Geography, Market & Language Foundation |
| Version | 1.0 |
| Status | Canonical |
| Effective date | 2026-08-03 |
| Owner | BIOS Executive Office — Data Architecture and Engineering |
| Dependencies | ADR-001, ARCH-001, ARCH-002, DB-001, DB-002 v1.1, ENG-001, CANON-001 |
| Supersedes | None |
| Review cadence | Before SQL implementation, before merge, and after relevant Atlas resolution |
| Related documents | [README](../../README.md), [ENG-001](../engineering/ENG-001_BIOS_Engineering_Handbook.md), [CANON-001](../engineering/CANON-001_Repository_and_Engineering_Standards.md), [ADR-001](../decisions/ADR-001_PostgreSQL_and_Supabase.md), [ARCH-001](../architecture/ARCH-001_Canonical_Platform_Architecture.md), [ARCH-002](../architecture/ARCH-002_Architecture_Assumption_Register.md), [DB-001](DB-001_Canonical_Data_Model.md), [DB-002](DB-002_Migration_001_Core_Platform_Foundation.md) |

## 1. Purpose

DB-003 defines exactly what the second executable PostgreSQL/Supabase migration is permitted to create. Migration 002 establishes shared, governed geography, market, market-group, and language reference structures required by later BIOS knowledge, evidence, intelligence, and decision layers.

Migration 002 does not encode the Executive Office’s current commercial priorities as permanent architecture. It adds no tenant-private market configuration, Domain/Category model, multilingual processing workflow, evidence, intelligence, agent, vector, connector, Client, or Workspace structure.

This is an implementation design specification. It contains no SQL.

## 2. Canonical architecture preserved

1. Geography and Market are separate concepts.
2. A Market is a commercial or analytical operating scope, not a country alias.
3. Markets and geographies relate many-to-many.
4. Market groups are configurable collections of markets.
5. Greater China is representable as a market group containing Mainland China, Hong Kong, and Taiwan; it is not a country, parent geography, parent market, or special schema object.
6. Priority 1 and Priority 2 are operational configuration, not intrinsic reference attributes or constraints.
7. Language identifiers are governed and stable, while translation and normalization remain deferred.
8. Shared reference mutation is platform-governed; tenant roles do not grant global-reference authority.
9. Atlas assumptions remain unvalidated merely because the schema can represent them.
10. All new structures remain expandable beyond the initial Phase 1 operating context.

## 3. Authority and decision labels

- **Canonical requirement:** required by an approved governing document.
- **Implementation decision — approved:** an Executive Office-approved deterministic implementation choice.
- **Approved with refinement:** approved subject to the precise refinement stated in this document.
- **Approved as simplified:** approved after removing semantics not required by Migration 002.
- **Deferred:** deliberately excluded from Migration 002.
- **SQL blocker:** an unresolved decision that must be approved before executable SQL is generated.

## 4. Exact permitted migration surface

### 4.1 Tables

Migration 002 may create exactly these eight tables:

1. `bios_core.geographies`
2. `bios_core.geography_relationships`
3. `bios_core.markets`
4. `bios_core.market_geographies`
5. `bios_core.market_groups`
6. `bios_core.market_group_members`
7. `bios_core.languages`
8. `bios_core.market_languages`

All are expressly supported by DB-001 Sections 9.1–9.5 and defined by ARCH-001 Sections 8–9. No canonical conflict was found.

### 4.2 Supporting objects

Migration 002 may create only supporting objects required by this specification:

- primary, foreign-key, unique, check, and not-null constraints;
- indexes listed in the table specifications;
- RLS policies and grants;
- narrow helper or trusted mutation functions for shared reference governance;
- trigger functions for timestamps, immutability, relationship episode closure, and required audit events where constraints/grants are insufficient;
- additive extensions to the DB-002 audit action and resource vocabularies after M002-D11 approval;
- comments documenting object ownership and security intent.

No new PostgreSQL extension is authorized.

## 5. Explicit exclusions

Migration 002 must not create:

- Client, Workspace, or workspace membership objects;
- Domain, domain node, Domain Pack, Market Pack, category, or ontology objects;
- tenant-defined market configuration or tenant-private market groups;
- entity, alias, source, document, evidence, representation, or provenance objects;
- signal, pattern, finding, Decision Context, recommendation, or decision objects;
- connector, ingestion, agent, vector, flexible-attribute, or knowledge-promotion infrastructure;
- translation, transliteration, locale-selection, or semantic-normalization pipelines.

These are scope exclusions, not rejections of future Phase 1 concepts.

## 6. Common conventions

| Concern | Migration 002 rule |
|---|---|
| Primary identifier | BIOS-owned UUID generated independently of external standards |
| Stable code | Lowercase BIOS code, 3–64 characters, matching `^[a-z][a-z0-9_]{1,62}[a-z0-9]$` |
| Display name | Trimmed text, 1–200 characters |
| Description | Optional trimmed text, maximum 1,000 characters |
| Lifecycle | `draft`, `active`, or `deprecated` |
| Lifecycle transition | `draft → active → deprecated`; `deprecated` is terminal in Migration 002 |
| Time | `timestamptz`; database-generated `created_at` and `updated_at` |
| Relationship history | Immutable endpoint episode with `valid_from` and nullable `valid_to` |
| Active episode | `valid_to IS NULL`; future-dated activation is not supported in Migration 002 |
| Sharing | Every table is shared platform reference data; no `tenant_id` column |
| Mutation | Trusted service or exceptional platform administration only |
| Deletion | No physical deletion through the Migration 002 governed application model, regardless of lifecycle state |

For a relationship episode, `valid_from` defaults to transaction time, `valid_to` must be null or greater than `valid_from`, and only `valid_to` plus audit-maintained `updated_at` may change after insertion. Ending and re-adding a relationship creates history as separate episodes.

## 7. Implementation decisions requiring approval

### M002-D01 — Geography coding standard — APPROVED

Use a BIOS-owned UUID as the canonical relationship identifier and a globally unique, immutable BIOS `code` as the human-operable stable key. External identifiers are not primary keys and are deferred to a normalized external-identifier table in a later migration when source/authority/version semantics are approved.

Migration 002 does not add ISO-specific columns or assume every geography has an ISO representation. Initial fixtures may retain ISO references outside canonical rows for test traceability, but executable application relationships use `geographies.id`.

### M002-D02 — Market identity — APPROVED

Use a BIOS-owned UUID as the canonical Market identifier and a globally unique, immutable BIOS market `code`. Do not derive identity from a country code, display label, Priority 1/2 classification, or geography membership. This supports multi-geography markets and multiple markets covering one geography.

### M002-D03 — Market priority representation — APPROVED

Defer market priority from Migration 002. Do not add a priority column and do not create a priority/portfolio table. Priority belongs in a later governed platform-configuration model. Test or operational fixtures may carry current P1/P2 context outside canonical schema, but no priority value is required for a valid Market.

### M002-D04 — Market-group scope — APPROVED

Implement only shared, platform-governed market groups. Do not mix tenant and shared ownership and do not add nullable `tenant_id`. Tenant-private groups are deferred until a tenant configuration and authorization workflow is approved.

### M002-D05 — Language coding standard — APPROVED WITH REFINEMENT

Use a **BIOS canonical language tag based on a restricted BCP 47-compatible subset**. Migration 002 intentionally supports only `language`, `language-Script`, `language-Region`, and `language-Script-Region` forms using this grammar:

```text
^[a-z]{2,3}(-[A-Z][a-z]{3})?(-([A-Z]{2}|[0-9]{3}))?$
```

Canonicalization occurs before persistence. PostgreSQL validates the already-canonical BIOS representation and the agreement between the canonical tag and its separately stored base language, optional script, and optional region components. The database constraint is not responsible for implementing the complete BCP 47 canonicalization algorithm.

A row represents a governed BIOS language profile used for content processing; `zh-Hans` and `zh-Hant` are distinct script-qualified profiles sharing base language `zh`. Illustrative valid forms include `en`, `ja`, `ko`, `ms`, `id`, `th`, `vi`, `hi`, `zh-Hans`, and `zh-Hant`; these examples are not automatically authorized seed rows. A region-qualified tag is added only when a validated workflow needs it and must not be interpreted as a different human language merely because it has a separate profile row.

This is not complete BCP 47 validation. Variants, extensions, private-use tags, and grandfathered tags are deferred. Broader BCP 47 support may be introduced additively later.

### M002-D06 — Reference seed governance — APPROVED

The executable schema migration creates no geography, market, group, language, or relationship business rows. Stable production reference data must be supplied through a separately reviewed, deterministic reference-data seed process. Current operating priority must not be part of those rows.

`supabase/tests/` may create synthetic or clearly identified representative fixtures, including a Greater China group case. Local development seed data may include reviewed Phase 1 references but must remain distinguishable from commercial priority and Atlas validation.

### M002-D07 — Geography relationship vocabulary — APPROVED

Migration 002 permits exactly one geography relationship type: `contains`. A `contains` episode means the subject geography contains the object geography for the stated validity interval. A geography may have zero, one, or many containing geographies; no `parent_id` exists. Self-links are prohibited. Additional relationship types require a later additive migration.

### M002-D08 — Market-geography relationship vocabulary — APPROVED

Migration 002 permits exactly `primary` and `included` roles. `included` means the geography is within the Market’s defined coverage. `primary` additionally identifies the principal geography for display/default purposes. A Market may have at most one active `primary` episode but any number of active `included` episodes. The same geography may participate in many markets. A primary geography must also have an active included episode; trusted mutation must enforce this transactional invariant.

### M002-D09 — Market-group semantics — APPROVED AS SIMPLIFIED

Migration 002 establishes stable Market-group identity, lifecycle, description, and Market membership without requiring a business-purpose taxonomy. No mandatory Market-group purpose field or replacement classification is permitted. Analytical, operational, reporting, portfolio, and other purpose semantics are deferred until an actual configuration or workflow requires them. Greater China is valid as an ordinary Market group without a type.

### M002-D10 — Market-language semantics — APPROVED AS SIMPLIFIED

Migration 002 represents only a governed many-to-many relationship episode between a Market and a Language profile. It has no usage-role field. `Primary`, `official`, `supported`, `ingestion`, and other usage semantics are deferred until evidence, configuration, and concrete workflows justify them. The same Market may relate to many Language profiles, and the same Language profile may relate to many Markets.

### M002-D11 — Audit vocabulary extension — APPROVED

Extend DB-002 additively with exactly these action codes:

- `reference.created`
- `reference.status_changed`
- `reference.metadata_updated`
- `reference.relationship_added`
- `reference.relationship_ended`

Extend `resource_type` with exactly:

- `geography`
- `geography_relationship`
- `market`
- `market_geography`
- `market_group`
- `market_group_member`
- `language`
- `market_language`

The resource identifies the affected table concept. `reference.metadata_updated` applies only when trusted platform administration corrects approved non-identity descriptive/classification metadata; it never authorizes identity mutation. Its safe metadata identifies the approved fields changed, a reason where supplied, and other bounded governance information. It must not store unrestricted before/after row snapshots. Other safe metadata may identify endpoint UUIDs, the remaining Geography relationship type or Market-Geography role, and `from_status`/`to_status` where applicable. All metadata inherits DB-002’s 8,192-byte JSON-object limit. Migration 002 must extend constraints in its own forward migration and must not edit Migration 001.

M002-D01 through M002-D11 are approved in the dispositions above and no longer block SQL implementation.

## 8. Table specifications

### 8.1 `bios_core.geographies`

#### Purpose and scope

Shared platform registry of governed physical or jurisdictional places. It supports country, territory, administrative region, subnational geography, macro-region, and other explicitly governed types without treating all rows as countries.

#### Fields

| Field | Type | Null | Default | Rule |
|---|---|---:|---|---|
| `id` | `uuid` | No | Generated UUID | Primary key; immutable |
| `code` | `text` | No | None | Globally unique BIOS code; immutable after creation |
| `name` | `text` | No | None | 1–200 trimmed characters |
| `geography_type` | `text` | No | None | `country`, `territory`, `administrative_region`, `subnational_geography`, `macro_region`, or `other` |
| `description` | `text` | Yes | Null | Maximum 1,000 characters |
| `status` | `text` | No | `draft` | Common lifecycle |
| `created_at` | `timestamptz` | No | Transaction time | Immutable |
| `updated_at` | `timestamptz` | No | Transaction time | Audit-maintained |
| `activated_at` | `timestamptz` | Yes | Null | Required when active/deprecated |
| `deprecated_at` | `timestamptz` | Yes | Null | Required only when deprecated |

#### Constraints, indexes, and lifecycle

- Primary key on `id`; unique constraint on `code`.
- Checks enforce code/name/description bounds, exact type/status vocabularies, and lifecycle timestamp consistency.
- Indexes on `(status, geography_type)` and normalized display name for administrative lookup; name is not identity.
- `id` and `code` are immutable identity attributes. `name`, `description`, and `geography_type` are descriptive/classification metadata and may be corrected through trusted platform administration after validation and required audit. An approved `geography_type` correction does not require a replacement Geography. Ordinary users and tenant administrators cannot modify identity or metadata. Status lifecycle remains separately governed.
- Physical deletion is not available through any Migration 002 governed application path, including for draft or unreferenced rows. Draft mistakes remain draft unless corrected through governed metadata correction or handled by a later explicitly governed cleanup migration/workflow.

#### Access, audit, and compatibility

Authenticated users may read active rows; anonymous users are denied. Ordinary users and tenant administrators cannot write. Trusted service/platform administration may mutate through the governed path. Creation, status change, and approved metadata correction emit `reference.created`, `reference.status_changed`, and `reference.metadata_updated` respectively. Future external identifiers and Domain links are additive.

**Atlas:** A-026 and A-036; representation does not validate either.

### 8.2 `bios_core.geography_relationships`

#### Purpose and scope

Shared, typed, many-to-many geography relationship episodes. Hierarchy belongs here, not on `geographies.parent_id`, so a geography can participate in multiple governed hierarchies.

#### Fields

| Field | Type | Null | Default | Rule |
|---|---|---:|---|---|
| `id` | `uuid` | No | Generated UUID | Primary key; immutable |
| `subject_geography_id` | `uuid` | No | None | FK to containing geography; immutable |
| `object_geography_id` | `uuid` | No | None | FK to contained geography; immutable |
| `relationship_type` | `text` | No | `contains` | M002-D07 vocabulary |
| `valid_from` | `timestamptz` | No | Transaction time | Episode start; immutable |
| `valid_to` | `timestamptz` | Yes | Null | Episode end; only domain-mutable field |
| `created_at` | `timestamptz` | No | Transaction time | Immutable |
| `updated_at` | `timestamptz` | No | Transaction time | Audit-maintained |

#### Constraints, indexes, and history

- FKs do not cascade; subject and object must differ.
- Partial unique index prevents duplicate active `(subject, object, type)` episodes.
- Indexes support active children by subject and active containers by object.
- Checks enforce exact type and valid interval.
- Direct cycles are prohibited. General transitive cycle prevention belongs in the trusted mutation function and must be tested; no fixed single-parent rule exists.
- Ending sets `valid_to` and audits `reference.relationship_ended`; no ordinary delete or endpoint update.

Authenticated active-reference reads are permitted; all untrusted writes are denied. Trusted administration adds/ends episodes. **Atlas:** A-026, A-030, A-036.

### 8.3 `bios_core.markets`

#### Purpose and scope

Shared registry of configurable commercial or analytical operating scopes. A Market is not synonymous with a country or geography.

#### Fields

| Field | Type | Null | Default | Rule |
|---|---|---:|---|---|
| `id` | `uuid` | No | Generated UUID | Primary key; immutable |
| `code` | `text` | No | None | Globally unique BIOS code; immutable |
| `name` | `text` | No | None | 1–200 trimmed characters |
| `description` | `text` | Yes | Null | Maximum 1,000 characters |
| `status` | `text` | No | `draft` | Common lifecycle |
| `created_at` | `timestamptz` | No | Transaction time | Immutable |
| `updated_at` | `timestamptz` | No | Transaction time | Audit-maintained |
| `activated_at` | `timestamptz` | Yes | Null | Required when active/deprecated |
| `deprecated_at` | `timestamptz` | Yes | Null | Required only when deprecated |

No priority field, country code, tenant owner, or category field is permitted.

#### Constraints, indexes, lifecycle, and access

- Primary key on `id`; unique constraint on `code`.
- Checks enforce common bounds/status/timestamps.
- Index on status and administrative name lookup.
- `id` and `code` are immutable identity attributes. `name` and `description` may be corrected through trusted platform administration after validation and `reference.metadata_updated` audit. Referenced rows are deprecated, not deleted; status follows the separate lifecycle. Physical deletion is unavailable through Migration 002 governed paths.
- Authenticated users read active rows. Anonymous reads and all ordinary/tenant-admin writes are denied. Trusted administration creates, changes status, or corrects approved metadata with the corresponding required audit action.

**Atlas:** A-026 and A-036.

### 8.4 `bios_core.market_geographies`

#### Purpose and scope

Shared many-to-many episodes connecting Markets to geographic coverage without asserting identity.

#### Fields

| Field | Type | Null | Default | Rule |
|---|---|---:|---|---|
| `id` | `uuid` | No | Generated UUID | Primary key; immutable |
| `market_id` | `uuid` | No | None | FK to Market; immutable |
| `geography_id` | `uuid` | No | None | FK to Geography; immutable |
| `relationship_role` | `text` | No | `included` | `primary` or `included` |
| `valid_from` | `timestamptz` | No | Transaction time | Episode start; immutable |
| `valid_to` | `timestamptz` | Yes | Null | Episode end |
| `created_at` | `timestamptz` | No | Transaction time | Immutable |
| `updated_at` | `timestamptz` | No | Transaction time | Audit-maintained |

#### Constraints, indexes, and history

- FKs do not cascade.
- Partial unique index prevents duplicate active `(market, geography, role)` episodes.
- Partial unique index allows at most one active primary geography per Market.
- Indexes support active geographies by Market and active Markets by Geography.
- Checks enforce role and temporal rules. Trusted mutation enforces active `included` coverage for a `primary` link.
- Endpoint/role/start fields are immutable. Ending preserves history; ordinary deletion is denied.

Authenticated users read relationships whose endpoints are active. Ordinary and tenant-admin writes are denied; trusted administration writes and audits. **Atlas:** A-026, A-030, A-036.

### 8.5 `bios_core.market_groups`

#### Purpose and scope

Shared platform-governed configurable collections of Markets with stable identity, lifecycle, description, and membership. Migration 002 does not classify a group’s business purpose. Greater China is an ordinary group configuration, not a special entity type.

#### Fields

| Field | Type | Null | Default | Rule |
|---|---|---:|---|---|
| `id` | `uuid` | No | Generated UUID | Primary key; immutable |
| `code` | `text` | No | None | Globally unique BIOS code; immutable |
| `name` | `text` | No | None | 1–200 trimmed characters |
| `description` | `text` | Yes | Null | Maximum 1,000 characters |
| `status` | `text` | No | `draft` | Common lifecycle |
| `created_at` | `timestamptz` | No | Transaction time | Immutable |
| `updated_at` | `timestamptz` | No | Transaction time | Audit-maintained |
| `activated_at` | `timestamptz` | Yes | Null | Required when active/deprecated |
| `deprecated_at` | `timestamptz` | Yes | Null | Required only when deprecated |

#### Constraints, lifecycle, and access

- Primary key on `id`; unique code; checks enforce bounds, status, and timestamps.
- Index on status and administrative name lookup.
- `id` and `code` are immutable identity attributes. `name` and `description` may be corrected through trusted platform administration after validation and `reference.metadata_updated` audit. Referenced groups are deprecated, not deleted. Physical deletion is unavailable through Migration 002 governed paths.
- No group type, tenant ID, nested group, priority, or special Greater China column exists.
- Authenticated users read active groups; untrusted/tenant-admin writes are denied; trusted administration creates, changes status, or corrects approved metadata with the corresponding required audit action.

**Atlas:** A-026, A-036, A-037. Tenant group behavior remains deferred.

### 8.6 `bios_core.market_group_members`

#### Purpose and scope

Shared many-to-many membership episodes connecting Market groups to Markets.

#### Fields

| Field | Type | Null | Default | Rule |
|---|---|---:|---|---|
| `id` | `uuid` | No | Generated UUID | Primary key; immutable |
| `market_group_id` | `uuid` | No | None | FK to group; immutable |
| `market_id` | `uuid` | No | None | FK to Market; immutable |
| `valid_from` | `timestamptz` | No | Transaction time | Episode start; immutable |
| `valid_to` | `timestamptz` | Yes | Null | Episode end |
| `created_at` | `timestamptz` | No | Transaction time | Immutable |
| `updated_at` | `timestamptz` | No | Transaction time | Audit-maintained |

#### Constraints, indexes, and history

- FKs do not cascade.
- Partial unique index prevents duplicate active `(group, market)` episodes.
- Indexes support active members by group and groups by Market.
- Endpoints/start are immutable; ending preserves history; ordinary deletion is denied.
- Member ordering and presentation metadata are deferred to a later configuration/presentation migration. Membership add/end is always audited.

Authenticated users read active memberships; untrusted/tenant-admin writes are denied; trusted administration writes and audits. **Atlas:** A-026, A-030, A-036.

### 8.7 `bios_core.languages`

#### Purpose and scope

Shared registry of governed BIOS language profiles for future multilingual content handling. It provides reference identity only; it does not translate, normalize, infer, or assess language quality.

#### Fields

| Field | Type | Null | Default | Rule |
|---|---|---:|---|---|
| `id` | `uuid` | No | Generated UUID | Primary key; immutable |
| `tag` | `text` | No | None | Unique BIOS canonical language tag using the restricted BCP 47-compatible subset |
| `base_language_subtag` | `text` | No | None | 2–3 lowercase ASCII letters |
| `script_subtag` | `text` | Yes | Null | Four ASCII letters in title case |
| `region_subtag` | `text` | Yes | Null | Two uppercase ASCII letters or three digits |
| `display_name` | `text` | No | None | 1–200 trimmed characters |
| `native_name` | `text` | Yes | Null | Maximum 200 trimmed characters; no completeness claim |
| `status` | `text` | No | `draft` | Common lifecycle |
| `created_at` | `timestamptz` | No | Transaction time | Immutable |
| `updated_at` | `timestamptz` | No | Transaction time | Audit-maintained |
| `activated_at` | `timestamptz` | Yes | Null | Required when active/deprecated |
| `deprecated_at` | `timestamptz` | Yes | Null | Required only when deprecated |

#### Constraints, indexes, lifecycle, and access

- Primary key on `id`; unique case-sensitive canonical `tag` after normalization.
- Canonicalization occurs before persistence. Checks enforce the M002-D05 restricted-subset regex, component regexes, exact reconstruction of `tag` from already-canonical components, name bounds, status, and lifecycle timestamps; they do not implement the complete BCP 47 canonicalization algorithm.
- Indexes on base language, `(base_language_subtag, script_subtag)`, and status.
- ID/tag/components are immutable identity attributes. Display/native names may be corrected through trusted platform administration after validation and `reference.metadata_updated` audit. Referenced rows are deprecated, not deleted. Physical deletion is unavailable through Migration 002 governed paths.
- Authenticated users read active rows; anonymous and untrusted/tenant-admin writes are denied; trusted administration creates, changes status, or corrects approved metadata with the corresponding required audit action.

**Atlas:** A-028 and A-038. Schema support does not validate normalization quality.

### 8.8 `bios_core.market_languages`

#### Purpose and scope

Shared many-to-many operational relationship episodes between Markets and Language profiles. Roles express BIOS usage, not universal official-language or sociolinguistic truth.

#### Fields

| Field | Type | Null | Default | Rule |
|---|---|---:|---|---|
| `id` | `uuid` | No | Generated UUID | Primary key; immutable |
| `market_id` | `uuid` | No | None | FK to Market; immutable |
| `language_id` | `uuid` | No | None | FK to Language; immutable |
| `valid_from` | `timestamptz` | No | Transaction time | Episode start; immutable |
| `valid_to` | `timestamptz` | Yes | Null | Episode end |
| `created_at` | `timestamptz` | No | Transaction time | Immutable |
| `updated_at` | `timestamptz` | No | Transaction time | Audit-maintained |

#### Constraints, indexes, and history

- FKs do not cascade.
- Partial unique index prevents duplicate active `(market, language)` episodes.
- Indexes support active languages by Market and Markets by Language.
- Endpoints and start are immutable; ending preserves history and allows a later new episode; ordinary deletion is denied. Language usage semantics are deferred.

Authenticated users read active relationships; untrusted/tenant-admin writes are denied; trusted administration writes and audits. **Atlas:** A-026, A-028, A-030, A-036, A-038.

## 9. Security and RLS

All eight tables are shared platform reference data. None contains `tenant_id`; this is explicit scope, not null-tenant sharing. Migration 001 tenant-owned policies remain unchanged.

RLS is required on all eight tables if exposed through Supabase APIs. Policy posture:

| Actor | Read active shared references | Read draft/deprecated | Insert/update/end | Delete |
|---|---:|---:|---:|---:|
| Anonymous | No | No | No | No |
| Authenticated ordinary user | Yes | No | No | No |
| Tenant administrator | Yes | No | No | No |
| Trusted BIOS service | Purpose-scoped | Purpose-scoped | Through approved governed path | No |
| Exceptional platform administration | Governed | Governed | Governed and audited | No |

Tenant administrator is a tenant-scoped capability and confers no global reference mutation right. Service-role bypass remains server-side and does not itself establish business authorization. Every trusted mutation validates action/resource vocabulary and writes its audit event atomically. Migration 002 creates no governed reference-delete function. Database-owner emergency recovery outside the BIOS application governance model is outside this contract.

## 10. Audit obligations

| Operation | Action | Resource type |
|---|---|---|
| Create base reference | `reference.created` | `geography`, `market`, `market_group`, or `language` |
| Change base status | `reference.status_changed` | Same base resource |
| Correct approved non-identity metadata | `reference.metadata_updated` | Same base resource |
| Add relationship episode | `reference.relationship_added` | Corresponding relationship resource |
| End relationship episode | `reference.relationship_ended` | Corresponding relationship resource |

Safe metadata is limited by DB-002’s 8,192-byte JSON-object constraint. For `reference.metadata_updated`, it identifies which approved metadata fields changed, a reason where supplied, and only other bounded governance information; unrestricted before/after row snapshots are prohibited. Other events may include endpoint UUIDs, the remaining Geography relationship type or Market-Geography role, `valid_from`, `valid_to`, `from_status`, `to_status`, and reason. No Market-group purpose type, Market-Language usage role, unrestricted row snapshot, or personal data is added.

M002-D11 is approved. Migration 002 must extend DB-002’s governed audit checks additively before any new reference mutation can succeed.

## 11. Temporal semantics

Base registry rows use lifecycle timestamps and are deprecated rather than historically rewritten. All four relationship tables use immutable episode rows with a start and optional end. This implements the minimal historical validity required by DB-001 without full bitemporal modeling.

Migration 002 does not support scheduled future episodes, uncertain dates, retroactive corrections, or system-time reconstruction beyond audit history. A correction to an active relationship ends the erroneous episode at correction time and creates a new episode; it does not falsify the earlier record. Richer temporal correction remains under A-030.

## 12. Greater China representation

After approved reference data exists, Greater China is represented as:

- three ordinary Markets for Mainland China, Hong Kong, and Taiwan;
- one ordinary shared Market group; and
- three active `market_group_members` episodes.

There is no Greater China geography row required, no parent link, no parent Market, no priority field, and no special constraint. The executable schema migration does not seed this group under M002-D06; a reviewed reference-data process or test fixture demonstrates it.

## 13. Seed governance

| Data class | Migration 002 treatment |
|---|---|
| Schema/reference structure | Created by migration |
| Stable business reference rows | Separate reviewed deterministic reference-data seed after M002-D06 approval |
| P1/P2 operational priority | Deferred to platform configuration; never reference identity |
| Atlas commercial validation | Remains in Atlas; never implied by seed presence |
| Test fixtures | Created and cleaned by `supabase/tests/` or approved test fixture support |
| Local demonstration data | Safe, synthetic/reviewed, separate from production migration |

No real client, tenant, research evidence, or category data is authorized.

## 14. Atlas control

| Assumption | Migration 002 relationship | Validation effect |
|---|---|---|
| A-026 | Configurable Market and group structures avoid Market-specific schema forks | None; representability is not validation |
| A-028 | Language profiles prepare for future cross-language workflows | None; no normalization is implemented |
| A-030 | Relationship episodes provide a reversible minimal temporal model | None; richer temporal needs remain testable |
| A-036 | Shared Markets/groups provide a future target for Market Packs | None; no Market Pack exists |
| A-037 | Tenant-private Market/group configuration is deferred | None |
| A-038 | Stable Language identities prepare for versioned multilingual provenance | None; evidence representations are absent |

## 15. Acceptance test plan

All database-level tests belong in `supabase/tests/`. No tests are written by this specification.

Required tests:

1. Clean local reset succeeds through Migrations 001 and 002.
2. Exactly the eight approved Migration 002 tables exist.
3. No Domain/Category, Client/Workspace, evidence/intelligence, agent, vector, connector, or tenant-group table exists.
4. Geography and Market rows have distinct tables and identifiers.
5. One Market relates to multiple geographies and one Geography to multiple Markets.
6. Greater China is representable through one ordinary group and three memberships without a parent geography/Market.
7. No Market priority field or required priority relationship exists.
8. Duplicate stable codes/tags are rejected.
9. Invalid stable codes, restricted BCP 47-compatible canonical tags/components, geography types, Geography relationship types, Market-Geography roles, statuses, and lifecycle transitions are rejected.
10. Bounds for names, descriptions, and native names are enforced.
11. Invalid/self geography endpoints and invalid foreign-key endpoints are rejected.
12. Geography cycle attempts are rejected through the trusted mutation path.
13. Duplicate active relationship episodes are rejected; ended history permits a later new episode.
14. More than one active primary Geography per Market is rejected.
15. A primary Market-Geography link without active included coverage is rejected.
16. Market-Language many-to-many behavior works, duplicate active `(market_id, language_id)` episodes are rejected, and an ended episode permits a later new episode.
17. Relationship endpoints/types/roles/start times are immutable; only permitted episode closure succeeds.
18. Base-reference `id`/`code` and Language canonical tag/components are immutable.
19. Permitted descriptive/classification metadata correction succeeds only through trusted administration, satisfies constraints, and emits `reference.metadata_updated`.
20. A metadata-correction attempt cannot mutate an immutable identity field.
21. Physical deletion is denied to ordinary users, tenant administrators, trusted BIOS services, and exceptional platform administration through the governed application model.
22. Authenticated users can read active shared references.
23. Anonymous users cannot read shared references.
24. Ordinary users and tenant administrators cannot mutate global references merely because of their tenant role.
25. Trusted administrative mutation is atomic and emits the required operation-specific audit event.
26. New action/resource vocabulary satisfies DB-002 audit constraints; unknown action and resource codes remain rejected.
27. No executable seed requires a current P1/P2 classification.
28. Test-only fixtures are not retained as production migration reference rows.
29. Migration 001’s existing 49 tests pass unchanged.
30. Catalog/structural snapshot is identical after clean reset/replay.

Later integration tests may verify API exposure, service credential isolation, and reference-data publication workflow. RLS and database invariants must not be deferred to integration tests.

## 16. Migration safety

- **Forward migration:** create the eight tables and supporting objects, extend audit checks additively, enable RLS, and grant only the approved privileges. Fail on incompatible pre-existing objects.
- **Local reset:** the guarded local Supabase reset rebuilds Migrations 001 and 002 from source control with safe fixtures only.
- **Immutability:** after merge or shared application, Migration 002 is immutable; corrections use new forward migrations.
- **Evolution:** add external identifiers, tenant configuration, new vocabularies, or richer temporal semantics additively after approval.
- **History:** never overwrite relationship endpoints or erase ended episodes.
- **Deletion:** Migration 002 supplies no governed physical-delete function or permission for its eight tables. Draft mistakes remain correctable metadata or future cleanup work; database-owner emergency recovery is outside the application contract.
- **Seed reproducibility:** stable codes and reviewed source manifests identify seed rows; seed processing fails on incompatible meaning rather than silently replacing it.
- **Recovery:** current local-only recovery is reset/replay; shared/production use requires forward recovery and tested backup/restore.
- **Migration 001 compatibility:** do not edit its tables, RLS, roles, or audit history; only extend its audit constraint vocabularies in Migration 002.
- **Migration 003 compatibility:** Domain/Category tables may later reference Market and Language IDs where architecture permits, but Migration 002 creates no Domain dependency.

## 17. SQL-blocker review

The specification resolves vague executable terms as follows:

| Term | Deterministic meaning or decision |
|---|---|
| Bounded | Exact field lengths are specified |
| Stable | Immutable UUID/code/tag rules are specified under D01, D02, D05 |
| Governed | Mutation actors, trusted path, operation-specific audit events, and vocabularies are specified |
| Valid | Exact lifecycle, time interval, and FK/check behavior is specified |
| Safe | Audit metadata inherits DB-002 object/size/content restrictions |
| Standard | Restricted BCP 47-compatible canonical-tag regex and pre-persistence canonicalization boundary are specified; complete BCP 47 and external Geography standards are deferred |
| Configurable | Data rows and relationships, never country-specific schema branches |
| Supported | Exact Migration 002 code, lifecycle, Geography relationship, and Market-Geography role vocabularies are enumerated; Market-group types and Market-Language roles are explicitly absent |
| Immutable | Identity attributes and relationship endpoints/start are immutable; governed descriptive/classification metadata correction is separately authorized through `reference.metadata_updated` |
| Active | Base status is `active`; relationship episode has null `valid_to` |

The SQL-readiness audit found no remaining specification blocker. Every required audited operation has an approved action: create → `reference.created`; status transition → `reference.status_changed`; governed metadata correction → `reference.metadata_updated`; relationship creation → `reference.relationship_added`; relationship ending → `reference.relationship_ended`. Physical deletion is not supported by Migration 002.

Exact bounds, regexes, lifecycle transitions, relationship vocabularies, active-episode uniqueness, Geography cycle prevention, the primary Market-Geography transactional invariant, canonical-language-tag validation boundary, trusted mutation permissions, audit codes, seed behavior, metadata-correction permissions, and deprecation/no-delete rules are defined.

ARCH-001, ARCH-002, DB-001, and DB-002 v1.1 are present at their canonical repository paths and constitute the approved architecture and database baseline for Migration 002.

## 18. Migration 002 readiness checklist

### Architecture and scope

- [x] Exactly eight Migration 002 tables are specified.
- [x] Geography, Market, group, and Language remain distinct governed concepts.
- [x] No excluded platform layer is introduced.
- [x] Greater China and P1/P2 are not schema truths.

### Geography

- [x] UUID/code identity, type vocabulary, hierarchy relationship, cardinality, cycle, history, and deletion rules are specified.
- [x] M002-D01 and M002-D07 approved.

### Markets and market groups

- [x] Market identity is independent of country and priority.
- [x] Market-Geography and group-member many-to-many episodes are specified.
- [x] Only shared groups are proposed; tenant groups remain deferred.
- [x] M002-D02, D03, D04, and D08 approved; D09 approved as simplified with no group-purpose taxonomy.

### Languages

- [x] Restricted BCP 47-compatible canonical-tag grammar, components, and pre-persistence canonicalization boundary are explicit.
- [x] Translation/normalization remains deferred.
- [x] M002-D05 approved with refinement; D10 approved as simplified with no usage-role taxonomy.

### Security and RLS

- [x] Shared scope is explicit and contains no nullable tenant ownership.
- [x] Anonymous and untrusted mutation are denied.
- [x] Tenant administrators receive no platform-reference write authority.
- [ ] SQL RLS implementation receives security review.

### Audit

- [x] Exact additive action/resource vocabularies and event obligations are proposed.
- [x] Governed metadata correction uses `reference.metadata_updated` without authorizing identity mutation or row snapshots.
- [x] Physical reference deletion is unsupported and has no action code or governed function.
- [x] M002-D11 additive audit vocabulary approved.

### Temporal semantics and seed governance

- [x] Relationship episode history and lifecycle rules are deterministic.
- [x] Current priority is separated from reference identity and seed data.
- [x] M002-D06 approved.

### Testing and reproducibility

- [x] Database acceptance tests cover structure, policy, relationships, history, codes, audit, and replay.
- [ ] Executable tests pass with all 49 Migration 001 tests unchanged.
- [ ] Clean local migration replay is demonstrated.

### Atlas and migration compatibility

- [x] A-026, A-028, A-030, A-036, A-037, and A-038 remain unvalidated.
- [x] Migration 001 security/identity structures are not weakened or rewritten.
- [x] Migration 003 retains an additive Domain/Category boundary.
- [x] ARCH-001, ARCH-002, DB-001, and DB-002 v1.1 are present at their canonical repository paths.

## 19. Readiness recommendation

**READY FOR SQL IMPLEMENTATION**

DB-003 is deterministic enough for implementation. Normal downstream gates remain: SQL security review, executable pgTAP/RLS tests, all 49 Migration 001 tests passing unchanged, clean local migration replay, and repository/pull-request review.

## 20. Version history

| Version | Date | Change |
|---|---|---|
| 1.0 | 2026-08-03 | Initial canonical implementation design for Migration 002 Geography, Market, Market-group, and Language foundation, incorporating pre-admission review corrections |
