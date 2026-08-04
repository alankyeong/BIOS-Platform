# DB-006 — BIOS Migration 005: Source & Document Foundation

| Field | Value |
|---|---|
| Document ID | DB-006 |
| Title | BIOS Migration 005 — Source & Document Foundation |
| Version | 1.3 |
| Status | Canonical |
| Effective date | 2026-08-04 |
| Owner | BIOS Executive Office — Data Architecture and Engineering |
| Dependencies | ADR-001, ARCH-001, ARCH-002, DB-001, DB-002 v1.1, DB-003 v1.1, DB-004 v1.0, DB-005 v1.3, ENG-001, CANON-001 |
| Supersedes | DB-006 v1.2 |
| Review cadence | Before SQL implementation, before merge, and after relevant Atlas resolution |
| Related documents | [ENG-001](../engineering/ENG-001_BIOS_Engineering_Handbook.md), [CANON-001](../engineering/CANON-001_Repository_and_Engineering_Standards.md), [ADR-001](../decisions/ADR-001_PostgreSQL_and_Supabase.md), [ARCH-001](../architecture/ARCH-001_Canonical_Platform_Architecture.md), [ARCH-002](../architecture/ARCH-002_Architecture_Assumption_Register.md), [DB-001](DB-001_Canonical_Data_Model.md), [DB-002](DB-002_Migration_001_Core_Platform_Foundation.md), [DB-003](DB-003_Migration_002_Geography_Market_and_Language_Foundation.md), [DB-004](DB-004_Migration_003_Domain_and_Category_Foundation.md), [DB-005](DB-005_Migration_004_Entity_Foundation.md) |

## 1. Purpose

DB-006 defines the smallest coherent fifth PostgreSQL/Supabase migration for governed Source and Source Document identity. It preserves the chain from information origin to identifiable publication artifact so a later Evidence migration can cite a durable Source Document UUID without collapsing Source, Document, retrieval, content representation, Evidence, or intelligence into one object.

This is an implementation design specification. It contains no SQL. The decisions in Section 17 require Executive Office approval before SQL implementation.

## 2. Canonical boundaries

- A **Source** is a governed publisher, provider, origin, repository, or information channel identity.
- A **Source Document** is one identifiable publication or released artifact supplied by one Source.
- A Source is not Evidence.
- A Source Document is not Evidence.
- A URL is a locator, not stable identity.
- Retrieved or extracted content is not validated Evidence.
- Audit records governance activity and is not evidentiary provenance.
- Reliability, truth, relevance, and quality are assessments outside durable Source identity.

## 3. Object classification and exact migration boundary

| Object | Classification | Dependency reasoning |
|---|---|---|
| `bios_knowledge.sources` | REQUIRED IN MIGRATION 005 | Later documents and Evidence require a durable governed origin identity. |
| `bios_knowledge.source_documents` | REQUIRED IN MIGRATION 005 | Later Evidence requires a precise publication/artifact UUID distinct from Source identity. |
| `bios_knowledge.source_types` | DEFER | No approved type vocabulary currently changes security or lifecycle; a registry would encode an unvalidated media/provider taxonomy. |
| `bios_knowledge.source_document_versions` | DEFER | Material revisions are separate Source Document rows with explicit predecessor lineage; content representations and richer versioning await Evidence/representation needs. |
| `bios_knowledge.source_retrievals` | DEFER | Retrieval is an operational event owned by a later ingestion/retrieval model, not Document identity. |
| `bios_knowledge.source_document_locations` | DEFER | Migration 005 permits one optional governed locator; multi-location history awaits demonstrated ingestion and citation requirements. |

Migration 005 may create exactly two BIOS tables:

1. `bios_knowledge.sources`
2. `bios_knowledge.source_documents`

`bios_knowledge` already exists from Migration 004. Supporting objects are limited to required constraints, indexes, foreign keys, RLS policies, grants, narrow trusted functions, lifecycle/immutability/timestamp protections, lineage concurrency controls, and additive audit vocabulary. No extension is authorized.

## 4. Explicit exclusions

Migration 005 must not create Source Types, separate document versions, retrievals, locator collections, connectors, crawler/API jobs, ingestion queues, extraction/OCR/parsing/chunking/embedding state, storage-object registries, raw binary/text, normalized content, Evidence, representations, claims, observations, facts, provenance edges, Signals, Patterns, Findings, Decision Contexts, Recommendations, Decisions, vectors, Entity relationships, Market presence, Domain membership, packs, attributes/EAV, Client, or Workspace structures.

It must not add Evidence status, claim text, finding/signal IDs, arbitrary polymorphic references, subjective reliability scores, or hidden Entity relationships to either authorized table.

## 5. Common conventions

| Concern | Migration 005 rule |
|---|---|
| Primary key | BIOS-owned generated UUID with no external or business meaning |
| Stable code | 3–64 lowercase characters matching `^[a-z][a-z0-9_]{1,62}[a-z0-9]$` |
| Name | Trimmed text, 1–200 characters |
| Description/note | Null or trimmed, non-empty text of at most 1,000 characters |
| Scope | Explicit `knowledge_scope` of exactly `shared` or `tenant` |
| Tenant ownership | Null exactly for shared rows; non-null valid Tenant exactly for tenant rows |
| Time | `timestamptz`; database-set `created_at`; database-maintained `updated_at` |
| Mutation | Narrow governed operations only; no direct untrusted table mutation |
| Physical deletion | Unsupported through governed application paths |
| Production seeds | Zero Source and Source Document rows |

