# DB-007 — BIOS Migration 006 — Evidence & Provenance Foundation

| Field | Value |
|---|---|
| Document ID | DB-007 |
| Version | 1.4 |
| Status | Canonical |
| Effective date | 2026-08-04 |
| Supersedes | DB-007 v1.3 |
| Owner | BIOS Executive Office — Data Architecture and Engineering |
| Document type | Implementation Design Specification |

## 1. Purpose

DB-007 proposes the smallest coherent sixth PostgreSQL/Supabase migration that can preserve the canonical lineage:

```text
Source → Source Document → Evidence → later interpretation → later intelligence → later decisions
```

Migration 006 establishes governed Evidence identity and exact Source Document provenance. It does not create ingestion, content storage, representations, Signals, Patterns, Findings, Recommendations, Decision Contexts, or Decisions.

Evidence is source-grounded material. It is not an analytical conclusion. Audit records who changed BIOS governance state and when; provenance records what artifact supports Evidence and where within that artifact the support is located. Neither substitutes for the other.

DB-007 v1.4 is Canonical. Its approved durable decisions govern Migration 006 SQL implementation.

## 2. Canonical authority and design posture

DB-007 is subordinate to ARCH-001, ARCH-002, DB-001 through DB-006, ADR-001, ENG-001, and CANON-001. Migration 001–005 SQL and tests supply implementation precedent only; they do not authorize architecture by convenience.

The proposal follows these rules:

1. preserve original/source-grounded material separately from interpretation;
2. require explicit, immutable provenance for every Evidence record;
3. prefer one atomic Evidence record per Source Document anchor;
4. never broaden provenance visibility through an Evidence row;
5. preserve historical Evidence when a Source Document is superseded or a Source is deprecated;
6. make substantive changes explicit through supersession after activation;
7. defer representation, ingestion, classification, and intelligence architecture until their own gates;
8. prohibit direct untrusted mutation and physical deletion through governed paths.

## 3. Evidence definition

An Evidence record is a governed, citable, source-grounded unit containing one bounded textual evidence payload and exactly one immutable provenance record pointing to one governed Source Document.

Migration 006 supports two payload semantics:

- `verbatim_excerpt` — a bounded excerpt transcribed from the cited Source Document; and
- `normalized_statement` — a bounded faithful statement derived from the cited material, clearly identified as a transformation rather than a quotation.

Evidence is therefore closest to option C: a governed atomic evidence record containing bounded evidence semantics and an exact source anchor. It may represent an excerpt, observation, or factual statement, but it may not contain strategic implication, trend direction, recommendation, business impact, or another analytical interpretation.

Evidence is not identified by its text. Its UUID is authoritative. Duplicate text is permitted because the same words may occur in distinct documents, scopes, editions, or anchors. Migration 006 performs no semantic deduplication.

Evidence must not be:

- manually entered without a governed Source Document;
- synthesized across multiple Source Documents;
- treated as a generic research note;
- used as a Signal, Pattern, Finding, Recommendation, or Decision;
- inferred from an audit event.

Structured datasets and tenant-provided research are admissible only after each governed artifact has a Source Document identity. One atomic Evidence record cites one Source Document. Cross-document synthesis belongs to later analytical objects.

## 4. Representation sequencing assessment

### 4.1 Recommendation

Adopt outcome A:

```text
Migration 006: Evidence + minimal typed Source Document provenance
Later migration: Representation / extraction / stored-content lineage
```

A Source Document UUID plus a typed, bounded anchor is sufficient for the first manually governed Evidence slice because DB-006 assigns material revisions distinct Source Document UUIDs and preserves historical identity. A document-level citation is valid when the complete artifact is the support; a page, section, line, time, or source-native anchor narrows that citation when the artifact permits it.

### 4.2 Representation gate

Migration 006 does not claim to reconstruct retrieved bytes, parsed text, OCR output, translated text, or model extraction. Before BIOS activates Evidence produced from an automated extraction, stored representation, or multilingual normalization pipeline, a later canonical migration must introduce immutable representation identity and transformation lineage.

Representation must therefore precede automated Evidence ingestion, not manually validated Evidence identity. If the first production workflow requires automated extraction or exact stored-content replay, the implementation sequence must pause after DB-007 and admit the Representation migration before production Evidence activation.

Migration 006 stores no generation-method field and does not claim PostgreSQL can infer whether `evidence_text` was written manually, extracted automatically, translated, normalized by a model, or produced through another Representation-dependent process. Its executable enforcement boundary is the absence of every automated or Representation-aware interface and dependency: no ingestion Evidence writer, extraction/OCR/translation/model activation path, connector-to-Evidence path, `representation_id`, `extraction_run_id`, `model_id`, translation-provenance field, or corresponding lineage function is authorized. The initial mutation surface is only the narrow trusted manual/governed Evidence path. BIOS governance prohibits automated or multilingual-derived Evidence activation until Representation architecture is canonically admitted.

### 4.3 Deferred representation objects

`evidence_representations`, `source_document_representations`, `evidence_versions`, stored-content objects, chunks, OCR outputs, translations, and extraction runs are deferred. Audit metadata and free-form JSON must not emulate them.

## 5. Object classification and exact boundary

| Object | Classification | Reason |
|---|---|---|
| `bios_knowledge.evidence` | REQUIRED IN MIGRATION 006 | Governed Evidence identity, payload, scope, lifecycle, and supersession are required before later interpretation. |
| `bios_knowledge.evidence_provenance` | REQUIRED IN MIGRATION 006 | Provenance must be structural, immutable, source-specific, and distinct from audit. |
| `bios_knowledge.evidence_types` | DEFER | No approved workflow or security behavior requires a registry; payload semantics need only a minimal bounded column vocabulary. |
| `bios_knowledge.evidence_links` | DEFER | Cross-evidence and arbitrary upstream links belong to later constrained analytical provenance. |
| `bios_knowledge.evidence_versions` | NOT AUTHORIZED | Substantive revision uses a new Evidence UUID and explicit supersession; parallel version identity would duplicate governance. |
| `bios_knowledge.evidence_anchors` | NOT AUTHORIZED | The single provenance row already owns one typed anchor; a separate anchor table adds no current cardinality. |
| `bios_knowledge.evidence_representations` | DEFER | Representation and transformation lineage require a separate design gate before automated extraction or multilingual normalization. |

Migration 006 creates exactly two BIOS tables:

1. `bios_knowledge.evidence`
2. `bios_knowledge.evidence_provenance`

It creates zero production rows.

## 6. Explicit exclusions

Migration 006 must not create or add:

- Source, Source Document, Evidence Type, arbitrary Evidence link, or Evidence version duplicates;
- representations, retrievals, ingestion jobs, connectors, storage objects, raw documents, full extracted text, OCR output, chunks, embeddings, or vectors;
- Market, Geography, Domain, Domain Node, Entity, Entity relationship, or classification links;
- Signals, Patterns, Findings, Recommendations, Decision Contexts, Decisions, packs, agents, Client, or Workspace objects;
- confidence, truth, reliability, importance, impact, trend, implication, recommendation, or strategic-score fields;
- arbitrary polymorphic references or unconstrained provenance JSON;
- tenant-private-to-shared promotion;
- hard-coded commercial Evidence examples or business seeds.

## 7. Common conventions

| Concern | Migration 006 rule |
|---|---|
| Primary key | BIOS-generated UUID; immutable and without business meaning |
| Scope | Exactly `shared` or `tenant` |
| Tenant ownership | Null exactly for shared; valid non-null Tenant exactly for tenant |
| Text | Trimmed, non-empty, explicitly bounded |
| Time | `timestamptz`; database-set creation and database-maintained update time |
| Mutation | Narrow governed operations only; no direct untrusted table mutation |
| Physical deletion | Unsupported through governed application paths |
| Production seeds | Zero Evidence and provenance rows |

## 8. `bios_knowledge.evidence`

| Field | Null | Rule |
|---|---:|---|
| `id` | No | Generated UUID primary key; immutable |
| `knowledge_scope` | No | Exactly `shared` or `tenant`; immutable |
| `tenant_id` | Conditional | Null exactly for shared; non-null valid Tenant exactly for tenant; immutable |
| `evidence_text` | No | Trimmed 1–2,000 characters; candidate-correctable; immutable after activation |
| `text_kind` | No | Exactly `verbatim_excerpt` or `normalized_statement`; candidate-correctable; immutable after activation |
| `language_id` | No | Active Migration 002 Language required at creation and activation; candidate-correctable; immutable after activation |
| `access_classification` | No | Exactly `public`, `licensed`, `tenant_confidential`, or `restricted`; governed by Section 11; candidate-correctable; immutable after activation |
| `valid_from` | Yes | Temporal applicability start; candidate-correctable; immutable after activation |
| `valid_to` | Yes | Temporal applicability end; candidate-correctable; must be later than `valid_from` when present |
| `supersedes_evidence_id` | Yes | Immutable predecessor Evidence UUID governed by Section 10 |
| `status` | No | `candidate`, `active`, `superseded`, `rejected`, or `archived`; default candidate |
| `created_at` | No | Database-set; immutable |
| `updated_at` | No | Database-maintained |
| `activated_at` | Yes | Required after activation and retained thereafter |
| `superseded_at` | Yes | Required exactly when superseded |
| `rejected_at` | Yes | Required exactly when rejected |
| `archived_at` | Yes | Required exactly when archived |

Evidence has no direct Source Document, Market, Domain, Entity, Source, Signal, Finding, or Decision FK. Its Source Document dependency is expressed only through its mandatory provenance row.

### 8.1 Payload rules

`verbatim_excerpt` means the stored text is represented as a bounded excerpt from the cited artifact. It is limited to 2,000 characters to support citation while minimizing copyrighted or sensitive content. Migration 006 never stores an entire source artifact.

`normalized_statement` means the text is a faithful governed transformation. It must not be presented as a quotation and must not introduce analysis. The responsible actor and governance transition are captured by audit; future automated transformation method/model lineage requires Representation architecture.

No structured value, unit, numeric confidence, source reliability, truth score, or arbitrary JSON payload is authorized. Structured Evidence requires a later explicit observation/value model rather than stringly typed fields.

### 8.2 Language and time

Language describes `evidence_text`, not necessarily the Source Document as a whole. Later deprecation of the Language record does not cascade or invalidate historical Evidence.

`valid_from` and `valid_to` express the period the source-grounded statement describes. Both may be null for unknown or non-temporal material. `valid_to` cannot exist without `valid_from`. Point-in-time Evidence uses `valid_from` with null `valid_to`. Source publication time remains on Source Document and is not copied. No `observed_at`, `event_time`, `reference_period`, or bitemporal claim is added.

## 9. `bios_knowledge.evidence_provenance`

Each Evidence record must have exactly one provenance row. Each provenance row belongs to exactly one Evidence record. Evidence and Evidence Provenance expose no separate application creation operations. One governed operation creates the Evidence row, creates its one provenance row, and writes the required audit in one transaction. The provenance table's unique, non-null `evidence_id` enforces at most one provenance row; atomic governed creation plus denial of independent creation enforces exactly one for successfully governed Evidence.

No public or trusted `create provenance later` operation is authorized. Direct insert to either table is unavailable to anonymous and authenticated clients. Failed atomic creation leaves neither row and no successful audit event. This invariant requires neither a third table nor a circular foreign key.

| Field | Null | Rule |
|---|---:|---|
| `id` | No | Generated UUID primary key; immutable |
| `evidence_id` | No | Unique immutable Evidence FK; one provenance row per Evidence |
| `source_document_id` | No | Immutable Source Document FK; exactly one Source Document per Evidence |
| `anchor_kind` | No | Exactly `document`, `page`, `section`, `line_range`, `time_range`, or `source_native` |
| `page_start` | Conditional | Positive integer required for `page`; otherwise null |
| `page_end` | Conditional | Null or integer at least `page_start`; only for `page` |
| `section_label` | Conditional | Trimmed 1–300 characters required for `section`; otherwise null |
| `line_start` | Conditional | Positive integer required for `line_range`; otherwise null |
| `line_end` | Conditional | Integer at least `line_start` required for `line_range`; otherwise null |
| `time_start_ms` | Conditional | Non-negative bigint required for `time_range`; otherwise null |
| `time_end_ms` | Conditional | Bigint greater than `time_start_ms` required for `time_range`; otherwise null |
| `source_native_locator` | Conditional | Trimmed 1–500 characters required for `source_native`; otherwise null |
| `created_at` | No | Database-set; immutable |

For `document`, all anchor-detail fields are null. Exactly the fields governed by the selected anchor kind may be populated. Migration 006 performs no format-specific page interpretation, URL-fragment normalization, locator parsing, or arbitrary JSON anchoring.

Provenance is immutable. An incorrect Source Document or material anchor requires rejection/archive of a candidate or a new Evidence UUID that supersedes the active Evidence. Provenance cannot be replaced in place after creation.

## 10. Lifecycle, correction, and supersession

Permitted transitions are:

```text
candidate → active → superseded
candidate → rejected
candidate → archived
active → archived
```

`superseded`, `rejected`, and `archived` are terminal. Reactivation is prohibited. Creation always starts candidate.

Candidate Evidence may correct only `evidence_text`, `text_kind`, `language_id`, `access_classification`, `valid_from`, and `valid_to`. Provenance and identity remain immutable. A candidate is not available to later intelligence.

