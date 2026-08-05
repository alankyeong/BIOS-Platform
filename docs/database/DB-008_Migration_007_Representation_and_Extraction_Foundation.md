# DB-008 — BIOS Migration 007 — Representation & Extraction Foundation

| Field | Value |
|---|---|
| Document ID | DB-008 |
| Version | 1.2 |
| Status | Canonical |
| Effective date | 2026-08-05 |
| Supersedes | DB-008 v1.1 |
| Owner | BIOS Executive Office — Data Architecture and Engineering |
| Document type | Implementation Design Specification |

## 1. Purpose

DB-008 proposes the smallest durable Representation and processing-lineage layer required before BIOS can later admit automated Evidence generation. It preserves the separation:

```text
Source Document → Representation → Processing lineage → later Evidence integration
```

A Source Document governs an external publication or artifact. A Representation is an immutable, bounded, machine-consumable textual rendition of that artifact or another Representation. A Processing Run records how one Representation was produced. Evidence remains the atomic source-grounded unit governed by DB-007.

Migration 007 does not authorize automated Evidence activation. It creates no ingestion orchestrator, connector, binary object store, segment/chunk registry, embedding, Signal, Pattern, Finding, or decision object.

DB-008 v1.2 is Canonical. M007-D01 through M007-D20 were approved by the BIOS Executive Office on 2026-08-05 and govern Migration 007 implementation.

## 2. Canonical dependencies

DB-008 is subordinate to ADR-001, ARCH-001, ARCH-002, DB-001 through DB-007, ENG-001, and CANON-001. It extends the implemented Migration 001–006 boundary and adopts established PostgreSQL/Supabase conventions for UUID identity, explicit shared/tenant scope, immutable ownership, lifecycle timestamps, RLS, narrow trusted functions, fixed empty `search_path`, deterministic locking, bounded audit metadata, and forward-compatible ownership-scoped regression tests.

The following earlier decisions remain unchanged:

- DB-006 Source Document UUID is the governed artifact identity; material publication revisions receive distinct UUIDs.
- DB-007 Evidence remains directly and historically linked to Source Document through exactly one provenance row.
- Shared licensed/restricted Source Document use lacks canonical service entitlement/trusted-reader authorization.
- Operation context is not authority, and `service_role` possession alone is not business authorization.
- Representations are versioned derivatives; they do not replace original/source-grounded identity.

## 3. Current-state assessment

Migration 006 implements `bios_knowledge.evidence` and `bios_knowledge.evidence_provenance` without Representation dependencies. It deliberately exposes no automated Evidence writer or Representation-aware activation path. Existing Evidence therefore remains valid and must not be rewritten.

The database currently has no durable identity for extracted, OCR, normalized, translated, or transcribed text and no first-class record of the processing execution that produced it. Audit cannot fill either role: audit records governance action, not content lineage or process execution.

Migration 007 must establish those two missing durable identities without pretending to solve acquisition, binary storage, orchestration, entitlement, segmentation, retrieval, vectorization, or Evidence integration.

## 4. Migration boundary and object classification

Migration 007 creates exactly two BIOS tables:

1. `bios_knowledge.document_representations`
2. `bios_knowledge.processing_runs`

| Candidate structure | Classification | Reason |
|---|---|---|
| `bios_knowledge.document_representations` | REQUIRED IN M007 | Gives immutable identity to bounded machine-consumable textual content and its root Source Document. |
| `bios_knowledge.processing_runs` | REQUIRED IN M007 | Processing execution has independent outcome, timing, reproducibility, and failure semantics; it cannot be reduced to audit metadata. |
| `bios_knowledge.representation_lineage` | REJECTED IN M007 | One input and one output are sufficient; root Source Document plus optional parent self-reference preserve a deterministic chain without a general DAG. |
| `bios_knowledge.representation_segments` | DEFERRED | No M007 consumer requires durable reusable segment identity; later Evidence/vector requirements must justify it. |
| Representation-type registry | REJECTED IN M007 | A bounded vocabulary has direct invariant behavior and needs no seeded registry identity. |
| Model/provider/pipeline/prompt registries | DEFERRED | Bounded run metadata is sufficient for the first reproducibility slice; registry governance awaits repeated operational need. |
| Binary/object-storage registry | DEFERRED | M007 stores bounded textual derivatives only and does not establish acquisition/storage infrastructure. |
| Evidence/Representation integration table | DEFERRED | Automated Evidence activation requires a separate explicit DB-007 integration gate. |

Migration 007 creates zero production Representation rows and zero production Processing Run rows.

## 5. Representation model

A Representation is one immutable textual output produced by one successful Processing Run from exactly one input: either a Source Document or a parent Representation. It always records the root Source Document directly for authorization and historical lookup.

### 5.1 `bios_knowledge.document_representations`

| Field | Null | Rule |
|---|---:|---|
| `id` | No | BIOS-generated UUID primary key; immutable |
| `source_document_id` | No | Immutable root Source Document FK |
| `parent_representation_id` | Yes | Immutable direct parent FK; null exactly when the run input is the Source Document |
| `producing_run_id` | No | Unique immutable Processing Run FK; one output Representation per successful run |
| `knowledge_scope` | No | Exactly `shared` or `tenant`; immutable |
| `tenant_id` | Conditional | Null exactly for shared; valid non-null Tenant exactly for tenant; immutable |
| `representation_kind` | No | Exact vocabulary in Section 5.2; immutable |
| `language_id` | No | Active canonical Language required at creation/activation; immutable |
| `media_type` | No | Exact M007 textual media vocabulary in Section 5.3; immutable |
| `content_text` | No | Non-empty textual content; immutable; maximum 1,048,576 UTF-8 serialized bytes |
| `content_sha256` | No | Lowercase 64-hex SHA-256 verified by PostgreSQL against UTF-8 `content_text`; immutable; integrity metadata and deduplication aid, not identity or unique |
| `access_classification` | No | `public`, `licensed`, `tenant_confidential`, or `restricted`; compatible with root/parent; immutable |
| `supersedes_representation_id` | Yes | Immutable predecessor FK governed by Section 12 |
| `status` | No | `candidate`, `active`, `superseded`, or `archived`; default candidate |
| `created_at` | No | Database-set; immutable |
| `updated_at` | No | Database-maintained for lifecycle changes only |
| `activated_at` | Yes | Required after activation and retained thereafter |
| `superseded_at` | Yes | Required exactly when superseded |
| `archived_at` | Yes | Required exactly when archived |