## 6. Source identity

A Source identifies an information origin or provider boundary. It need not be a legal organization, website, Entity, connector, or hostname. One organization may operate multiple Sources, and Source-to-Entity association is deferred.

Source uses an immutable UUID and immutable stable code. A shared Source code is globally unique among shared Sources. A tenant-private Source code is unique within its owning Tenant. The same code may exist in different Tenants and may coexist across shared and tenant scope. Canonical name is correctable and not identity or unique.

No `source_type_id` or source-type column is authorized. Type classification remains deferred because it has no approved security or workflow consequence. No initial Source Type vocabulary or commercial seed is created.

An optional `canonical_origin_uri` provides administrative origin context. It is nullable, trimmed, 1–2,048 characters when supplied, correctable through governance, and never unique or identity. Migration 005 performs no URL canonicalization beyond trim and does not derive Source identity from hostnames.

### 6.1 Source metadata correction matrix

For candidate, active, and deprecated Sources, governed factual metadata correction may update only `canonical_name`, `description`, and `canonical_origin_uri`. In every lifecycle state, `id`, `code`, `knowledge_scope`, `tenant_id`, and `created_at` are immutable. Metadata correction preserves the Source lifecycle state, never reactivates a deprecated Source, updates `updated_at`, and emits the required metadata audit event atomically. No other Source field is mutable through metadata correction.

## 7. Source scope and lifecycle

Shared and tenant-private Sources coexist in one explicitly scoped table. Sharing is determined by `knowledge_scope`, never merely by a null Tenant. Scope and Tenant are immutable. Tenant-private-to-shared promotion is absent under A-042.

Source lifecycle is:

```text
candidate → active → deprecated
candidate → deprecated
```

Creation always starts candidate. Deprecated is terminal; no reactivation is authorized. Activation and deprecation are separate governed operations. Source deprecation is blocked while any candidate or active Source Document references it; superseded and archived Documents do not block deprecation. Deprecation does not delete historical Documents, change their status, rewrite `source_id`, invalidate historical Source/Document identity, or cascade lifecycle changes. Superseded and archived Documents remain historically attached to the deprecated Source through authorized governance/history paths.

A deprecated Source remains historically addressable but accepts no new candidate Document, Document activation, or successor proposal. A successor candidate must be created while its Source and predecessor are active.

Candidate requires null `activated_at` and `deprecated_at`. Active requires non-null `activated_at` and null `deprecated_at`. Deprecated requires non-null `deprecated_at`; `activated_at` is retained when the Source was formerly active and remains null when candidate transitioned directly to deprecated.

## 8. `bios_knowledge.sources`

| Field | Null | Rule |
|---|---:|---|
| `id` | No | Generated UUID primary key; immutable |
| `code` | No | Immutable scope-compatible stable code using Section 5 |
| `canonical_name` | No | Trimmed 1–200 characters; correctable; non-unique |
| `description` | Yes | Section 5 description rule; correctable |
| `canonical_origin_uri` | Yes | Trimmed 1–2,048 characters; correctable; not unique or identity |
| `knowledge_scope` | No | Exactly `shared` or `tenant`; immutable |
| `tenant_id` | Conditional | Null exactly for shared; non-null valid Tenant exactly for tenant; immutable |
| `status` | No | `candidate`, `active`, or `deprecated`; default candidate |
| `created_at` | No | Database-set; immutable |
| `updated_at` | No | Database-maintained |
| `activated_at` | Yes | Required for active/deprecated after activation |
| `deprecated_at` | Yes | Required exactly when deprecated |

Required indexes support scope/Tenant/status reads, scope-compatible code uniqueness, and administrative name lookup. No source type, reliability score, Entity ID, Market ID, Domain ID, credential, connector, license entitlement, or content field is authorized.

## 9. Source Document identity and scope

A Source Document is one identifiable publication or released artifact. It belongs immutably to one Source but has its own explicit scope and Tenant because a tenant-private acquired artifact may originate from a shared Source.

A new ordinary candidate Source Document may be created only under a compatible Source whose status is candidate or active. Creation under a deprecated Source is rejected. Successor-candidate creation remains stricter: it requires an active Source, active predecessor, and identical Source, scope, and Tenant where applicable. Document activation always requires an active Source, so a candidate Document created under a candidate Source cannot activate until that Source becomes active.

Scope compatibility is exact:

- a shared Document must reference a shared Source;
- a tenant-private Document may reference a shared Source or a Source owned by the same Tenant;
- a tenant-private Document cannot reference another Tenant's Source;
- a tenant-private Source cannot produce a shared Document.

Document UUID, Source, scope, Tenant, optional source-local document identifier, initial locator identity, predecessor, and creation time are immutable in every lifecycle state. `content_sha256` retains its once-set rule. Correction never changes the Document UUID.

### 9.1 Metadata correction matrix

| Document lifecycle | Governed correctable fields |
|---|---|
| Candidate | `canonical_title`, `description`, `published_at`, `language_mode`/`language_id`, `media_type`, `access_classification`, `restriction_note` |
| Active | `canonical_title`, `description`, `published_at`, `language_mode`/`language_id`, `media_type`, `restriction_note` |
| Superseded or archived | `canonical_title`, `description`, `published_at`, `language_mode`/`language_id`, `media_type`, `restriction_note` |