After activation, material Evidence semantics are immutable. Correcting the text, text kind, language, temporal applicability, access classification, Source Document, or anchor requires a new candidate Evidence UUID with `supersedes_evidence_id`. Candidate successor creation requires an active predecessor, compatible scope/Tenant, and provenance compatible with Section 11. At most one candidate successor may reference an active predecessor at a time. Activating the successor atomically activates it, supersedes the predecessor, and records both audit transitions. Deterministic advisory locking on the predecessor UUID precedes row locking.

Archiving a candidate successor releases the proposal position. A superseded predecessor cannot receive another proposal. Successor chains are allowed; cycles and self-reference are prohibited.

Rejection means validation determined that candidate Evidence must not become active. Rejected Evidence is retained for governance/audit and cannot be reactivated. Archive is an administrative retirement, not a judgment of truth. No ordinary lifecycle transition physically deletes Evidence or provenance.

## 11. Scope, provenance compatibility, and access propagation

Evidence never broadens the visibility of its Source Document.

### 11.1 Scope compatibility

- shared Evidence may derive only from an active shared Source Document classified `public`;
- tenant-private Evidence may derive only from an active shared `public` Source Document or an active same-Tenant private Source Document classified `tenant_confidential`, subject to Section 11.3;
- shared Evidence may never derive from tenant-private, licensed, or restricted Source Documents;
- tenant-private Evidence may never derive from another Tenant's Source Document;
- tenant-private-to-shared promotion is absent;
- provenance scope and ownership are revalidated at creation and activation.

Historical provenance remains valid when the cited Source Document later becomes superseded/archived or its Source becomes deprecated. Those later transitions do not cascade, rewrite, hide by identity, or invalidate existing active/historical Evidence. New candidate Evidence and Evidence activation require an active Source Document and compatible active Source.

### 11.2 Access-classification compatibility

Evidence may be equally or more restrictive than its Source Document, never less restrictive. The exact allowed matrix is:

| Source Document classification | Shared Evidence allowed | Tenant Evidence allowed |
|---|---|---|
| `public` | `public`, `restricted` | `public`, `licensed`, `tenant_confidential`, `restricted` |
| `licensed` | None | `licensed`, `tenant_confidential`, `restricted` |
| `tenant_confidential` | None | `tenant_confidential`, `restricted` |
| `restricted` | None | `restricted` |

`tenant_confidential` and `restricted` are not treated as interchangeable. The table above remains the complete non-broadening classification matrix, but it does not independently authorize a trusted operation to consume a Source Document. Evidence classification becomes immutable after activation.

### 11.3 Trusted Source Document authorization for Evidence mutation

Migration 006 separates technical execution eligibility from business authorization to use a Source Document as provenance. Possession of `service_role` or access to a trusted `SECURITY DEFINER` path satisfies only technical eligibility. It does not confer unrestricted Source Document authority. `actor_identifier`, `correlation_id`, `purpose`, and `target_tenant_id` remain non-authorizing operation context.

For Evidence creation and activation, the complete database-verifiable provenance-authorization predicate is:

```text
trusted execution eligibility
AND canonical Source/Document lifecycle validity
AND canonical scope/access-classification validity
AND database-verifiable provenance authorization
```

Migration 006 admits exactly two provenance-authorization cases:

1. **Shared/public:** an active shared Source Document classified `public`, provided every other DB-006/DB-007 invariant passes. No additional entitlement is required.
2. **Same-Tenant private/tenant-confidential:** an active tenant-private Source Document classified `tenant_confidential`, provided `target_tenant_id` is supplied, identifies the owning Tenant, and the resulting Evidence remains tenant-private for that same Tenant. Tenant ownership equality is the database-verifiable business-authorization predicate. The context value itself is not authority.

Migration 006 rejects shared `licensed` and shared `restricted` Source Documents because no canonical entitlement or trusted-reader mechanism lets PostgreSQL verify service authority to consume them. It also rejects every other unsupported combination, including cross-Tenant private provenance, shared Evidence from private Documents, missing or mismatched required Tenant context, and any attempt to use service-role possession or actor/purpose/correlation context as an access override.

The database never interprets `purpose` text to authorize access. No string match, vocabulary inference, regular expression, or purpose-based ACL is permitted.

Evidence creation from shared licensed or restricted Source Documents requires a future canonical authorization architecture capable of representing and verifying service entitlement or trusted-reader authority. That later architecture may evaluate capabilities, entitlements, service identities, purpose grants, access grants, or another governed mechanism. Migration 006 chooses none of them and creates no entitlement, service-purpose, or trusted-reader structure.

### 11.4 Reads

- anonymous callers read no Evidence or provenance;
- authenticated callers with active BIOS Profiles may read active shared `public` Evidence and its provenance only while the cited Source Document is currently authorized to that caller through the Source Document read contract;
- shared `restricted` Evidence is absent from ordinary authenticated reads;
- active Tenant members may read active tenant-private Evidence and provenance in their Tenant only when the underlying Source Document is also authorized to that Tenant;
- Tenant administrators may additionally read candidate, superseded, rejected, and archived tenant-private governance rows in their own Tenant;
- no Tenant role grants shared restricted, licensed, platform-global, or cross-Tenant access;
- every exposed Evidence/provenance read is the intersection of current Evidence authorization and current cited Source Document authorization;
- if lifecycle, scope, Tenant, or access-classification rules later make the cited Source Document unreadable to an actor, ordinary Evidence RLS must also stop exposing the citing Evidence and provenance to that actor;
- loss of ordinary visibility never deletes, rewrites, invalidates, or changes the status of stored Evidence/provenance rows;
- trusted platform governance may inspect preserved historical rows only through narrow administrative/governance authority;
- nonexistent and unauthorized provenance must remain indistinguishable through exposed paths.

Migration 006 creates no entitlement engine, no general trusted Evidence reader, and no general historical Source Document reader.

## 12. Market, Domain, Entity, and analytical boundaries

Evidence identity and provenance remain independent of Market, Geography, Domain, Domain Node, and Entity. Provenance answers where material came from; classification answers what it concerns. Combining them now would entangle citation identity with provisional ontology and entity resolution.

Later governed evidence-classification or observation structures may link Evidence to these registries. Migration 006 does not add informal UUIDs or JSON substitutes.

Because no Entity FK or Evidence-to-Entity dependency is introduced, DB-005 Entity merge/unmerge behavior remains unaffected and needs no new restriction.

## 13. Creation and validation authority

### 13.1 Capability gap

Migration 001 seeds `analyst`, but its only capabilities concern membership, role assignment, and audit reading. It defines no Evidence authoring or validation capability. Role name alone must not confer power.