Representation UUID—not content hash—is BIOS identity. Identical text and digest may legitimately exist across Source Documents, scopes, languages, methods, or runs. Migration 007 performs no automatic deduplication or merge.

### 5.2 Representation-kind vocabulary

Migration 007 permits exactly:

- `extracted_text`
- `ocr_text`
- `transcript`
- `normalized_text`
- `translated_text`

The first three may be produced directly from a Source Document. `normalized_text` and `translated_text` require a parent Representation. No free-text `other` kind is authorized. New kinds require an additive migration.

Source Document remains the original/acquired artifact identity. M007 Representations are derived textual renditions; M007 does not create an `original_binary` Representation or duplicate acquired content.

### 5.3 Textual media vocabulary

Migration 007 permits exactly:

- `text/plain`
- `text/markdown`
- `text/html`

`application/json` and every other structured or arbitrary media type are rejected. M007 is a textual Representation foundation, not a structured-output architecture.

## 6. Content and storage model

Migration 007 adopts a deliberately bounded PostgreSQL textual-content strategy.

- `content_text` stores the exact UTF-8 textual Representation used for integrity and later deterministic coordinates.
- Serialized UTF-8 size is limited to 1,048,576 bytes per Representation.
- PostgreSQL verifies `content_sha256` against the stored UTF-8 bytes.
- Content is immutable from creation onward; correction produces a new run and Representation UUID.
- The 1,048,576-byte threshold is an M007 operational PostgreSQL storage bound, not a permanent BIOS Representation limit.
- Content above the bound is rejected through governed completion: before any Representation insert, the Processing Run transitions to `failed` with `error_code = content_too_large`, no Representation is created, and the optional safe summary contains no content.
- Content must never be silently truncated, summarized, split, semantically compressed, re-encoded into altered meaning, or otherwise changed merely to fit the limit.
- Large text, binary PDFs, images, audio/video, downloaded HTML bytes, and other acquired artifacts are outside M007.

This is not a permanent rejection of object storage. A later acquisition/storage design may use a private Supabase Storage bucket or another governed store with immutable object identity, digest verification, Tenant isolation, retention, and backup rules. M007 does not create a bucket, storage path field, object FK, upload interface, or hybrid locator because doing so would introduce an unapproved storage lifecycle and cross-system atomicity contract.

The bounded PostgreSQL choice supports the minimum extracted/OCR/transcript/normalized/translated textual slice while keeping original artifact storage separate. Representations exceeding the byte bound cannot be registered in M007 and require later object-storage/segmentation architecture; altering the material to evade the bound is prohibited.

## 7. Representation lineage

Lineage is a single-parent chain, not a general graph:

```text
Source Document → Representation A → Representation B → Representation C
```

Every Representation stores its immutable root `source_document_id`. A direct Source Document output has null `parent_representation_id`; a derived output has exactly one parent. The producing run records the same input. Database constraints/trusted validation require:

- direct output: run `input_source_document_id` equals Representation root and run `input_representation_id` is null;
- derived output: run `input_representation_id` equals Representation parent, run source input is null, and parent root Source Document equals output root;
- scope/Tenant and access classification remain compatible across every edge;
- parent and predecessor are distinct concepts: parent records derivation input; predecessor records replacement of the same governed rendition role;
- self-parenting and lineage cycles are prohibited;
- new derived processing requires an active parent and active root Source Document/Source;
- historical lineage remains stored when a parent, root Document, or Source later becomes non-active; no cascade rewrite occurs.

One parent is sufficient because M007 transformations operate on one input rendition. Multi-input combination is analytical synthesis or a future specialized processing design and is not authorized.

## 8. Processing and extraction model

A Processing Run is the immutable execution record for one attempted operation. It is not a job queue, retry controller, scheduler, audit event, or Representation.

### 8.1 `bios_knowledge.processing_runs`

| Field | Null | Rule |
|---|---:|---|
| `id` | No | BIOS-generated UUID primary key; immutable |
| `input_source_document_id` | Conditional | Source Document FK; exactly one input with `input_representation_id` |
| `input_representation_id` | Conditional | Representation FK; exactly one input with `input_source_document_id` |
| `knowledge_scope` | No | Exactly `shared` or `tenant`; immutable |
| `tenant_id` | Conditional | Null exactly for shared; valid non-null Tenant exactly for tenant; immutable |
| `operation_kind` | No | `extract_text`, `ocr`, `transcribe`, `normalize`, or `translate` |
| `processor_identifier` | No | Trimmed 1–200; stable code/name for implementation, service, or model pipeline; immutable; not authorization |
| `processor_version` | No | Trimmed 1–100; immutable |
| `model_identifier` | Yes | Trimmed 1–200 when a model participates; immutable; not a registry FK |
| `model_version` | Yes | Null exactly when `model_identifier` is null; otherwise trimmed 1–100; immutable |
| `parameters` | No | Flat JSON object, default `{}`, maximum 8,192 serialized bytes; immutable; keys/values governed below |
| `actor_identifier` | No | Canonical DB-002 semantics, maximum 200; immutable execution attribution, not authority |
| `correlation_id` | No | Trimmed 1–200 text; immutable operational correlation, not authority |
| `purpose` | No | Trimmed 1–500 safe governed purpose; immutable, not authority or content |
| `outcome` | No | `running`, `succeeded`, `failed`, or `cancelled`; default running |
| `error_code` | Conditional | Null except failed; failed requires trimmed 1–100 bounded code |
| `error_summary` | Conditional | Null except failed; optional trimmed 1–500 safe summary; no source/representation content or secrets |
| `started_at` | No | Database-set; immutable |
| `completed_at` | Conditional | Null while running; required for every terminal outcome |