`access_classification` cannot change after activation. No lifecycle state permits mutation of `id`, `source_id`, `knowledge_scope`, `tenant_id`, `document_identifier`, `locator_scheme`, `canonical_locator`, `supersedes_document_id`, or `created_at`; lifecycle reversal, locator replacement, and predecessor replacement are prohibited. Historical metadata correction updates `updated_at` and audit atomically. A correction setting `language_mode = single` requires an active Language at correction time. Later Language deprecation remains non-cascading.

Canonical title is not unique. `document_identifier`, when supplied, is trimmed 1–300 characters, immutable, and unique within the Source and Document ownership scope: one shared value or one value per owning Tenant. It represents a Source-issued stable identifier, not a URL. Documents without such an identifier remain valid UUID identities.

## 10. `bios_knowledge.source_documents`

| Field | Null | Rule |
|---|---:|---|
| `id` | No | Generated UUID primary key; immutable |
| `source_id` | No | Immutable Source FK; scope compatibility enforced |
| `knowledge_scope` | No | Exactly `shared` or `tenant`; immutable |
| `tenant_id` | Conditional | Null exactly for shared; non-null valid Tenant exactly for tenant; immutable |
| `document_identifier` | Yes | Source-local immutable identifier, trimmed 1–300; unique within Source and Document ownership scope when non-null |
| `canonical_title` | No | Trimmed 1–500 characters; correctable; non-unique |
| `description` | Yes | Section 5 description rule; correctable |
| `locator_scheme` | Yes | Paired with locator; exactly `url`, `doi`, `accession`, `report_number`, `source_local`, or `other` |
| `canonical_locator` | Yes | Paired with scheme; trimmed 1–2,048; immutable after creation; not globally unique or identity |
| `published_at` | Yes | Correctable publication timestamp; null means unknown, never unpublished |
| `language_mode` | No | Exactly `unknown`, `single`, or `multiple`; correctable |
| `language_id` | Conditional | Required exactly for `single`; null for `unknown` or `multiple`; active Language required at creation/activation |
| `media_type` | Yes | Lowercase IANA-style type, 3–255 characters matching `^[a-z0-9][a-z0-9!#$&^_.+-]*/[a-z0-9][a-z0-9!#$&^_.+-]*$` |
| `content_sha256` | Yes | Lowercase 64-character hex digest; may be registered once from null, then immutable; not unique |
| `access_classification` | No | Exactly `public`, `licensed`, `tenant_confidential`, or `restricted`; correctable only before activation |
| `restriction_note` | Yes | Section 5 note rule; correctable |
| `supersedes_document_id` | Yes | Immutable predecessor FK governed by Section 11 |
| `status` | No | `candidate`, `active`, `superseded`, or `archived`; default candidate |
| `created_at` | No | Database-set; immutable |
| `updated_at` | No | Database-maintained |
| `activated_at` | Yes | Required after activation and retained thereafter |
| `superseded_at` | Yes | Required exactly when superseded |
| `archived_at` | Yes | Required exactly when archived |

Locator scheme and locator are both null or both non-null. Migration 005 does not parse or normalize schemes beyond bounds and vocabulary. A locator cannot move to another Document. Incorrect locator identity is resolved before activation or by archiving the candidate and creating a corrected Document; active locator mutation is prohibited.

`content_sha256` fingerprints one acquired byte sequence when available. It is optional because Migration 005 has no retrieval requirement, and it is not unique because identical bytes may be legitimately held under different scope or publication identity. It does not store content or prove truth.

## 11. Document lifecycle, revision, and supersession

Permitted lifecycle transitions are:

```text
candidate → active → superseded
candidate → archived
active → archived
```

Superseded and archived are terminal. Creation always starts candidate. Activation requires an active compatible Source, an active Language when `language_mode = single`, and valid scope/access compatibility. No direct client lifecycle mutation is permitted.

Candidate requires all lifecycle timestamps null. Active requires non-null `activated_at` and null `superseded_at`/`archived_at`. Superseded requires retained non-null `activated_at`, non-null `superseded_at`, and null `archived_at`. Archived requires non-null `archived_at`, null `superseded_at`, and retains `activated_at` only when archived from active.

A material publication revision is a new Source Document UUID. The new candidate may identify one `supersedes_document_id`. Successor creation requires an active Source and an active predecessor with the same Source, scope, and Tenant. One predecessor may have at most one candidate successor referencing it at any time; creating a second candidate successor fails. Archiving that candidate releases the proposal position. When the candidate activates, it becomes active and the predecessor becomes superseded atomically with audit. Because the predecessor is then no longer active, it can never receive another successor proposal. The predecessor remains historically addressable. A successor chain is permitted, but cycles and self-reference are prohibited.

No content, alias, Evidence, or future reference is moved automatically. PDF and HTML releases are separate Source Documents when BIOS governs them as distinct released artifacts. A later representation/grouping model may relate formats without changing existing UUIDs.

## 12. Locator and deduplication strategy

Migration 005 performs no fuzzy or automatic deduplication. UUID is authoritative identity. URL, locator, title, publication time, and content digest are signals for governed review, not universal identity keys.

Deterministic rules are:

- optional `document_identifier` is unique within Source and Document ownership scope;
- locator values are not unique;
- content digest is not unique;
- the same URL may identify a changed artifact over time;
- material revision creates a new UUID and predecessor link;
- syndicated copies under different Sources are distinct Documents;
- tenant-private and shared copies remain distinct unless a future authorized mapping/promotion workflow relates them;
- one optional canonical locator is stored; additional locations and locator history are deferred.