DB-007 therefore reports an authorization gap: BIOS cannot safely grant tenant analysts Evidence creation merely because they hold the `analyst` role. It also must not overload `tenant_admin` with research authority.

### 13.2 Migration 006 authority

Until a separate approved capability amendment exists:

- shared Evidence creation, candidate correction, validation, activation, rejection, archive, and supersession are restricted to a named trusted BIOS service/exceptional platform governance path;
- tenant-private Evidence operations are also restricted to that trusted path. A trusted mutation operation may accept `target_tenant_id UUID` only as operation context when Tenant ownership cannot be derived from provenance itself, including tenant Evidence derived from a shared Source Document;
- `target_tenant_id` is never caller authority. Only the trusted platform service/governance execution path may supply it, and ordinary authenticated actors receive no execution grant on Migration 006 mutation functions;
- the trusted function independently validates that the Tenant exists and is active where required, scope/Tenant consistency, Source Document scope and ownership, access-classification compatibility, Source and Document lifecycle, Language, predecessor/successor state, and every other DB-007 invariant;
- for an admitted same-Tenant private `tenant_confidential` Source Document, `target_tenant_id` must equal the Document Tenant; for an admitted shared `public` Source Document it identifies the Tenant for which the trusted platform workflow creates private Evidence;
- shared `licensed`, shared `restricted`, and every other Source Document combination outside Section 11.3 are rejected regardless of service-role possession or operation-context content;
- ordinary members, analysts, viewers, and tenant administrators receive no Evidence mutation authority merely from existing roles;
- trusted-service possession alone does not define business authority: calls require a bounded actor identifier, correlation ID, governed purpose, and atomic audit.

This is deliberately narrower than the expected future workflow. Migration 006 has no database dependency on a nonexistent governed work-item object. A future workflow/capability migration may replace or further constrain trusted Tenant context and may add explicit capabilities such as Evidence authoring and Evidence validation after Executive Office approval. Creation and validation must be independently authorizable; the validator must not be inferred from the creator role.

A trusted process may create or activate Evidence only from a Source Document authorized by the database-verifiable Section 11.3 predicate. Evidence creation is never an indirect Source Document access bypass. `purpose` remains bounded descriptive audit context and is never parsed or interpreted as permission.

### 13.3 Trusted operation context

Every trusted Migration 006 mutation operation—Evidence/provenance creation, candidate correction, activation, rejection, archive, successor proposal, and supersession where applicable—uses one consistent operation-context contract:

| Context | Required | Rule |
|---|---:|---|
| `actor_identifier` | Yes | Reuses the canonical BIOS/DB-002 actor-identifier semantics and maximum 200-character bound. The trusted operation derives and validates trusted execution identity according to established BIOS precedent. Caller-supplied actor identifier is audit attribution only and never authorization. No second actor vocabulary is introduced. |
| `correlation_id` | Yes | Text; trimmed, non-empty, maximum 200 characters; contains no secret or token; has no authorization meaning; recorded only as bounded safe operational/audit context. |
| `purpose` | Yes | Text; trimmed, non-empty, maximum 500 characters; describes the governed operation purpose; contains no Evidence text, Source Document content, secret, or token; has no authorization meaning; recorded only as bounded safe operational/audit context. |
| `target_tenant_id` | Conditional | UUID; optional only when tenant-private operation context is required; supplied only through the trusted platform path; independently validated; never authority. |

All four values are operation context. Their presence, validity, or combination is never sufficient authorization. Authorization derives only from the trusted BIOS execution path and canonical internal validation performed by the `SECURITY DEFINER` operation. No function may authorize merely because context arguments are present or well formed.

These values are function/audit context only. Migration 006 persists none of them as Evidence or provenance business columns, creates no workflow/work-item table, and introduces no role or capability.

## 14. RLS and trusted operations

RLS is mandatory on both tables. Direct mutation by anonymous or authenticated clients is denied. Narrow `SECURITY DEFINER` operations must:

- use fixed empty `search_path` and fully qualified references;
- re-derive profile/service identity and authorization internally;
- require and validate the Section 13.3 actor identifier, correlation ID, and purpose consistently for every trusted mutation;
- accept no caller-supplied Profile, role, membership, or authorization flags;
- accept `target_tenant_id` only on the trusted mutation surface and treat it solely as validated operation context, never authorization;
- validate Evidence, Source Document, Source, scope, Tenant, access classification, Language, lifecycle, predecessor state, and the exact Section 11.3 provenance-authorization predicate;
- lock deterministically for successor operations;
- write governance state and audit atomically;
- expose only least-privilege execution grants;
- revoke execution from `PUBLIC` and deny anonymous callers;
- return no cross-Tenant or unauthorized existence detail.

No direct table insert, update, or delete grant is authorized for ordinary authenticated callers. Ordinary authenticated actors receive no execution access to Migration 006 mutation functions. Trusted functions are mutation interfaces, not content-reader or entitlement APIs. Evidence and provenance are created only by the single atomic governed operation; no independent provenance-creation function exists.

## 15. Audit and provenance separation

Migration 006 reuses only:

- `reference.created`
- `reference.status_changed`
- `reference.metadata_updated`

It adds exactly these audit resource types:

- `evidence`
- `evidence_provenance`

No Evidence-specific action is necessary. Activation, rejection, supersession, and archive are deterministic `reference.status_changed` events. Safe bounded audit metadata may contain `correlation_id`, `purpose`, applicable `target_tenant_id`, predecessor/successor UUIDs, changed-field names, lifecycle `from_status`/`to_status`, and safe reason/context already authorized by BIOS precedent.

Creation of Evidence and its provenance occurs in one transaction and emits deterministic creation audit. Candidate payload correction emits `reference.metadata_updated` with changed field names. Failed operations emit no successful audit event. Audit metadata remains a JSON object within DB-002's 8,192-byte serialized bound. It must not contain `evidence_text`, verbatim excerpts, normalized Evidence payload, Source Document content, unrestricted row snapshots, passwords, tokens, secrets, arbitrary unbounded JSON, or provenance substitutes.

Audit describes governance action. It cannot satisfy the mandatory provenance-row invariant.

## 16. Seed governance

Migration 006 creates zero production Evidence rows and zero provenance rows. No Evidence Type registry or vocabulary seeds are created. Synthetic examples belong only in executable tests.

## 17. Approved design recommendation register

All decisions below are Proposed and require BIOS Executive Office approval.

### M006-D01 — Migration sequence — APPROVED — 2026-08-04