### 8.2 Operation/input/output rules

- `extract_text`, `ocr`, and `transcribe` require a Source Document input and produce respectively `extracted_text`, `ocr_text`, or `transcript`.
- `normalize` and `translate` require a Representation input and produce respectively `normalized_text` or `translated_text`.
- a running run has no output Representation;
- successful completion atomically creates exactly one candidate Representation and marks the run succeeded;
- failed/cancelled completion creates no Representation;
- a run is terminal after succeeded, failed, or cancelled;
- retry is a new run UUID; no attempt counter or mutable rerun;
- only succeeded runs have an output, enforced by unique `producing_run_id` plus governed atomic completion;
- failure belongs to Processing Run; no failed Representation row is created.

`processing_runs` intentionally contains no `output_representation_id`. The canonical output relation is the reverse FK `document_representations.producing_run_id`, which is required and unique. The trusted successful-completion operation inserts exactly one candidate Representation and transitions the Run from running to succeeded in one transaction. Failure of either change rolls back both. Failed/cancelled completion inserts no Representation. There is no independent `attach output later` interface, so a successfully governed succeeded Run has exactly one reverse-related Representation while a failed/cancelled Run has zero, without duplicating the relationship in both tables.

### 8.3 Reproducibility boundary

Processor, version, optional model identity/version, and bounded parameters record the minimum durable method context. `parameters` is a flat JSON object: every key is 1–64 lowercase characters matching `^[a-z][a-z0-9_]*$`; every value is a JSON string, number, boolean, or null; nested objects and arrays are rejected. The following keys are prohibited exactly: `password`, `passwords`, `token`, `tokens`, `secret`, `secrets`, `credential`, `credentials`, `api_key`, `api_keys`, and `authorization`. String values are limited to 500 characters. This is deterministic structural minimization, not a claim that PostgreSQL can semantically detect every secret.

M007 creates no model, provider, pipeline, prompt, tool, or configuration registry. It stores no prompt text, credentials, tokens, raw provider response, logs, or unrestricted snapshots through governed paths. If registry identity becomes necessary for reproducibility or approval, a later migration adds it without rewriting runs.

M007 does not orchestrate execution. An external trusted worker may start and complete runs through narrow governed operations, but queues, leases, heartbeats, retries, schedules, webhooks, connector state, and ingestion attempts are deferred.

## 9. Segmentation and coordinate model

Representation segments/chunks are deferred. M007's immutable `content_text` provides deterministic byte/character content and digest, while DB-007 already supports Source Document anchors. A later Evidence integration may add typed Representation coordinates or stable segments after retrieval/citation requirements are known.

M007 creates no chunk UUID, passage table, page map, token range, embedding range, or vector projection. Character offsets must not be placed into audit metadata or arbitrary JSON as a substitute. Segment identity requires its own canonical gate if reusable chunks become necessary.

## 10. Scope, Tenant, and Source authorization

Representation never broadens root Source Document authorization. Trusted processing is admitted only for the same two database-verifiable provenance cases established by DB-007 v1.4:

1. active shared Source and active shared Source Document classified `public`; or
2. active same-Tenant private Source and Source Document classified `tenant_confidential`, with an active matching `target_tenant_id` and tenant-private output.

Shared `licensed` and shared `restricted` processing are rejected. M007 creates no entitlement, service-purpose, trusted-reader, service-identity capability, or access-grant architecture. Tenant-private Source Documents outside the admitted same-Tenant `tenant_confidential` case are rejected.

Scope derivation rules are:

- shared Representation/Run may originate only from shared/public Source Document or shared/public parent Representation;
- tenant Representation/Run may originate from shared/public input using a validated active target Tenant, or from same-Tenant private/tenant-confidential input;
- tenant output from shared input remains tenant-private even if classified public;
- shared output may never derive from tenant-private input;
- cross-Tenant input/output is prohibited;
- child access classification may be equal or more restrictive under the DB-007 non-broadening matrix, never less restrictive;
- root Source Document authorization is revalidated at run creation and successful completion;
- `service_role`, actor, correlation, purpose, processor, model, and Tenant context do not independently authorize content use.

For shared/public input to tenant-private output, M007 reuses DB-007's approved platform-governed targeting precedent. Only the narrow trusted BIOS platform operation may choose an active `target_tenant_id`; ordinary authenticated or Tenant-directed execution receives no mutation grant. Executive Office approval of M007-D11 authorizes that operation's limited business purpose: create a tenant-private derivative of universally admitted shared/public material for the independently validated active Tenant. The UUID alone confers nothing, and the function must reject non-active/nonexistent Tenants, any non-public shared input, and every scope or lifecycle mismatch. M007 does not represent Tenant consent, delegated tenant authority, entitlement, or a general targeting capability.

## 11. Language semantics

Every Representation has exactly one active canonical Language at creation and activation.

- direct `extract_text`, `ocr`, or `transcribe` from a Source Document with `language_mode = single` must use that Document's `language_id`;
- for an `unknown` or `multiple` Source Document, the trusted process must supply an active output Language determined by the governed processing result;
- `normalize` requires output Language equal to parent Language;
- `translate` requires output Language different from parent Language;
- parent lineage supplies translation source Language; no duplicated `source_language_id` is stored;
- later Language deprecation does not cascade or rewrite historical Representations/Runs;
- language is immutable because changing it changes material Representation semantics.

## 12. Lifecycle, immutability, and supersession

### 12.1 Representation lifecycle

```text
candidate → active → superseded
candidate → archived
active → archived
```

Superseded and archived are terminal; reactivation is prohibited. A Representation is born candidate only through successful atomic run completion. Candidate activation revalidates run outcome, root Source/Document, parent, Language, scope, access, digest, and lineage.

Representation content, digest, kind, media type, Language, root, parent, producing run, scope, Tenant, predecessor, and creation time are immutable in every state. There is no in-place content or material metadata correction. Incorrect output is archived and reproduced through a new run/UUID.

### 12.2 Supersession