This avoids false merges. Candidate duplicates may exist until governed review archives one or establishes supersession. Migration 005 does not claim semantic equivalence.

## 13. Language, Market, Entity, and access boundaries

`language_mode` distinguishes unknown, one known Language, and multilingual artifacts without creating a multilingual relation table. A single-language Document requires one active Migration 002 Language at creation and activation. Later Language deprecation preserves historical context and does not cascade Document lifecycle. Multilingual Documents carry no single `language_id`; a future representation model may identify component languages.

Source and Source Document contain no Market or Geography FK. Publication jurisdiction and evidence relevance are distinct and remain later claims. They contain no Domain or Domain Node FK.

Source contains no Entity FK. Publisher/organization relationships are useful but not identity-critical and require an explicit future relationship/provenance contract. No informal UUID substitutes for that relationship.

`access_classification` prevents the presence of a row from implying unrestricted use. It is a narrow operational classification, not legal advice or a license-entitlement engine. A shared Document may be public, licensed, or restricted, but not tenant-confidential. Tenant-private Documents may use any classification; their Tenant scope remains authoritative even when classification is public. `restriction_note` is optional for every classification, including public; licensed, tenant-confidential, and restricted Documents do not require it. The note is descriptive metadata only and never grants or overrides access. Authorization derives from scope, Tenant authority, access classification, lifecycle, and approved trusted paths. Retention rules and full licensing workflows are deferred.

## 14. Content, retrieval, Evidence, and provenance boundaries

Migration 005 stores metadata identity only. It stores no raw binary, extracted/cleaned/normalized text, chunks, embeddings, object-storage key, connector state, acquisition attempt, `first_seen_at`, `last_seen_at`, or `retrieved_at`. Those belong to versioned representation/storage or operational retrieval models.

Future Evidence may reference the exact Source Document UUID. Material revisions already receive distinct UUIDs; optional immutable digest can identify acquired bytes. If Evidence requires representation-level precision, a later additive representation/version table must be admitted before that Evidence is activated. Audit events cannot substitute for this link.

No Source/Document record asserts claim truth, Source reliability, Evidence quality, relevance, or trustworthiness. Atlas research assessments remain outside identity tables.

## 15. Security and RLS

RLS is mandatory on both tables. Anonymous access is denied. URL possession never authorizes row access.

Ordinary authenticated callers with active BIOS Profiles may read active shared Sources. They may read active shared Source Documents only when `access_classification = public`. Licensed and restricted shared Documents are not generally readable through ordinary authenticated RLS, and Tenant membership grants no such access merely because a tenant-private Document may reference a shared Source. Trusted platform governance may access these rows only through the narrowly authorized administrative/governance mechanisms required to operate the registry. Migration 005 creates no license-entitlement model and no general privileged document-content reader or trusted-reader API/function; any broader consumption interface requires a later approved entitlement/content-access migration.

Active Tenant members may read active tenant-private Sources and Documents owned by their Tenant, regardless of whether the referenced Source is shared or same-Tenant. Tenant administrators may additionally read candidate, deprecated, superseded, and archived tenant-owned governance rows. No cross-Tenant read or existence disclosure is permitted.

Ordinary authenticated users cannot mutate. Active tenant administrators may use narrow governed functions to create/correct/activate/deprecate tenant-private Sources and create/correct/activate/archive/supersede tenant-private Documents within their Tenant. Tenant-admin status grants no shared or cross-Tenant authority. Shared mutation is restricted to trusted BIOS service/exceptional platform administration.

All trusted SECURITY DEFINER operations use fixed empty `search_path`, fully qualified objects, internally re-derived Profile/membership/role/status authorization, least-privilege grants, and atomic audit. They accept no caller-supplied Tenant/Profile authority. `PUBLIC` execution is revoked and anonymous execution denied. Service-role possession alone does not define business authority.

## 16. Audit and seed governance

Reuse only existing actions:

- `reference.created`
- `reference.status_changed`
- `reference.metadata_updated`

Add exactly these resource types:

- `source`
- `source_document`

No retrieval/download action is added. Creation, lifecycle transitions, metadata correction, digest registration, and atomic Document supersession use the applicable existing action. Supersession is represented by the predecessor/successor status events and correlation metadata; it creates no new action vocabulary. Failed governed operations leave no success event.

Audit metadata is a JSON object within DB-002's 8,192-byte bound, identifies changed fields and safe reason/context, and contains no unrestricted content or row snapshots. Audit is not Evidence provenance.

Migration 005 creates zero production Sources and Source Documents. Named publishers, agencies, consultancies, platforms, and clients are prohibited as migration seeds. Tests use synthetic transactional fixtures.

## 17. Approved implementation decisions

M005-D01 through M005-D21 were approved by the BIOS Executive Office on 2026-08-04.

### M005-D01 — Exact table boundary — APPROVED — 2026-08-04

- **Decision:** Which Source/Document objects enter Migration 005.
- **Recommended option:** Create exactly `sources` and `source_documents`; defer Types, versions, retrievals, and locations.
- **Alternatives:** Sources only; all six provisional tables.
- **Reason:** Two tables establish stable origin/artifact identity; other objects require unvalidated workflows.
- **Coupling/reversibility:** Low; all deferred concepts remain additive.

### M005-D02 — Source scope and ownership — APPROVED — 2026-08-04