- **Decision:** Whether Representation must precede Evidence.
- **Recommended option:** Create manually governable Evidence and typed Source Document provenance in Migration 006; require a later Representation migration before automated extraction, stored-content reconstruction, OCR, translation, model-generated normalization, or multilingual derivative activation. Enforce this database boundary by exposing no Representation/automation interface or lineage dependency, not by attempting to infer text-generation method.
- **Alternatives:** Representation first; or a combined Evidence/Representation migration.
- **Reason:** Source Document UUID plus bounded typed anchor supports the first human-validated slice without inventing content infrastructure.
- **Coupling/reversibility:** Medium; representation is additive, but automated activation must remain gated.

### M006-D02 — Exact table boundary — APPROVED — 2026-08-04

- **Decision:** Migration-owned tables.
- **Recommended option:** Create exactly `evidence` and `evidence_provenance`.
- **Alternatives:** Evidence alone; add Evidence Types, anchors, links, versions, or representations.
- **Reason:** Two tables preserve governed identity and first-class provenance with no unsupported cardinality.
- **Coupling/reversibility:** Low; later structures are additive.

### M006-D03 — Evidence definition — APPROVED — 2026-08-04

- **Decision:** What one Evidence UUID means.
- **Recommended option:** One atomic bounded textual source-grounded unit with exactly one Source Document provenance row.
- **Alternatives:** Generic claim, free-form note, observation record, or multi-document synthesis.
- **Reason:** Keeps Evidence citable and separate from interpretation.
- **Coupling/reversibility:** High; downstream intelligence will depend on this identity.

### M006-D04 — Payload semantics and bounds — APPROVED — 2026-08-04

- **Decision:** Minimum payload.
- **Recommended option:** Required `evidence_text` of 1–2,000 trimmed characters and `text_kind` of `verbatim_excerpt` or `normalized_statement`; no structured value or score.
- **Alternatives:** Quote only; structured value model; arbitrary JSON; no stored text.
- **Reason:** Supports the first citable slice while bounding copyright/privacy exposure and distinguishing quote from transformation.
- **Coupling/reversibility:** Medium; structured observations remain additive.

### M006-D05 — Provenance cardinality — APPROVED — 2026-08-04

- **Decision:** Number of origins per Evidence.
- **Recommended option:** Exactly one Evidence-to-one Source Document provenance row created with Evidence and audit by one atomic governed operation; unique `evidence_id` enforces at most one, and no independent provenance-creation path exists.
- **Alternatives:** Multiple provenance links or fields directly on Evidence.
- **Reason:** Atomic source-specific Evidence avoids hidden synthesis and preserves simple access propagation.
- **Coupling/reversibility:** Medium; later analytical objects can combine Evidence.

### M006-D06 — Typed anchor model — APPROVED — 2026-08-04

- **Decision:** Exact source anchor representation.
- **Recommended option:** Bounded relational anchor kinds and mutually exclusive typed fields defined in Section 9.
- **Alternatives:** Document-level only; JSON; arbitrary locator; separate anchor table.
- **Reason:** Supports common citation forms without unconstrained JSON or polymorphism.
- **Coupling/reversibility:** Medium; representation-specific anchors may later link additively.

### M006-D07 — Scope and Tenant ownership — APPROVED — 2026-08-04

- **Decision:** Shared/private Evidence.
- **Recommended option:** Explicit shared/tenant scope; admit trusted provenance only from shared/public Documents or same-Tenant private/tenant-confidential Documents; require owning-Tenant equality for the latter; reject cross-Tenant, shared licensed/restricted, and promotion paths.
- **Alternatives:** Tenant-only; shared-only; promotion in Migration 006.
- **Reason:** Matches canonical knowledge-scope rules and prevents provenance leakage.
- **Coupling/reversibility:** High security coupling; future promotion requires a separate gate.

### M006-D08 — Access propagation — APPROVED — 2026-08-04

- **Decision:** Whether Evidence can change provenance visibility.
- **Recommended option:** Apply the complete non-broadening matrix in Section 11.2 and intersect every ordinary Evidence/provenance read with the caller's current authorization to the cited Source Document. Historical retention never grants historical read authority.
- **Alternatives:** Exact inheritance only; independent classification; future entitlement engine.
- **Reason:** Evidence may be more restrictive for governance but never expose inaccessible provenance.
- **Coupling/reversibility:** High security coupling.

### M006-D09 — Evidence lifecycle — APPROVED — 2026-08-04

- **Decision:** States and transitions.
- **Recommended option:** `candidate`, `active`, `superseded`, `rejected`, `archived` with transitions and timestamps in Section 10; terminal historical states and no reactivation.
- **Alternatives:** Candidate/active only; no rejected state; copy Document lifecycle exactly.
- **Reason:** Separates validation rejection from administrative archive while preserving history.
- **Coupling/reversibility:** Medium; downstream use must require active Evidence.

### M006-D10 — Correction and supersession — APPROVED — 2026-08-04

- **Decision:** In-place mutation versus new identity.
- **Recommended option:** Candidate payload correction only; active material semantics immutable; new UUID and atomic supersession for substantive correction.
- **Alternatives:** Version table; unrestricted correction events; fully immutable candidates.
- **Reason:** Historical intelligence must not silently change.
- **Coupling/reversibility:** High provenance coupling.

### M006-D11 — Supersession concurrency — APPROVED — 2026-08-04

- **Decision:** Competing successor proposals.
- **Recommended option:** At most one candidate successor per active predecessor, enforced by partial uniqueness plus deterministic predecessor advisory/row locking.
- **Alternatives:** Multiple proposals; application-only coordination.
- **Reason:** Produces deterministic lineage and avoids race-created forks.
- **Coupling/reversibility:** Low implementation coupling; policy change would need a later migration.

### M006-D12 — Temporal semantics — APPROVED — 2026-08-04

- **Decision:** Minimum Evidence time.
- **Recommended option:** Optional `valid_from` and `valid_to` only, with exact range rules; do not copy Source publication time.
- **Alternatives:** Observed/event/reference-period fields; no Evidence time.
- **Reason:** Supports point/period applicability without premature bitemporality.
- **Coupling/reversibility:** Medium; richer temporal claims remain additive.

### M006-D13 — Language — APPROVED — 2026-08-04

- **Decision:** Language of Evidence payload.
- **Recommended option:** Required active Language for `evidence_text`; immutable after activation; later deprecation non-cascading.
- **Alternatives:** Inherit Document language; nullable language; defer to Representation.
- **Reason:** Normalized statements may differ in language from their Source Document and must be labeled.
- **Coupling/reversibility:** Medium; translated representations remain separate.

### M006-D14 — Evidence Type — APPROVED — 2026-08-04

- **Decision:** Type architecture.
- **Recommended option:** No Evidence Type registry; use only `text_kind` to distinguish verbatim from transformed text.
- **Alternatives:** Registry or broad enum of quote/statistic/claim/observation.
- **Reason:** No workflow/security behavior yet depends on a semantic taxonomy.
- **Coupling/reversibility:** Low; later registry/link is additive.