A replacement Representation may identify one `supersedes_representation_id`. The exact supersession compatibility key is `source_document_id`, `representation_kind`, `language_id`, `knowledge_scope`, and `tenant_id`. The predecessor must be active and match every key component. `parent_representation_id` is deliberately excluded: a later rendition may replace the same governed role while deriving from a different valid active parent, provided root lineage and every other compatibility/security invariant pass. At most one candidate successor may reference a predecessor. Deterministic predecessor advisory locking precedes row locking. Activating the successor atomically supersedes the predecessor and audits both transitions. Archiving a candidate releases the proposal position. Self-reference, cycles, forks, and reusing a superseded predecessor are prohibited.

Derivation parentage and replacement identity are distinct. Existing parent lineage never changes; a new normalized/translated result may derive from the same or a different valid active parent while retaining exact root and processing lineage.

### 12.3 Processing Run lifecycle

```text
running → succeeded
running → failed
running → cancelled
```

All terminal states are immutable. Failed/cancelled runs retain safe execution metadata for reproducibility and operations but create no Representation. A succeeded run cannot be failed, cancelled, or reused. Physical deletion is unsupported through governed paths for either table.

## 13. Evidence compatibility and automation gate

Migration 007 does not modify `bios_knowledge.evidence` or `bios_knowledge.evidence_provenance`. Existing manually governed Evidence continues to cite Source Document exactly as created under DB-007.

M007 also does not authorize automated Evidence creation or activation. It creates no Evidence writer, no Representation-to-Evidence FK, no processing-run field on Evidence/provenance, and no Representation-aware Evidence activation function.

A later canonical migration must explicitly define the additive integration by which automated Evidence cites:

```text
Source Document → Representation → Processing Run → Evidence
```

That gate must decide whether to extend Evidence provenance or introduce a constrained link, define Representation coordinates/segments, preserve exactly-one Source Document provenance, apply Source authorization, and distinguish automation from manual governance. M007 does not choose that contract.

## 14. Security and RLS

RLS is mandatory on both tables.

- anonymous callers read neither table;
- ordinary authenticated callers receive no direct mutation privileges;
- active-profile callers may read active shared Representations only when classification is `public` and the root Source Document is currently readable under DB-006;
- active Tenant members may read active tenant Representations in their Tenant only while the root Source Document remains currently authorized to that Tenant;
- Tenant administrators gain no processing/mutation power and no global/shared authority merely from role;
- ordinary readers do not read Processing Runs; execution metadata remains trusted governance/operations data in M007;
- historical Representation retention does not grant broader ordinary Source Document access;
- no cross-Tenant existence disclosure is permitted.

Trusted functions use `SECURITY DEFINER`, fixed empty `search_path`, fully qualified objects, internally derived trusted execution eligibility, canonical Source authorization, least grants, `PUBLIC` revocation, and atomic audit. Context, service-role possession, processor/model identifiers, and purpose never substitute for authorization.

M007 creates no general content reader, historical Source Document reader, licensed/restricted reader, entitlement bypass, or storage fetch API.

## 15. Trusted operations

The minimum governed mutation surface conceptually provides:

1. start Processing Run;
2. complete Run successfully and atomically create one candidate Representation;
3. complete Run as failed or cancelled without Representation;
4. activate or archive a Representation;
5. activate a successor and atomically supersede its predecessor.

Every operation consistently requires canonical actor identifier, textual correlation ID, and bounded purpose under DB-007 rules. Tenant processing conditionally requires `target_tenant_id`. These values and processor/model metadata are context/lineage, never authorization.

No direct Representation creation, separate `attach output later`, arbitrary parent-link mutation, lifecycle mutation, or physical delete operation is authorized. Ordinary authenticated actors receive no execute grant on M007 mutation functions. A future capability migration may admit analyst/operator workflows.

## 16. Audit, lineage, and execution separation

- **Audit** answers who changed governed state and when.
- **Lineage** connects root Source Document, parent Representation, producing Run, and output Representation.
- **Execution** records operation, processor/model context, parameters, timing, outcome, and safe failure classification.

Migration 007 reuses `reference.created`, `reference.status_changed`, and `reference.metadata_updated` only where semantically applicable and adds audit resource types:

- `document_representation`
- `processing_run`

Run start and Representation creation use `reference.created`. Run completion and Representation lifecycle use `reference.status_changed`. Because material Representation and run definition fields are immutable, M007 does not need a general metadata-update operation.

Audit metadata remains a JSON object within DB-002's 8,192-byte serialized bound and may contain bounded correlation, purpose, target Tenant, operation kind, run/Representation/predecessor/successor UUIDs, changed lifecycle states, outcome, and safe error code. It contains no Representation content, Source Document content, parameters snapshot, model response, prompt, credentials, tokens, secrets, stack trace, or unrestricted row snapshot.

Processing parameters belong on the immutable Run record, not in audit. Lineage belongs in relational FKs, not in audit or arbitrary JSON.

## 17. Deferred and prohibited structures

Deferred:

- acquired binary/object storage and storage-object identity;
- large/out-of-row textual Representation storage;
- retrieval/acquisition attempts, connectors, queues, schedules, leases, retries, and orchestration;
- Representation segments, chunks, page maps, token/character coordinate registries;
- model, provider, pipeline, prompt, tool, and configuration registries;
- multi-input/many-to-many Representation lineage;
- automated Evidence integration and Representation-aware Evidence provenance;
- human processing/operator capabilities;
- licensed/restricted service entitlement or trusted-reader authority;
- embeddings, vector indexes, semantic retrieval, and derived search projections.

Prohibited in M007:

- Signals, Patterns, Findings, Insights, Recommendations, Decision Contexts, Decisions, intelligence products, importance, implication, or business-impact fields;
- general DAG/polymorphic lineage, arbitrary content/lineage JSON, and free-text Representation kinds;
- production Representation or Processing Run seeds.

## 18. Approved decision register

M007-D01 through M007-D20 are **APPROVED — 2026-08-05**.

### M007-D01 — Exact table boundary