- **Decision:** Shared/private coexistence and code uniqueness.
- **Recommended option:** Explicit mixed scope with exact Tenant invariant; shared-global and tenant-local code uniqueness; no promotion.
- **Alternatives:** Shared-only; separate tables; ambiguous nullable Tenant.
- **Reason:** Client-provided sources require private ownership without duplicating the identity contract.
- **Coupling/reversibility:** Medium security coupling; explicit scope supports later physical separation.

### M005-D03 — Source Type treatment — APPROVED — 2026-08-04

- **Decision:** Registry, bounded column, or no type.
- **Recommended option:** No type in Migration 005.
- **Alternatives:** `source_types` registry; hard-coded vocabulary.
- **Reason:** No approved classification changes security or lifecycle; a taxonomy would be speculative.
- **Coupling/reversibility:** Highly reversible; later additive FK remains possible.

### M005-D04 — Source identity and metadata — APPROVED — 2026-08-04

- **Decision:** UUID/code/name/origin URI semantics and bounds.
- **Recommended option:** Sections 5, 6, and 8; URI correctable but neither unique nor identity; candidate, active, and deprecated Sources permit correction only of name, description, and origin URI while identity/scope fields remain immutable and lifecycle state is preserved.
- **Alternatives:** Hostname/URL identity; name identity; no stable code.
- **Reason:** Sources outlive mutable labels and web locations.
- **Coupling/reversibility:** Stable UUID/code is durable; metadata can evolve.

### M005-D05 — Source lifecycle and dependency — APPROVED — 2026-08-04

- **Decision:** Source states, transitions, terminal behavior, and Document dependency.
- **Recommended option:** Candidate-active-deprecated graph in Section 7; lifecycle-wide factual metadata correction never changes status; candidate/active Documents block deprecation, superseded/archived Documents do not; historical attachment survives without cascade; deprecated Sources reject new Documents, activation, and successor proposals.
- **Alternatives:** Reference draft lifecycle; archive/reactivate; cascade Documents.
- **Reason:** Source identity requires review and must not invalidate live Documents.
- **Coupling/reversibility:** Medium; future expansion requires an additive migration.

### M005-D06 — Source Document identity and scope — APPROVED — 2026-08-04

- **Decision:** Durable fields, own scope, and Source compatibility.
- **Recommended option:** UUID plus immutable Source/scope/Tenant and optional Source-local identifier unique within Source and Document ownership scope; ordinary candidate creation permits candidate or active compatible Source, while activation and successor proposal require active Source; compatibility in Section 9.
- **Alternatives:** Inherit Source scope only; URL identity; globally unique title/identifier.
- **Reason:** Tenant-private copies of shared origins require independent Document ownership.
- **Coupling/reversibility:** Medium security relevance; explicit constraints preserve separation.

### M005-D07 — Locator model — APPROVED — 2026-08-04

- **Decision:** Locator fields, vocabulary, uniqueness, and mutation.
- **Recommended option:** One optional paired scheme/value, bounded vocabulary, not unique, immutable after creation; defer multi-location table.
- **Alternatives:** URL-only unique column; locator table now; unrestricted scheme.
- **Reason:** A locator assists retrieval/citation but cannot safely define identity.
- **Coupling/reversibility:** Low; later location history is additive.

### M005-D08 — Revision/version model — APPROVED — 2026-08-04

- **Decision:** Separate versions or new Document per material revision.
- **Recommended option:** New Document UUID with immutable predecessor; exactly one candidate successor per active predecessor; archived candidate releases the position; activation atomically supersedes predecessor; defer version table.
- **Alternatives:** Mutable row; separate version table; content-overwrite model.
- **Reason:** Preserves exact historical citation with the smallest schema.
- **Coupling/reversibility:** Medium; later representations can group/link existing UUIDs.

### M005-D09 — Deduplication — APPROVED — 2026-08-04

- **Decision:** Which fields define duplicates.
- **Recommended option:** Section 12: no automatic/fuzzy dedup; only Source-and-ownership-scope-local identifier uniqueness and governed supersession.
- **Alternatives:** Unique URL; unique hash; fuzzy title/date matching.
- **Reason:** Each alternative creates false identity merges across revisions, formats, syndication, or scope.
- **Coupling/reversibility:** Low and conservative; future matching can add proposals without rewriting identity.

### M005-D10 — Language treatment — APPROVED — 2026-08-04

- **Decision:** Unknown/single/multilingual representation.
- **Recommended option:** `language_mode` plus conditional single `language_id`; no multilingual table.
- **Alternatives:** Nullable Language only; mandatory Language; many-to-many now.
- **Reason:** Distinguishes unknown from multilingual without speculative component modeling.
- **Coupling/reversibility:** Low; later representation-language links are additive.

### M005-D11 — Market/Geography coupling — APPROVED — 2026-08-04

- **Decision:** Foundational Market/Geography FK.
- **Recommended option:** None.
- **Alternatives:** Publication Market/jurisdiction columns; mandatory primary Market.
- **Reason:** Market relevance is a later Evidence/classification claim, not Document identity.
- **Coupling/reversibility:** No coupling; later explicit links are additive.

### M005-D12 — Entity/publisher coupling — APPROVED — 2026-08-04

- **Decision:** Source-to-Entity FK.
- **Recommended option:** Defer; add no informal Entity UUID.
- **Alternatives:** Optional publisher Entity FK; require every Source to be an Entity.
- **Reason:** Not every Source maps cleanly to an Entity and the relationship needs provenance/governance.
- **Coupling/reversibility:** Deferral preserves DB-005 unmerge contract and allows later relationship design.