### M006-D15 — Creation and validation authority — APPROVED — 2026-08-04

- **Decision:** Who may mutate Evidence under the current role model.
- **Recommended option:** Trusted governed service/exceptional platform path only; no role-name authority; report analyst capability gap and defer tenant authoring until explicit capabilities are approved. Apply the bounded operation-context contract consistently, but authorize provenance only through the database-verifiable Section 11.3 cases. Neither trusted-path possession nor any context argument grants unrestricted Source Document authority.
- **Alternatives:** Tenant-admin authoring; analyst role-name grant; new capabilities in Migration 006.
- **Reason:** Current capabilities do not authorize research actions and must not be silently broadened.
- **Coupling/reversibility:** High authorization coupling; a capability migration is required for human authoring.

### M006-D16 — RLS and Source access — APPROVED — 2026-08-04

- **Decision:** Read/mutation enforcement.
- **Recommended option:** Preserve Section 11/14 ordinary RLS and current read intersection; deny anonymous/direct mutation and ordinary authenticated execution; use one atomic Evidence/provenance creation operation; and require narrow fixed-search-path trusted functions to validate operation context plus the exact shared/public or same-Tenant private/tenant-confidential provenance authorization. Shared licensed/restricted provenance is deferred pending canonical entitlement/trusted-reader architecture.
- **Alternatives:** Evidence-only access checks; application-only enforcement; general trusted reader.
- **Reason:** Evidence creation/read must not bypass Source Document restrictions.
- **Coupling/reversibility:** High security coupling.

### M006-D17 — Audit vocabulary — APPROVED — 2026-08-04

- **Decision:** Evidence governance actions/resources.
- **Recommended option:** Reuse three reference actions and add `evidence`/`evidence_provenance` resources; no Evidence-specific action. Permit only the bounded safe operation-context and transition metadata listed in Section 15, subject to DB-002's serialized JSON-object bound and content/secret exclusions.
- **Alternatives:** Validation/rejection/supersession action codes.
- **Reason:** Status metadata already represents deterministic semantic transitions without vocabulary proliferation.
- **Coupling/reversibility:** Low; future actions are additive.

### M006-D18 — Seeds — APPROVED — 2026-08-04

- **Decision:** Production seed rows.
- **Recommended option:** Zero Evidence and provenance seeds.
- **Alternatives:** Example Evidence or Evidence Type seeds.
- **Reason:** Evidence is governed business/research material, not reference seed data.
- **Coupling/reversibility:** Low.

### M006-D19 — Source/Document historical compatibility — APPROVED — 2026-08-04

- **Decision:** Effect of later Source/Document lifecycle changes.
- **Recommended option:** Preserve historical Evidence/provenance without cascade, rewrite, or invalidation; require active compatible Source and Document for new creation/activation; separately require ordinary reads to satisfy the actor's current Source Document authorization. Add no general historical Source Document reader.
- **Alternatives:** Cascade archive, invalidate Evidence, or rewrite to successor Document.
- **Reason:** Historical intelligence must remain reconstructable against the exact artifact originally cited.
- **Coupling/reversibility:** High provenance coupling.

## 18. Numbered executable acceptance-test plan