- **Decision:** Create exactly `document_representations` and `processing_runs`.
- **Rationale:** Representation and execution have independent durable identity; lineage fits direct FKs.
- **Alternatives:** One table; add lineage/segment/storage registries.
- **Consequences:** Small boundary; later extensions additive.
- **Status:** APPROVED — 2026-08-05.

### M007-D02 — Textual content storage

- **Decision:** Store immutable UTF-8 text in PostgreSQL, bounded at 1,048,576 bytes; defer binary/large object storage.
- **Rationale:** Enables deterministic initial textual processing without inventing storage lifecycle.
- **Alternatives:** Supabase Storage; hybrid; metadata-only.
- **Consequences:** Large outputs rejected until later storage gate.
- **Status:** APPROVED — 2026-08-05.

### M007-D03 — Representation identity and digest

- **Decision:** UUID is identity; required verified SHA-256 is integrity/deduplication metadata and non-unique.
- **Rationale:** Hash equality does not establish governance identity.
- **Alternatives:** Hash identity; optional digest.
- **Consequences:** Duplicate content remains representable and traceable.
- **Status:** APPROVED — 2026-08-05.

### M007-D04 — Representation-kind vocabulary

- **Decision:** Use the five-code CHECK vocabulary in Section 5.2; no registry or `other`.
- **Rationale:** Each kind has executable input/language behavior.
- **Alternatives:** Registry; free text; broader enum.
- **Consequences:** New kind requires additive migration.
- **Status:** APPROVED — 2026-08-05.

### M007-D05 — Textual media vocabulary

- **Decision:** Permit exactly `text/plain`, `text/markdown`, and `text/html`; reject `application/json` and other structured/arbitrary media.
- **Rationale:** Keeps content contract deterministic and textual.
- **Alternatives:** General IANA media regex; text/plain only.
- **Consequences:** Other formats await storage/content extension.
- **Status:** APPROVED — 2026-08-05.

### M007-D06 — Single-parent lineage

- **Decision:** Store root Source Document and optional single parent directly on Representation; no lineage table.
- **Rationale:** M007 transformations take one input and do not justify a DAG.
- **Alternatives:** Many-to-many lineage; Source Document only.
- **Consequences:** Multi-input synthesis remains prohibited.
- **Status:** APPROVED — 2026-08-05.

### M007-D07 — First-class Processing Run

- **Decision:** Create durable runs with one input, execution identity, timing, and outcome; represent the sole successful output only through unique reverse FK `document_representations.producing_run_id`, with no duplicated output FK on Run.
- **Rationale:** Failure/reproducibility semantics cannot live in audit or Representation.
- **Alternatives:** Audit-only; fields on Representation.
- **Consequences:** Adds one table but avoids orchestration scope and inconsistent bidirectional output references.
- **Status:** APPROVED — 2026-08-05.

### M007-D08 — Processing metadata

- **Decision:** Store bounded processor/model identifiers/versions and bounded JSON-object parameters; defer registries.
- **Rationale:** Minimum reproducibility without premature control-plane tables.
- **Alternatives:** Registries now; no method metadata.
- **Consequences:** Registry normalization may be additive later.
- **Status:** APPROVED — 2026-08-05.

### M007-D09 — Operation mapping

- **Decision:** Apply the exact operation/input/output-kind mapping in Section 8.2.
- **Rationale:** Prevents arbitrary or ambiguous output semantics.
- **Alternatives:** Free combinations; general `other` operation.
- **Consequences:** New processing modes require migration.
- **Status:** APPROVED — 2026-08-05.

### M007-D10 — Segmentation

- **Decision:** Defer segments/chunks and arbitrary coordinate fields.
- **Rationale:** No admitted M007 consumer requires durable chunk identity.
- **Alternatives:** Segment table now; offsets on Representation.
- **Consequences:** Later Evidence/vector integration must admit coordinates explicitly.
- **Status:** APPROVED — 2026-08-05.

### M007-D11 — Scope and Tenant derivation

- **Decision:** Enforce Section 10 shared/private derivation and root ownership compatibility. Permit shared/public-to-tenant derivation only through the approved narrow BIOS platform-governed operation targeting an independently validated active Tenant; the Tenant UUID is context, not authority, and ordinary Tenant-directed mutation is absent.
- **Rationale:** Derived content must not broaden or cross Tenant boundaries.
- **Alternatives:** Independent output scope; application-only checks.
- **Consequences:** Database-enforced isolation across lineage.
- **Status:** APPROVED — 2026-08-05.

### M007-D12 — Source authorization

- **Decision:** Admit only shared/public and same-Tenant private/tenant-confidential roots; reject licensed/restricted processing.
- **Rationale:** M007 introduces no entitlement/trusted-reader mechanism.
- **Alternatives:** Service-role bypass; entitlement architecture now.
- **Consequences:** Licensed/restricted automation remains gated.
- **Status:** APPROVED — 2026-08-05.

### M007-D13 — Language

- **Decision:** One active output Language; same-language rules for extraction/normalization; parent-derived source Language for translation.
- **Rationale:** Avoids duplicated language provenance and arbitrary inference.
- **Alternatives:** Nullable language; source/output pair on every row.
- **Consequences:** Multilingual Source Documents require trusted output labeling.
- **Status:** APPROVED — 2026-08-05.

### M007-D14 — Representation lifecycle and immutability

- **Decision:** Candidate/active/superseded/archived; content/material fields immutable from creation; no failed Representation.
- **Rationale:** Reproducibility forbids rewriting process output.
- **Alternatives:** Candidate editing; failed status on Representation.
- **Consequences:** Correction requires new run and UUID.
- **Status:** APPROVED — 2026-08-05.

### M007-D15 — Run lifecycle

- **Decision:** Running to succeeded/failed/cancelled; successful completion atomically inserts one candidate Representation whose required unique `producing_run_id` is the sole output relation, then marks the Run succeeded; failed/cancelled creates zero; retry is new run; attach-later is absent.
- **Rationale:** Deterministic execution history without job orchestration.
- **Alternatives:** Mutable retries; output attachment later.
- **Consequences:** No orphan successful runs or failed Representations.
- **Status:** APPROVED — 2026-08-05.