### M005-D13 — Content fingerprint and storage boundary — APPROVED — 2026-08-04

- **Decision:** Digest, media type, content, and storage fields.
- **Recommended option:** Optional once-set SHA-256 and optional bounded media type; no content/storage reference.
- **Alternatives:** No fingerprint; mandatory hash; raw text/blob/storage key.
- **Reason:** A digest can identify acquired bytes without collapsing representation storage into identity.
- **Coupling/reversibility:** Low; representations/storage remain additive.

### M005-D14 — Retrieval/ingestion boundary — APPROVED — 2026-08-04

- **Decision:** First/last-seen/retrieved fields and operational tables.
- **Recommended option:** Defer all retrieval times/events/jobs.
- **Alternatives:** Document-level latest retrieval fields; retrieval table; connector state.
- **Reason:** Operational attempts are many-to-one events and should not mutate publication identity.
- **Coupling/reversibility:** Fully additive later.

### M005-D15 — Access and licensing metadata — APPROVED — 2026-08-04

- **Decision:** Classification vocabulary, compatibility, and read effect.
- **Recommended option:** Four-value classification and optional bounded descriptive note in Sections 10, 13, and 15; note never authorizes; only active public shared Documents receive general authenticated read; no general licensed/restricted reader is created.
- **Alternatives:** No rights metadata; full license/retention model; classification informational only.
- **Reason:** BIOS must not imply unrestricted access while no entitlement engine exists.
- **Coupling/reversibility:** High security relevance; vocabulary is additive, entitlement remains separate.

### M005-D16 — Document lifecycle and correction — APPROVED — 2026-08-04

- **Decision:** States, transitions, correction, immutable fields, and terminal states.
- **Recommended option:** Section 11 lifecycle plus the exact Section 9.1 correction matrix; identity/locator/predecessor immutable in every state, access classification candidate-only, factual metadata correctable throughout history with atomic timestamp/audit, no deletion/reactivation.
- **Alternatives:** In-place revision; active-to-candidate; physical deletion.
- **Reason:** Historical citation must remain reconstructable.
- **Coupling/reversibility:** Medium; explicit history allows additive refinement.

### M005-D17 — Security and RLS — APPROVED — 2026-08-04

- **Decision:** Actor visibility and mutation authority across scope/status/access classification.
- **Recommended option:** Section 15 exact policies and narrow hardened governance operations; ordinary authenticated read is limited to active public shared Documents, Tenant membership does not unlock licensed/restricted shared rows, and no entitlement/general trusted-reader interface is created.
- **Alternatives:** All shared Documents authenticated-readable; platform-only private mutation; ordinary-member candidate creation.
- **Reason:** Separates public reference visibility, tenant ownership, and restricted/licensed artifacts.
- **Coupling/reversibility:** High security impact; policy tests provide a controlled change path.

### M005-D18 — Audit vocabulary — APPROVED — 2026-08-04

- **Decision:** Actions, resources, and supersession audit.
- **Recommended option:** Reuse three reference actions; add `source` and `source_document`; no new action.
- **Alternatives:** Source-specific actions; retrieval audit action; generic privileged action only.
- **Reason:** Existing actions describe governance changes; retrieval is operational.
- **Coupling/reversibility:** Low additive resource vocabulary.

### M005-D19 — Seeds — APPROVED — 2026-08-04

- **Decision:** Production Source/Document seeds.
- **Recommended option:** Zero.
- **Alternatives:** Common publishers/agencies; infrastructure placeholder Source.
- **Reason:** No row is technically required and named sources need independent governance.
- **Coupling/reversibility:** Zero-seed is least coupled.

### M005-D20 — Publication metadata bounds — APPROVED — 2026-08-04

- **Decision:** Exact title, identifier, locator, media type, digest, time, and note constraints.
- **Recommended option:** Section 10 exact definitions and regexes.
- **Alternatives:** Unbounded text; mandatory URL/date/hash; free-form media/access values.
- **Reason:** Executable SQL requires deterministic bounds without overstating data availability.
- **Coupling/reversibility:** Future widening is additive; narrowing requires data review.

### M005-D21 — Supersession concurrency — APPROVED — 2026-08-04

- **Decision:** Concurrent successor proposals and activation ordering.
- **Recommended option:** Serialize by predecessor UUID with transaction-scoped deterministic locking before row locks; allow exactly one candidate successor per active predecessor, release the position on candidate archive, and reject all later proposals after predecessor supersession.
- **Alternatives:** Row locks only; multiple branches; global lock.
- **Reason:** Prevents double supersession and avoidable deadlocks without global serialization.
- **Coupling/reversibility:** Implementation-local and replaceable behind governed operations.

## 18. Acceptance-test plan

All executable tests belong in `supabase/tests/`; this document writes none.