1. Clean reset succeeds through Migrations 001–006.
2. Exactly the two approved Migration 006 tables exist.
3. Migration 006 structural assertions are ownership-scoped rather than global table-count assertions.
4. Evidence Types, links, versions, anchors, representations, retrievals, ingestion, content, chunks, vectors, Signals, Patterns, Findings, Recommendations, Decision Contexts, Decisions, Client, and Workspace remain absent.
5. Migration 006 creates zero production Evidence and provenance rows.
6. Evidence UUID is generated and immutable.
7. Evidence text is required, trimmed, and bounded at 1–2,000 characters.
8. Evidence text is not unique and does not determine identity.
9. Text kind accepts exactly `verbatim_excerpt` or `normalized_statement`.
10. Evidence has no structured value, unit, confidence, reliability, truth, importance, impact, trend, implication, or recommendation field.
11. Evidence scope accepts exactly shared or tenant.
12. Shared Evidence requires null Tenant and tenant Evidence requires a valid non-null Tenant.
13. Evidence scope and Tenant are immutable.
14. Evidence creation always starts candidate.
15. Every Evidence row is created atomically with exactly one provenance row.
16. A provenance row cannot exist without valid Evidence.
17. An Evidence row cannot complete governed creation without provenance.
18. Provenance UUID, Evidence UUID, Source Document UUID, anchor kind/details, and creation time are immutable.
19. One Evidence UUID cannot have a second provenance row.
20. Every provenance references exactly one valid Source Document.
21. Evidence cannot be created without a Source Document.
22. Evidence cannot cite an audit event as provenance.
23. Shared Evidence can cite an active shared public Source Document.
24. Shared Evidence cannot cite tenant-private Source Documents.
25. Shared Evidence cannot cite licensed or restricted shared Source Documents.
26. Tenant Evidence can cite an active shared public Source Document.
27. Tenant Evidence creation rejects an active shared licensed Source Document because no canonical service entitlement is database-verifiable.
28. Tenant Evidence creation rejects an active shared restricted Source Document because no canonical trusted-reader authority is database-verifiable.
29. Tenant Evidence can cite an active same-Tenant private Source Document classified `tenant_confidential` when required Tenant context matches ownership.
30. Tenant Evidence cannot cite another Tenant's Source Document.
31. Evidence cannot be less restrictive than Source Document provenance under every matrix row.
32. Evidence may be more restrictive only in combinations explicitly listed in Section 11.2.
33. Tenant-private Evidence remains private when classified public.
34. No tenant-private-to-shared promotion operation exists.
35. New Evidence creation rejects a non-active Source Document.
36. Evidence activation rejects a non-active Source Document or incompatible Source.
37. Historical active/superseded Evidence remains attached when its Source Document becomes superseded or archived.
38. Historical Evidence remains attached when its Source becomes deprecated.
39. Source/Document lifecycle changes do not rewrite provenance.
40. Source/Document lifecycle changes do not cascade Evidence status.
41. `document` anchor requires every detail field null.
42. `page` anchor requires positive page start and valid optional page end.
43. `section` anchor requires trimmed 1–300 section label and no unrelated details.
44. `line_range` requires positive ordered start/end lines and no unrelated details.
45. `time_range` requires non-negative ordered millisecond bounds and no unrelated details.
46. `source_native` requires trimmed 1–500 locator and no unrelated details.
47. Anchor kind rejects values outside the six-code vocabulary.
48. Arbitrary anchor JSON and polymorphic reference columns remain absent.
49. Language requires a valid active Language at creation.
50. Evidence activation revalidates active Language.
51. Candidate correction to another Language requires the new Language to be active.
52. Later Language deprecation does not cascade or rewrite historical Evidence.
53. `valid_to` is null unless `valid_from` exists.
54. When both are present, `valid_to` is later than `valid_from`.
55. Point-in-time Evidence accepts `valid_from` with null `valid_to`.
56. Undated Evidence accepts both temporal values null.
57. Source Document publication time is not copied into Evidence identity.
58. Candidate payload correction permits exactly text, text kind, Language, access classification, and validity range.
59. Candidate correction updates `updated_at` and audit atomically.
60. Candidate correction cannot change UUID, scope, Tenant, predecessor, or provenance.
61. Active Evidence payload mutation is rejected.
62. Active Evidence provenance mutation is rejected.
63. Active material correction requires a new Evidence UUID.
64. Candidate-to-active succeeds only through governed validation.
65. Candidate-to-rejected succeeds and records `rejected_at`.
66. Candidate-to-archived succeeds and records `archived_at`.
67. Active-to-archived succeeds and retains `activated_at`.
68. Candidate-to-superseded is rejected.
69. Active-to-rejected is rejected.
70. Superseded, rejected, and archived states are terminal.
71. Reactivation is rejected for every terminal state.
72. Successor proposal requires an active predecessor.
73. Successor scope and Tenant match the predecessor.
74. Self-supersession is rejected.
75. Supersession cycles are rejected.
76. At most one candidate successor references an active predecessor.
77. A concurrent second successor proposal fails deterministically.
78. Successor creation acquires deterministic predecessor advisory lock before row lock.
79. Archiving a candidate successor releases the proposal position.
80. Successor activation atomically activates successor and supersedes predecessor.
81. Atomic supersession records both status timestamps.
82. Atomic supersession emits deterministic audits for both Evidence UUIDs.
83. Failed supersession leaves neither partial lifecycle state nor successful audit.
84. Superseded predecessor cannot receive another successor proposal.
85. Successor chain preserves every historical Evidence UUID and provenance row.
86. Anonymous users cannot read Evidence.
87. Anonymous users cannot read provenance.
88. Active-profile authenticated users read active shared public Evidence only when provenance access is also authorized.
89. Shared restricted Evidence is absent from ordinary authenticated reads.
90. Active Tenant members read active tenant Evidence only in their Tenant and only with authorized provenance.
91. Tenant administrators read non-active governance rows only in their Tenant.
92. Tenant membership does not grant shared licensed/restricted Evidence access.
93. Cross-Tenant Evidence and provenance reads disclose no row existence.
94. Missing, suspended, or revoked membership immediately denies tenant Evidence/provenance.
95. Ordinary members, analysts, viewers, and tenant administrators cannot mutate Evidence under Migration 006 capabilities.
96. Trusted operations validate the canonical bounded actor identifier, required bounded textual correlation ID and purpose, conditional Tenant context, and Source Document access internally without treating context as authorization.
97. Privileged functions use fixed empty search path and fully qualified references.
98. `PUBLIC` and anonymous execution of privileged mutation functions is denied.
99. Direct authenticated table insert, update, and delete are denied.
100. Physical deletion is rejected through governed and direct ordinary paths.
101. Creation emits deterministic `reference.created` audit for Evidence and provenance atomically.
102. Activation, rejection, supersession, and archive reuse `reference.status_changed` with bounded safe metadata.
103. Candidate correction reuses `reference.metadata_updated` and lists changed fields.
104. Audit resource types accept `evidence` and `evidence_provenance` and reject unknown codes.
105. No Evidence-specific audit action code is introduced.
106. Audit metadata remains a JSON object within 8,192 serialized bytes.
107. Audit metadata contains no Evidence text, excerpt, document content, or provenance substitute.
108. Failed governed operations emit no successful audit event.
109. No general entitlement or trusted Evidence reader function exists.
110. No Market, Geography, Domain, Domain Node, or Entity FK exists on either table.
111. No Signal, Pattern, Finding, Recommendation, Decision Context, or Decision field/table is introduced.
112. No representation, extraction, retrieval, storage, content, chunk, vector, or model field/table is introduced.
113. Migrations 001–005 regression suites remain green.
114. Earlier structural tests remain forward-compatible with canonical Evidence/provenance additions.
115. Clean replay produces deterministic tables, constraints, indexes, policies, functions, grants, and audit vocabulary.
116. Shared/private mixed-scope tests demonstrate that Evidence never broadens provenance visibility.
117. Historical-as-of fixtures demonstrate no cascade rewrite after Document supersession and Source deprecation.
118. Migration 006 contains no automated extraction, ingestion Evidence writer, Representation-aware activation, OCR, translation, model-lineage, connector-to-Evidence, or other automation interface/dependency that could serve as an automated Evidence activation path.
119. Only the trusted mutation path may supply `target_tenant_id` when creating or governing tenant-private Evidence.
120. Ordinary authenticated actors have no execute privilege on Migration 006 Evidence mutation functions.
121. Trusted Tenant context is independently validated for Tenant existence, active status where required, scope, ownership, Source/Document lifecycle, access, Language, and predecessor state rather than treated as authority.
122. Tenant Evidence citing a private Source Document rejects a `target_tenant_id` different from the Document Tenant.
123. Tenant Evidence citing a shared Source Document accepts its target Tenant only through validated trusted platform context.
124. Ordinary Evidence/provenance reads disappear when lifecycle, scope, Tenant, or access-classification changes make the cited Source Document unauthorized to that reader.
125. Evidence and provenance rows remain stored, unchanged, and historically valid after the visibility change in requirement 124.
126. Migration 006 introduces no general historical Source Document reader.
127. Every successful governed Evidence creation produces exactly one Evidence row and exactly one provenance row in the same transaction.
128. Failed atomic creation leaves neither Evidence nor provenance and emits no successful audit event.
129. No independently executable provenance-creation operation exists for trusted, authenticated, or anonymous actors.
130. Migration 006 introduces no automated or Representation-aware Evidence activation function, ingestion writer, connector writer, OCR/translation writer, or model-generated extraction path.
131. Neither table nor any Migration 006 function signature contains `representation_id`, `extraction_run_id`, `model_id`, translation lineage, generation method, or equivalent Representation/automation dependency.
132. Every trusted Migration 006 mutation rejects a null `correlation_id`.
133. `correlation_id` rejects empty, whitespace-only, and more-than-200-character values while accepting trimmed non-empty text up to 200 characters.
134. Every trusted Migration 006 mutation rejects a null `purpose`.
135. `purpose` rejects empty, whitespace-only, and more-than-500-character values while accepting trimmed non-empty text up to 500 characters.
136. Well-formed `actor_identifier`, `correlation_id`, `purpose`, and `target_tenant_id` do not authorize an otherwise unauthorized execution path.
137. `actor_identifier` reuses established BIOS governance semantics and rejects values outside the canonical maximum 200-character bound.
138. Successful trusted mutations record safe bounded correlation/purpose context and applicable Tenant/transition identifiers in audit metadata within DB-002's serialized JSON-object bound.
139. Audit metadata excludes Evidence text, verbatim/normalized payload, Source Document content, passwords, tokens, secrets, arbitrary unbounded JSON, and unrestricted row snapshots.
140. `actor_identifier`, `correlation_id`, `purpose`, and `target_tenant_id` are absent as Evidence/provenance business columns and exist only as function/audit context.
141. Trusted execution eligibility or `service_role` possession alone does not authorize every Source Document for Evidence provenance.
142. Trusted Evidence creation from an active shared `public` Source Document succeeds when every remaining lifecycle, scope, Language, anchor, and Evidence invariant passes.
143. Trusted tenant-private Evidence creation from an active same-Tenant private `tenant_confidential` Source Document succeeds when `target_tenant_id` equals Document ownership and every remaining invariant passes.
144. Tenant-private provenance rejects a missing `target_tenant_id` where the trusted operation requires Tenant context.
145. Tenant-private provenance rejects a `target_tenant_id` different from Source Document ownership.
146. Trusted Evidence creation from a shared `licensed` Source Document is rejected.
147. Trusted Evidence creation from a shared `restricted` Source Document is rejected.
148. A valid bounded `purpose` cannot override licensed or restricted Source Document rejection, and purpose text is never interpreted as an ACL or entitlement.
149. A valid `actor_identifier` cannot override licensed, restricted, ownership, scope, or lifecycle rejection.
150. A valid `correlation_id` cannot override licensed, restricted, ownership, scope, or lifecycle rejection.
151. `service_role` possession cannot override licensed, restricted, cross-Tenant, ownership, scope, or lifecycle rejection.
152. Cross-Tenant private provenance remains rejected even when every operation-context value is valid.
153. Migration 006 introduces no entitlement, service-purpose, trusted-reader, service-identity capability, access-grant, role, or capability table/function/column.