### M007-D16 — Representation supersession

- **Decision:** One candidate successor; compatibility key is root Source Document, kind, Language, scope, and Tenant; parent Representation is excluded; deterministic locking and atomic predecessor supersession apply.
- **Rationale:** Prevents silent rewrite and concurrent lineage forks.
- **Alternatives:** Version number; multiple proposals.
- **Consequences:** Historical outputs remain reconstructable while a replacement may use a different valid active derivation parent.
- **Status:** APPROVED — 2026-08-05.

### M007-D17 — Evidence integration

- **Decision:** Do not modify DB-007 or authorize automated Evidence; defer additive Representation-aware Evidence integration.
- **Rationale:** M007 supplies infrastructure but not Evidence workflow/coordinates.
- **Alternatives:** Add Representation FK now; new integration table.
- **Consequences:** Automated activation remains blocked by governance, intentionally.
- **Status:** APPROVED — 2026-08-05.

### M007-D18 — RLS and trusted operations

- **Decision:** Root-Document-intersected reads, trusted-only mutation, no ordinary Run reads, fixed-search-path functions, no context-as-authority.
- **Rationale:** Reuses DB-006/007 security lessons.
- **Alternatives:** Application-only security; service-role universal authority.
- **Consequences:** Least privilege and no authorization broadening.
- **Status:** APPROVED — 2026-08-05.

### M007-D19 — Audit vocabulary and separation

- **Decision:** Reuse reference actions; add `document_representation` and `processing_run`; keep audit, lineage, and execution distinct.
- **Rationale:** Existing actions describe governance transitions without content snapshots.
- **Alternatives:** Processing-specific actions; execution in audit JSON.
- **Consequences:** Bounded audit and relational reproducibility.
- **Status:** APPROVED — 2026-08-05.

### M007-D20 — Seeds and deferred architecture

- **Decision:** Zero business seeds; defer storage, orchestration, registries, segments, vectors, entitlement, and intelligence.
- **Rationale:** None is required for the minimum durable slice.
- **Alternatives:** Seed types/registries or build full pipeline.
- **Consequences:** Narrow migration with explicit future gates.
- **Status:** APPROVED — 2026-08-05.

## 19. Atlas and assumption alignment

| Assumption | DB-008 effect |
|---|---|
| A-028 — Cross-language semantic normalization | Advances safe evaluation by preserving immutable source-language and translated/normalized derivatives; efficacy remains unvalidated. |
| A-029 — Shared and tenant-private knowledge coexistence | Constrains Representation lineage with explicit scope, same-Tenant rules, and non-broadening authorization; production threat-model validation remains open. |
| A-030 — Temporal model sufficiency | Preserves run execution and lifecycle times without claiming bitemporal content truth; broader temporal sufficiency remains unresolved. |
| A-032 — PostgreSQL plus vector capabilities | Deliberately defers vectors until canonical Representation identity exists; sufficiency remains unvalidated. |
| A-033 — Specialist-agent value | Leaves agent/model orchestration deferred and records only bounded processor/model execution metadata. |
| A-038 — Multilingual provenance model | Directly advances versioned derivative and translation lineage; semantic reconstruction must still be validated through Atlas cases. |
| A-039 — Common decision chain | Preserves the Evidence/intelligence boundary and does not imply that processing output is Evidence or interpretation. |

DB-008 introduces no new Atlas assumption ID and marks none validated.

## 20. Sequential implementation acceptance plan