1. Clean reset succeeds through Migrations 001–005.
2. Exactly the two approved Migration 005 tables exist.
3. Source Types, versions, retrievals, locations, connectors, ingestion, content, Evidence, provenance, intelligence, vectors, chunks, Entity-relationship, Market-presence, Domain-membership, Client, and Workspace objects remain absent.
4. Migration 005 creates zero production Source and Source Document rows.
5. Source UUID is generated and immutable.
6. Source code regex and bounds are enforced.
7. Shared Source code is globally unique and tenant Source code is unique within Tenant.
8. The same Source code is allowed in distinct Tenants and across shared/tenant scope.
9. Source canonical name is trimmed, bounded, correctable, non-unique, and not identity.
10. Source description and origin URI null/trim/bound rules work.
11. Source origin URI is not unique and cannot serve as primary identity.
12. Source accepts exactly shared or tenant scope.
13. Shared Source requires null Tenant and tenant Source requires non-null valid Tenant.
14. Source scope and Tenant are immutable.
15. Source creation always starts candidate.
16. Source lifecycle permits only candidate-active-deprecated and candidate-deprecated.
17. Deprecated Source is terminal and cannot reactivate.
18. Source deprecation is blocked by candidate or active Documents, while superseded and archived Documents do not block it.
19. Historical superseded/archived Documents survive Source deprecation with unchanged status and `source_id`, remain attached and historically addressable, and receive no cascade.
20. A deprecated Source rejects new candidate Documents, Document activation, and successor proposals.
21. Source metadata correction changes only approved fields, updates timestamp, and audits atomically.
22. Source contains no type, reliability score, Entity, Market, Domain, connector, credential, or content field.
23. Every Source Document requires a valid Source.
24. Source Document UUID is generated and immutable.
25. Source Document scope accepts exactly shared or tenant.
26. Shared Document requires shared Source and null Tenant.
27. Tenant Document may reference a shared Source or same-Tenant Source.
28. Tenant Document cannot reference another Tenant's Source and tenant Source cannot produce shared Document.
29. Document Source, scope, Tenant, identifier, locator identity, predecessor, and creation time are immutable in every lifecycle state.
30. Document identifier bounds and Source-and-ownership-scope-local uniqueness work while null identifiers are allowed and the same identifier may exist for separate Tenant-owned copies of one shared Source.
31. Canonical title is trimmed, 1–500 characters, correctable, non-unique, and not identity.
32. Document description follows common null/trim/non-empty/maximum rules.
33. Locator scheme/value must be both null or both non-null.
34. Locator scheme accepts exactly the approved vocabulary.
35. Locator bounds work, duplicate locator values are allowed, and locator is not identity.
36. Published time is nullable and correctable without changing identity.
37. Language mode accepts exactly unknown, single, or multiple.
38. Single Language requires an active Language; unknown/multiple require null Language.
39. Later Language deprecation preserves Document history and does not cascade lifecycle.
40. Media type bound/regex and nullability work.
41. SHA-256 is null or lowercase 64-hex, can be registered once, and cannot then change.
42. Identical SHA-256 values are allowed for different Documents and are not identity.
43. Access classification accepts exactly public, licensed, tenant-confidential, or restricted.
44. Shared Document rejects tenant-confidential classification.
45. Tenant-private Document scope remains private even when access classification is public.
46. Restriction note follows null/trim/non-empty/maximum rules.
47. Restriction note is optional for every classification, including public, and never grants, overrides, or determines authorization.
48. Document creation always starts candidate.
49. Activation requires active compatible Source and active single Language where applicable.
50. Document lifecycle permits only candidate-active-superseded, candidate-archived, and active-archived.
51. Superseded and archived Documents are terminal.
52. Self-supersession and lineage cycles are rejected.
53. Predecessor and Source must be active and predecessor must have identical Source, scope, and Tenant.
54. At most one candidate successor may reference an active predecessor at one time; a second candidate fails.
55. Successor activation and predecessor supersession occur atomically with deterministic audit.
56. Archiving the candidate successor releases the predecessor proposal position.
57. A superseded predecessor cannot receive another successor proposal.
58. Material revision retains predecessor UUID and creates a distinct successor UUID.
59. No supersession operation moves/deletes content or future references.
60. URL, title, timestamp, and hash do not trigger automatic deduplication.
61. Syndicated and cross-scope copies remain distinct identities.
62. No multiple-locator table or arbitrary locator reference exists.
63. No Market, Geography, Domain, Domain Node, or Entity FK exists on Source/Document.
64. No raw/derived content, storage key, retrieval time, ingestion state, chunk, vector, Evidence, or claim field exists.
65. Candidate metadata correction permits exactly title, description, publication time, Language pair, media type, access classification, and restriction note.
66. Active metadata correction permits exactly title, description, publication time, Language pair, media type, and restriction note.
67. Superseded/archived factual correction permits exactly title, description, publication time, Language pair, media type, and restriction note, updates `updated_at`, and audits atomically.
68. Post-activation access classification mutation is rejected; single-Language correction requires an active Language; identity, locator, predecessor, digest, and lifecycle invariants remain enforced.
69. Anonymous callers cannot read either table.
70. Active-profile authenticated callers read active shared Sources.
71. General authenticated callers read only active public shared Documents.
72. Licensed/restricted shared Documents are absent from ordinary authenticated and membership-based reads; no general entitlement or trusted-reader interface exists.
73. Active Tenant members read active private Sources/Documents in their Tenant.
74. Tenant administrators read non-active governance rows only within their Tenant.
75. Cross-Tenant reads and existence disclosure are denied.
76. Missing, suspended, or revoked membership denies private access immediately.
77. Ordinary authenticated users cannot mutate Source/Document rows.
78. Tenant admins mutate only tenant-private rows in their own Tenant through governed paths.
79. Tenant admins receive no shared/global authority.
80. Trusted platform operations can govern shared records only through narrow administrative paths.
81. Privileged functions use fixed empty search path, qualified references, internal authorization, and least-privilege grants.
82. `PUBLIC` and anonymous execution of privileged mutation functions is denied.
83. Physical deletion is denied through ordinary, tenant-admin, and trusted governed paths.
84. Creation, lifecycle, metadata, digest, and supersession audit events are deterministic and atomic.
85. Failed governed operations leave no successful audit event.
86. New Source resource types are accepted and unknown audit resources remain rejected.
87. No retrieval-specific or Source-specific action code is introduced.
88. Audit metadata remains a bounded JSON object and contains no document content or unrestricted snapshots.
89. Migration 001, Migration 002, Migration 003, and Migration 004 regression suites remain green.
90. Migration 005 structural assertions are scoped to Migration 005-owned objects.
91. Clean replay produces deterministic catalog, constraint, policy, and function structure.
92. Concurrent supersession attempts cannot create two candidate successors or deadlock through inconsistent lock order.
93. Ordinary candidate Document creation succeeds under a compatible candidate Source.
94. Ordinary candidate Document creation succeeds under a compatible active Source.
95. Candidate Document creation under a deprecated Source is rejected.
96. Document activation under a candidate Source is rejected until the Source becomes active.
97. Governed Source metadata correction updates only canonical name, description, or canonical origin URI while Source status is candidate.
98. Governed Source metadata correction updates only canonical name, description, or canonical origin URI while Source status is active.
99. Governed Source metadata correction updates only canonical name, description, or canonical origin URI while Source status is deprecated.
100. Deprecated Source metadata correction preserves deprecated status and never reactivates the Source.
101. Source ID, code, knowledge scope, Tenant, and creation timestamp remain immutable in candidate, active, and deprecated states.
102. Source metadata correction updates `updated_at` and emits the required metadata audit event atomically.