Acceptance-test count: **153**.

## 19. SQL-blocker review

M006-D01 through M006-D19 remain approved, including the Executive Office trusted Source Document authorization clarification recorded on 2026-08-04. No known unresolved durable SQL architecture or security decision remains. Migration 006 implementation may proceed against DB-007 v1.4 Canonical. If implementation discovers a new durable ambiguity, implementation must stop and return it to the BIOS Executive Office rather than invent architecture.

Additionally, the following implementation conditions are explicit:

1. The current role/capability model does not authorize analyst or tenant-admin Evidence authoring/validation. Migration 006 can proceed with the recommended trusted-only path, including independently validated `target_tenant_id` operation context, but human tenant authoring requires a separately approved capability design.
2. Automated extraction, stored-content reconstruction, and multilingual derivative Evidence activation require an approved Representation migration. They are outside the first manual Evidence slice.
3. SQL must not invent any additional field, vocabulary, scope rule, anchor type, access ordering, lifecycle transition, authorization path, audit action, or seed.
4. If Executive Office changes provenance cardinality, access propagation, or Representation sequencing, the table/constraint design must be reviewed before SQL begins.
5. Migration 006 must not invent service entitlement, purpose-based authorization, licensed/restricted access, service-identity capability, or trusted-reader authority. Shared licensed/restricted Evidence creation remains deferred.

Human analyst or Tenant Evidence authoring requires a separately approved capability design. Automated extraction, stored-content reconstruction, OCR, translation, model-derived normalization, multilingual-derived Evidence activation, and Representation-aware Evidence workflows require canonical Representation architecture first. These are future capability and architecture gates and do not block the trusted-only manually governed Migration 006 implementation.

## 20. Compatibility assessments

### 20.1 DB-005 Entity unmerge

Migration 006 introduces no Entity FK, Entity classification, or Evidence-to-Entity dependency. Entity merge/unmerge semantics remain unaffected. No DB-005 amendment is required.

### 20.2 DB-006 Source and Document history

Evidence cites the exact Source Document UUID through immutable provenance. Source Document supersession/archive and Source deprecation do not cascade, rewrite, or invalidate historical Evidence. New Evidence creation and activation require active compatible provenance, while historical active/superseded/rejected/archived Evidence retains its original Source Document link. Retention and validity are distinct from visibility: ordinary readers see the Evidence/provenance only while they remain currently authorized to read the cited Source Document. Trusted governance may inspect preserved history through narrow authority; Migration 006 adds no general historical reader.

This preserves DB-006 material-revision identity: a new Source Document UUID does not silently replace the artifact that supported earlier Evidence. If the new publication changes the evidentiary material, BIOS creates new Evidence and uses Evidence supersession where applicable.

## 21. Readiness checklist

- [x] Canonical authorities and Migration 001–005 precedent reviewed.
- [x] Smallest coherent table boundary proposed.
- [x] Evidence and analytical interpretation separated.
- [x] Provenance and audit separated.
- [x] Representation sequencing explicitly assessed.
- [x] Shared/private and access non-broadening rules proposed.
- [x] Analyst-authority gap explicitly reported.
- [x] Lifecycle, correction, supersession, and concurrency proposed.
- [x] 153 executable acceptance requirements defined.
- [x] M006-D01 through M006-D19 approved by BIOS Executive Office.
- [ ] Analyst/human authoring capability admitted, if required for the first production workflow.
- [ ] Representation migration admitted before automated or multilingual-derived Evidence activation.
- [ ] SQL security review completed.
- [ ] Executable pgTAP/RLS tests completed.
- [ ] Clean Migration 006 replay completed.

## 22. Recommendation

**DB-007 v1.4 CANONICAL — READY TO RESUME MIGRATION 006 IMPLEMENTATION**

## 23. Version history

| Version | Date | Change |
|---|---|---|
| 1.4 | 2026-08-04 | Migration 006 trusted Source Document authorization clarified to admit only shared/public and same-Tenant tenant-private/tenant-confidential provenance; shared licensed/restricted Evidence creation deferred pending canonical entitlement/trusted-reader architecture; no table-boundary change |
| 1.3 | 2026-08-04 | Canonical approval of M006-D01 through M006-D19; Evidence & Provenance Foundation admitted for Migration 006 implementation |
| 1.2 | 2026-08-04 | Final precision definition of trusted Evidence mutation operation context and bounded audit metadata; no architecture or table-boundary change |
| 1.1 | 2026-08-04 | Final precision clarification of trusted Tenant context, historical provenance visibility, atomic exactly-one provenance creation, and Representation/automation enforcement boundary; no table-boundary change |
| 1.0 | 2026-08-04 | Initial Proposed implementation design for Migration 006 Evidence & Provenance Foundation |