1. Clean replay succeeds through Migrations 001–007.
2. Exactly `bios_knowledge.document_representations` and `bios_knowledge.processing_runs` are created by M007.
3. Structural assertions are scoped to M007 ownership and tolerate later canonical tables.
4. Separate lineage, segment, chunk, storage, model, provider, pipeline, prompt, connector, ingestion, vector, Evidence-integration, and intelligence tables remain absent.
5. Both tables use generated immutable UUID primary keys.
6. Both tables create zero production rows.
7. Representation requires a valid root Source Document.
8. Representation requires a valid unique producing Processing Run.
9. Representation accepts exactly shared or tenant scope.
10. Shared Representation requires null Tenant; tenant Representation requires valid non-null Tenant.
11. Representation root, parent, run, scope, Tenant, kind, Language, media type, content, digest, predecessor, and creation time are immutable.
12. Representation kind accepts exactly five Section 5.2 codes.
13. Direct extraction kinds reject a parent when the run input is Source Document.
14. Normalized and translated kinds require a parent Representation.
15. Media type accepts exactly `text/plain`, `text/markdown`, or `text/html`.
16. `application/json` and every other structured/arbitrary media type are rejected.
17. Text content rejects null, empty, and zero-byte values.
18. Text content accepts up to 1,048,576 UTF-8 bytes.
19. Text content rejects more than 1,048,576 UTF-8 bytes, including multibyte boundary cases, without truncation or alteration.
20. Required digest accepts only lowercase 64-hex.
21. Database verifies digest against exact stored UTF-8 content.
22. Digest is immutable and non-unique.
23. Identical content/digest may exist as distinct Representation UUIDs.
24. No binary content, storage bucket/path, object FK, or upload interface exists.
25. Representation Language requires a valid active Language at creation.
26. Activation revalidates active Language.
27. Later Language deprecation preserves historical Representation/Run lineage.
28. Single-language Source Document direct extraction requires matching Document Language.
29. Unknown/multiple-language Source Document direct processing accepts a governed active output Language.
30. Normalization output Language equals parent Language.
31. Translation output Language differs from parent Language.
32. No duplicated source-language field exists on Representation or Run.
33. Representation access classification accepts exactly four canonical codes.
34. Shared Representation rejects `tenant_confidential`.
35. Output classification never broadens root Source Document or parent classification.
36. Tenant output from shared/public input remains tenant-private even when classified public.
37. Root Source Document ID remains identical across a derived chain.
38. Direct output has null parent and matching run Source Document input.
39. Derived output has one matching run Representation input and matching parent FK.
40. Derived output rejects parent/root mismatch.
41. Derived output rejects scope/Tenant incompatibility with parent/root.
42. Self-parenting is rejected.
43. Parent lineage cycles are rejected.
44. Multi-parent and arbitrary lineage operations are absent.
45. New derived processing requires active parent Representation.
46. New processing requires active root Source and Source Document.
47. Historical lineage survives parent supersession/archive without rewrite.
48. Historical lineage survives Source Document supersession/archive and Source deprecation without rewrite.
49. Processing Run requires exactly one input FK.
50. Run scope accepts exactly shared or tenant.
51. Run Tenant nullability follows scope exactly.
52. Run input, scope, Tenant, operation, processor/model metadata, parameters, actor, correlation, purpose, and start time are immutable.
53. Operation kind accepts exactly five Section 8.1 codes.
54. Processor identifier is trimmed and bounded 1–200.
55. Processor version is trimmed and bounded 1–100.
56. Model identifier is null or trimmed/bounded 1–200.
57. Model version is null exactly when model identifier is null and otherwise trimmed/bounded 1–100.
58. Parameters defaults to a JSON object.
59. Parameters rejects arrays/scalars/null and serialized size above 8,192 bytes.
60. Parameters enforce flat lowercase 1–64-character keys, scalar/null values, 500-character string-value bounds, the exact prohibited-key vocabulary, and rejection of nested objects/arrays; governed paths do not store source/Representation content, prompts, raw provider responses, or secrets there.
61. Actor identifier reuses canonical BIOS semantics and 200-character maximum.
62. Correlation ID is required trimmed text bounded 1–200.
63. Purpose is required trimmed text bounded 1–500 and non-authorizing.
64. Well-formed context and processor/model fields do not authorize otherwise unauthorized input.
65. Run outcome accepts exactly running, succeeded, failed, or cancelled.
66. New Run always starts running with null completion/error fields.
67. Running-to-succeeded succeeds only through atomic output creation.
68. Succeeded Run has exactly one reverse-related output Representation through required unique `document_representations.producing_run_id`; Processing Run contains no duplicate output FK.
69. Running-to-failed requires bounded error code and permits bounded safe summary.
70. Running-to-cancelled creates no output and has null error fields.
71. Failed/cancelled Run creates no Representation.
72. Every terminal Run requires completion timestamp.
73. Terminal Runs reject lifecycle reversal or metadata mutation.
74. Retry creates a new Run UUID and no retry mutation exists.
75. No queue, lease, heartbeat, schedule, webhook, or retry-control column exists.
76. `extract_text` maps Source Document input to `extracted_text` output.
77. `ocr` maps Source Document input to `ocr_text` output.
78. `transcribe` maps Source Document input to `transcript` output.
79. `normalize` maps parent Representation input to `normalized_text` output.
80. `translate` maps parent Representation input to `translated_text` output.
81. Unsupported operation/input/output combinations are rejected.
82. Successful completion atomically creates output and transitions Run.
83. Failed successful-completion transaction leaves Run running and creates no output/audit success.
84. No independent direct Representation creation or attach-output-later operation exists; output insertion and Run success are one transaction.
85. Representation creation always starts candidate with correct null lifecycle timestamps.
86. Candidate-to-active succeeds after all dependency revalidation.
87. Candidate-to-archived and active-to-archived set exact timestamps.
88. Invalid transitions and terminal reactivation are rejected.
89. No failed Representation status exists.
90. Material/content correction in every lifecycle state is rejected.
91. Correction requires a new Run and Representation UUID.
92. Successor proposal requires active compatible predecessor.
93. Predecessor compatibility key is exactly root Source Document, Representation kind, Language, scope, and Tenant.
94. Self-supersession and cycles are rejected.
95. At most one candidate successor references one predecessor.
96. Concurrent successor proposals use deterministic advisory-before-row locking.
97. Archiving candidate successor releases proposal position.
98. Successor activation atomically activates successor and supersedes predecessor.
99. Atomic supersession writes both timestamps and audits.
100. Superseded predecessor cannot receive another proposal.
101. Shared Run/Representation succeeds for active shared/public root.
102. Tenant Run/Representation succeeds from shared/public root only through the narrow platform-governed operation with an independently validated active target Tenant; ordinary Tenant-directed authority is absent.
103. Tenant Run/Representation succeeds from same-Tenant private/tenant-confidential root.
104. Tenant-private processing rejects missing required target Tenant.
105. Tenant-private processing rejects mismatched target Tenant.
106. Shared output from tenant-private input is rejected.
107. Cross-Tenant parent or root processing is rejected.
108. Shared licensed root processing is rejected.
109. Shared restricted root processing is rejected.
110. Service-role possession cannot override licensed/restricted rejection.
111. Actor, correlation, purpose, processor, model, parameters, or target Tenant cannot override authorization rejection.
112. No entitlement, trusted-reader, service-purpose, access-grant, role, or capability structure is introduced.
113. RLS is enabled on both M007 tables.
114. Anonymous callers read neither table.
115. Ordinary authenticated callers receive no insert/update/delete on either table.
116. Ordinary authenticated callers cannot execute M007 mutation functions.
117. Active-profile callers read only active shared/public Representations with currently authorized root Document.
118. Active Tenant members read only active own-Tenant Representations with currently authorized root Document.
119. Ordinary authenticated and Tenant-admin callers cannot read Processing Runs.
120. Root Document lifecycle/access changes immediately remove ordinary Representation visibility without deleting lineage.
121. Cross-Tenant reads and existence disclosure are denied.
122. Trusted functions are security definer with fixed empty search path and fully qualified objects.
123. `PUBLIC` execution is revoked and grants are least privilege.
124. Physical deletion is rejected through governed/direct ordinary paths.
125. Audit vocabulary admits exactly `document_representation` and `processing_run` as new resources.
126. Run/Representation creation and lifecycle use only approved reference actions.
127. Audit metadata remains a JSON object within 8,192 serialized bytes.
128. Audit metadata excludes content, parameters snapshot, prompt, response, credentials, tokens, secrets, stack traces, and unrestricted snapshots.
129. Run parameters remain on immutable Run record, not audit metadata.
130. Lineage remains relational and absent from audit/arbitrary JSON substitutes.
131. Failed operations emit no successful audit event.
132. M007 creates no general content, historical Document, licensed, restricted, entitlement, or storage reader.
133. M007 does not alter `evidence` or `evidence_provenance` columns, constraints, policies, or functions.
134. Existing M006 Evidence remains readable/governed under unchanged DB-007 behavior.
135. No automated Evidence writer or Representation-aware Evidence activation function exists.
136. No Evidence-to-Representation or Evidence-to-Run FK/link exists.
137. No segment, chunk, page-map, character/token-range, embedding, or vector structure exists.
138. No Signal, Pattern, Finding, Insight, Recommendation, Decision Context, Decision, or intelligence-product structure exists.
139. Model/provider/pipeline/prompt registries remain absent.
140. Binary/object-storage and acquisition infrastructure remain absent.
141. Production seed count for both tables is zero.
142. Migration 001 regression suite remains green.
143. Migration 002 regression suite remains green.
144. Migration 003 regression suite remains green.
145. Migration 004 regression suite remains green.
146. Migration 005 regression suite remains green.
147. Migration 006 regression suite remains green.
148. Earlier exclusion/count assertions remain forward-compatible with canonical M007 additions.
149. Clean replay produces deterministic tables, constraints, indexes, policies, functions, grants, and audit vocabulary.
150. Required indexes cover root Document, parent, run, scope/Tenant/status, Language, digest, input FKs, outcome, and candidate successor lookup.
151. Oversized successful-completion input is detected before Representation insertion, transitions the Processing Run to failed with exact `error_code = content_too_large`, creates no Representation, and emits no successful Representation audit.
152. Oversized content is never silently truncated, summarized, split, semantically compressed, or otherwise altered to satisfy the M007 bound.
153. The byte bound is documented and enforced as an M007 operational PostgreSQL limit rather than a permanent BIOS Representation limit.
154. Shared/public-to-tenant targeting rejects invocation outside the narrow trusted BIOS platform operation even when `target_tenant_id` names an active Tenant.
155. Supersession compatibility excludes `parent_representation_id`; a successor may use a different valid active parent while matching the exact compatibility key and all lineage/security invariants.