## 19. Atlas and Evidence-governance assessment

| Assumption/control | Migration 005 relationship | Validation effect |
|---|---|---|
| A-028 | Language state is explicit; content normalization is absent | None; cross-language processing remains unvalidated |
| A-029 | Shared/private Source and Document scope is explicit | None; mixed-scope production safety still requires threat-model evidence |
| A-030 | Publication time and supersession lineage preserve minimal history | None; bitemporal requirements remain open |
| A-038 | Exact artifact UUID and optional digest support later representations | None; representation provenance remains unvalidated |
| A-041 | Tenant remains the private ownership boundary | No change to accepted Tenant security rule |
| A-042 | Tenant-private-to-shared promotion remains absent | Low-reversibility disclosure risk remains contained |

The schema enables source validation, citation, publication-date capture, limitation notes, and later reliability assessment, but does not claim any Source is trustworthy or any Document is Evidence. Primary-source preference remains research governance, not Source identity schema.

## 20. SQL-blocker review

M005-D01 through M005-D21 were approved by the BIOS Executive Office on 2026-08-04 and are no longer SQL blockers. DB-006 contains no known unresolved durable SQL architecture decision.

If SQL implementation discovers a material ambiguity not governed by DB-006, implementation must stop and return the matter to the BIOS Executive Office rather than infer or invent architecture. SQL security review, executable testing, and migration replay remain implementation gates rather than architecture blockers.

## 21. Entity-unmerge compatibility

Migration 005 creates no Entity FK, Entity relationship, Entity claim, or dependent Entity structure. Source/publisher association is explicitly deferred. Therefore DB-005's Migration 004 merge/unmerge and historical resolver contract remains unaffected and requires no revalidation or supersession at this gate.

Any later migration adding Source-to-Entity or Document-to-Entity dependency must explicitly re-evaluate DB-005 unmerge before admission.

## 22. Readiness checklist

- [x] Governing documents and Migration 001–004 precedents reviewed.
- [x] Exact two-table recommendation stated.
- [x] Every provisional object classified.
- [x] Source/Document/Evidence boundaries remain distinct.
- [x] Explicit shared/private ownership and compatibility rules stated.
- [x] Lifecycle, correction, revision, locator, and deduplication strategy stated.
- [x] Language, access, RLS, audit, seed, and deletion rules stated.
- [x] Content, retrieval, ingestion, and provenance boundaries stated.
- [x] One hundred two acceptance requirements defined.
- [x] DB-005 Entity-unmerge compatibility assessed.
- [x] M005-D01 through M005-D21 approved by the BIOS Executive Office.
- [ ] SQL security review completed.
- [ ] Executable pgTAP/RLS tests completed.
- [ ] Clean local migration replay completed.

## 23. Recommendation

**DB-006 v1.3 CANONICAL — READY FOR MIGRATION 005 IMPLEMENTATION**

DB-006 is the canonical Migration 005 implementation design. Its architecture decisions are approved; SQL security review, executable pgTAP/RLS tests, and clean Migration 005 replay remain future implementation gates.

## 24. Version history

| Version | Date | Change |
|---|---|---|
| 1.3 | 2026-08-04 | Canonical admission following BIOS Executive Office approval of M005-D01 through M005-D21; no architecture substance changed |
| 1.2 | 2026-08-04 | Final precision clarification of Source status requirements for candidate Document creation and lifecycle-wide Source metadata correction; no architecture boundary change |
| 1.1 | 2026-08-04 | Precision correction of Source deprecation history, restriction-note authority, lifecycle-specific metadata correction, exact candidate-successor cardinality, and licensed/restricted shared read boundary |
| 1.0 | 2026-08-04 | Initial proposed Migration 005 Source & Document Foundation implementation design |