Acceptance-requirement count: **155**.

## 21. SQL-blocker review

M007-D01 through M007-D20 were approved by the BIOS Executive Office on 2026-08-05. Architecture approval is complete, and no known unresolved durable SQL architecture or security decision remains.

DB-008 v1.2 Canonical is executable without inventing a table, field, type, bound, vocabulary, content-storage rule, identity rule, lineage cardinality, operation mapping, scope rule, access rule, Language rule, lifecycle, supersession rule, run outcome, RLS behavior, trusted authorization path, audit resource/action, or seed.

Tenant-targeted derivation from shared/public input is database-verifiable after approval of M007-D11: the operation is callable only through the narrow trusted BIOS platform path, the input must be shared/public and active, the target Tenant must independently exist and be active, and output scope must be tenant-private for that Tenant. `target_tenant_id` does not grant authority, and no ordinary Tenant-directed mutation path exists. This requires no new entitlement, role, capability, service-purpose, or trusted-reader structure.

No additional hidden SQL blocker is known. Implementation may proceed strictly within DB-008. If implementation discovers a new material ambiguity, it must stop and return the issue to the BIOS Executive Office rather than invent architecture.

## 22. Compatibility assessment

### 22.1 DB-006 Source and Document

M007 references but does not modify Source or Source Document. Root artifact identity remains DB-006's immutable UUID. Later Document/Source lifecycle changes preserve historical Representation lineage without cascade or rewrite; current ordinary read visibility continues to intersect current Source Document authorization.

### 22.2 DB-007 Evidence and provenance

M007 does not modify Evidence/provenance. Historical and new manual Evidence remain Source-Document-grounded exactly as DB-007 defines. Automated Evidence activation remains gated until a later migration explicitly admits Representation/Run lineage and coordinate semantics.

### 22.3 Earlier migrations

M007 adds no Market, Domain, Entity, tenancy, role/capability, or audit-action reinterpretation. Regression assertions must be ownership-scoped so later canonical tables do not appear as earlier migration defects.

## 23. Readiness checklist

- [x] Canonical architecture and implemented Migration 001–006 boundary reviewed.
- [x] Smallest durable two-table boundary proposed.
- [x] Content/storage decision explicit.
- [x] Single-parent lineage and root identity explicit.
- [x] Processing execution separated from audit and Representation.
- [x] Scope, Tenant, Language, authorization, lifecycle, immutability, and concurrency specified.
- [x] DB-007 integration and automation gates explicit.
- [x] Deferred ingestion, storage, segment, vector, registry, entitlement, and intelligence architecture explicit.
- [x] Atlas assumptions mapped without inventing IDs.
- [x] 155 sequential acceptance requirements defined.
- [x] M007-D01 through M007-D20 approved by BIOS Executive Office on 2026-08-05.
- [ ] SQL security review completed.
- [ ] Executable pgTAP/RLS tests completed.
- [ ] Clean Migration 007 replay completed.
- [ ] Migration 001–006 regression suites pass with M007 present.

## 24. Recommendation

**DB-008 v1.2 CANONICAL — READY FOR MIGRATION 007 IMPLEMENTATION**

Architecture approval is complete. SQL security review, executable pgTAP/RLS validation, clean Migration 007 replay, and Migration 001–006 regression validation remain implementation gates. Automated Evidence activation remains outside Migration 007.

## 25. Version history

| Version | Date | Change |
|---|---|---|
| 1.2 | 2026-08-05 | Canonical admission following BIOS Executive Office approval of M007-D01 through M007-D20; no architecture or table-boundary change |
| 1.1 | 2026-08-05 | Targeted clarification of textual media vocabulary, no-truncation byte-bound handling, platform-governed Tenant targeting, reverse Run-output relation, and parent-independent supersession compatibility; no table-boundary change |
| 1.0 | 2026-08-05 | Initial Proposed implementation design for Migration 007 Representation & Extraction Foundation |
