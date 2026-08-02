# ARCH-001 — Canonical Platform Architecture

| Field | Value |
|---|---|
| Document ID | ARCH-001 |
| Title | BIOS Canonical Platform Architecture |
| Version | 1.0 |
| Status | Canonical |
| Effective date | 2026-08-02 |
| Owner | BIOS Executive Office — Architecture and Engineering |
| Dependencies | ENG-001, CANON-001, ADR-001, ARCH-002 |
| Supersedes | None |
| Review cadence | At each engineering gate and after material Atlas resolution |
| Related documents | [README](../../README.md), [ENG-001](../engineering/ENG-001_BIOS_Engineering_Handbook.md), [CANON-001](../engineering/CANON-001_Repository_and_Engineering_Standards.md), [ADR-001](../decisions/ADR-001_PostgreSQL_and_Supabase.md), [ARCH-002](ARCH-002_Architecture_Assumption_Register.md), [DB-001](../database/DB-001_Canonical_Data_Model.md) |

## 1. Purpose

This document defines the current canonical technical architecture of the BRG Intelligence Operating System (BIOS), a multilingual Consumer Decision Intelligence platform. BIOS converts governed evidence into traceable intelligence and accountable decisions for multiple tenants, clients, workspaces, markets, and categories.

This architecture is category-neutral. Dairy is an illustrative category only. No category, industry, market, country, language, tenant, client, source type, entity type, or decision use case may be embedded as fixed application logic when it can be governed as data or configuration.

## 2. Scope and authority

ARCH-001 defines system boundaries, layers, canonical concepts, ownership, information flow, security posture, and extension rules. [DB-001](../database/DB-001_Canonical_Data_Model.md) defines what Engineering may encode structurally for Phase 1. [ARCH-002](ARCH-002_Architecture_Assumption_Register.md) identifies what remains to be proved.

Architecture status labels used in this document are:

- **ACCEPTED DESIGN DECISION** — governed by an approved canonical document or required as the current reversible baseline.
- **PROVISIONAL** — the recommended implementation posture pending evidence or Executive Office resolution.
- **UNVALIDATED ASSUMPTION** — a proposition tracked in Atlas and not established as fact.

Where this document exposes ambiguity in a governing document, it reports rather than silently repairs it.

## 3. System context

```text
External sources and licensed data
              │
              ▼
Ingestion → Evidence Room → Intelligence Workbench → Decision Context
                 │                    │                    │
                 └──── provenance ────┴────────────────────┘
                                      │
                         Human review and agent assistance
                                      │
                                      ▼
                       Recommendation → Authorized Decision
```

The BIOS intelligence chain is:

```text
Evidence → Signal → Pattern → Finding → Decision Context → Recommendation → Decision
```

Evidence is observed or acquired source material. Signals, patterns, findings, and recommendations are interpretations. The architecture must keep the two distinguishable and retain navigable upstream traceability.

## 4. Architecture principles

1. Decisions, not dashboards, are the primary product outcome.
2. Evidence and provenance are preserved through every derivation.
3. Tenant isolation is structural, deny-by-default, and tested.
4. Markets, categories, languages, and entity types are governed dimensions.
5. The canonical core is normalized; variation belongs in packs, configuration, and bounded extensions.
6. Shared knowledge is explicit and curated; tenant-private material never becomes shared by omission.
7. Human accountability governs consequential actions.
8. Unvalidated assumptions remain replaceable.
9. Local development reconstructs the platform from version-controlled artifacts.
10. Specialized infrastructure is added only for validated workloads.

## 5. Platform layers

| Layer | Responsibility | Examples |
|---|---|---|
| Executive workflows | Accountable decision formation and follow-through | Decision briefs, approvals, decision logs |
| Applications | Task-specific user experiences | Evidence room, intelligence workbench, dashboards |
| Agent platform | Bounded assistance and criticism | Evidence, signal, intelligence, and critic agents |
| Intelligence platform | Derived analytical objects | Signals, patterns, findings, decision contexts |
| Knowledge architecture | Meaning, relationships, provenance, language, time | Registries, links, normalized representations |
| Canonical platform | Identity, tenancy, governed data, authorization | Tenants, memberships, markets, domains, entities |
| Engineering foundation | Runtime, database, security, delivery, observability | PostgreSQL, Supabase, migrations, tests, audit |

Higher layers consume contracts owned below them. Applications and agents must not bypass tenant policy or create shadow systems of record.

## 6. Tenant, client, and workspace architecture

### 6.1 Approved boundary

**ACCEPTED DESIGN DECISION:** Tenant is the primary data-security and ownership boundary. Every tenant-private record must resolve to exactly one tenant. Missing tenant context means denial, not global access.

### 6.2 Unresolved commercial and organizational semantics

**UNVALIDATED ASSUMPTION — A-041:** The precise relationship among Tenant, Client, and Workspace is not approved. The following remain open:

- whether one client equals one tenant;
- whether one tenant may represent several client organizations;
- whether Client is a commercial concept separate from Tenant;
- whether every workspace belongs to exactly one tenant;
- whether tenants contain multiple workspaces;
- whether a user can belong to multiple tenants and workspaces;
- whether a decision context can span workspaces.

### 6.3 Least-irreversible Phase 1 posture

**PROVISIONAL:** Use Tenant as the hard security boundary. Model Workspace as an optional tenant-owned organizational scope, with each workspace belonging to exactly one tenant. Treat Client as business metadata outside the Phase 1 core until its semantics are approved. Permit users to hold independent memberships in multiple tenants and workspaces. Do not permit a decision context to cross tenant boundaries; cross-workspace scope remains configurable and Atlas-gated.

This candidate avoids equating commercial customers with security partitions and can be replaced without changing ownership of canonical records.

## 7. Identity and authorization

**ACCEPTED DESIGN DECISION:** Supabase Auth owns authentication identities in `auth.users`. BIOS owns application profiles and tenant/workspace memberships. A profile may reference one Supabase identity; authorization attaches to memberships and governed roles, not to a globally powerful user flag.

Authorization evaluates authenticated identity, tenant membership, workspace membership when applicable, role/capability, record scope, and action. Database RLS and server-side policy provide defense in depth. Privileged cross-tenant operations require named service or administrative roles, explicit purpose, and audit evidence.

## 8. Geography, markets, and groupings

The architecture distinguishes:

- **Geography:** a governed physical or jurisdictional place in a hierarchy.
- **Market:** a configured commercial/analytical operating scope, which references geography but is not identical to it.
- **Market grouping:** a configurable set of markets used for analysis or operation.
- **Reporting/portfolio grouping:** a configurable presentation or management grouping that may combine markets or other scopes.

**ACCEPTED DESIGN DECISION:** Priority markets are governed data, not schema constraints. Priority 1 currently includes Japan, South Korea, Malaysia, Mainland China, Hong Kong, Taiwan, and India. Priority 2 currently includes Vietnam, Thailand, Indonesia, Philippines, and Singapore.

**PROVISIONAL:** “Greater China” is a configurable analytical, geographic, portfolio, or reporting grouping containing Mainland China, Hong Kong, and Taiwan. It is not automatically a parent market. Its precise grouping semantics remain configurable and are covered by A-026 and A-036.

## 9. Language architecture

Language is an independent governed registry using stable codes and optional script/locale metadata. Markets declare supported, primary, or operational languages through relationships rather than a single language field.

Source documents and evidence preserve original language and original content. Normalized or translated representations are separate, versioned derivatives linked to the original, transformation method, model or reviewer, time, and confidence. Search or display may select a preferred representation but must not erase the original.

**UNVALIDATED ASSUMPTION — A-028:** Cross-language semantic normalization can achieve sufficient reliability for BIOS workflows. Human review thresholds depend on decision risk and measured quality.

## 10. Domain and category architecture

- **Domain:** a governed subject area or ontology boundary.
- **Domain node:** a hierarchical or graph node within a domain taxonomy.
- **Category:** a governed product, service, or analytical classification, represented through domain nodes or explicit category semantics defined by a Domain Pack.
- **Domain Pack:** a versioned configuration package of taxonomy, attributes, validation rules, mappings, prompts, and presentation metadata for a domain or category family.

**ACCEPTED DESIGN DECISION:** Categories are not hard-coded columns or enums. The canonical core supports arbitrary categories through normalized registries and relationships.

**UNVALIDATED ASSUMPTIONS — A-025, A-027, A-035:** A common abstraction, Consumer Decision Ontology, and Domain Pack mechanism are expected to work across categories but require Atlas validation. Domain-specific attributes remain bounded JSONB or governed definitions until promoted into stable canonical fields.

## 11. Market Packs, Domain Packs, and tenant configuration

A **Market Pack** is a versioned configuration package for market-specific language, source, regulatory, taxonomy-mapping, formatting, and workflow behavior. It references canonical markets and languages; it does not fork the platform.

A **Domain Pack** provides domain-specific classifications, attribute definitions, mappings, prompts, and validation behavior without redefining tenant security or core provenance.

Tenant configuration selects allowed packs, features, policies, display defaults, and workflow settings. Configuration is validated, versioned, attributable, and bounded by platform policy. Precedence is platform policy → pack defaults → tenant configuration → workspace configuration, with no layer permitted to weaken mandatory security.

**UNVALIDATED ASSUMPTIONS — A-026, A-035, A-036:** Packs can absorb sufficient variation without core forks or schema redesign.

## 12. Entity architecture

An Entity is an identifiable analyzed object such as an organization, brand, product, person, place, channel, or concept. Entity type is governed data. Entities may have aliases by language and market, typed relationships, temporal market presence, and domain memberships.

Shared reference entities and tenant-private entities use explicit knowledge scope. Matching or merging produces auditable proposals; it never silently changes identity. Relationships are typed, directional where needed, temporally qualified, and provenance-linked.

## 13. Knowledge architecture

BIOS knowledge consists of governed reference knowledge and tenant-private knowledge connected through typed, attributable relationships.

### 13.1 Shared reference knowledge

Shared knowledge contains curated registries, public/licensed reference facts permitted for reuse, and explicitly approved derived material. It is platform-governed and readable only according to classification and license.

### 13.2 Tenant-private knowledge

Tenant-private knowledge includes tenant sources, evidence, interpretations, configurations, and decisions. It remains tenant-owned through every derived object.

### 13.3 Promotion boundary

**UNVALIDATED ASSUMPTION — A-042:** Whether and how tenant-derived material may be promoted into shared reference knowledge is not approved.

**PROVISIONAL:** No direct promotion in Phase 1. A future promotion workflow must require tenant authorization, rights and privacy review, de-identification where necessary, human approval, new shared provenance, and an audit event. A shared record must never retain an operational dependency on inaccessible tenant-private evidence.

## 14. Evidence and source architecture

The source layer separates source definition, retrieved source document, ingestion attempt, and evidence assertion:

- **Source:** the governed origin or publication channel.
- **Source connector:** an optional adapter configuration used to retrieve material.
- **Source document:** an immutable or versioned acquired artifact and its metadata.
- **Ingestion record:** the operational history of acquisition and processing.
- **Evidence record:** a citable observation, excerpt, fact, or artifact derived from a source document or authorized direct observation.

Evidence records link explicitly to sources/documents, markets, domains, entities, language, time, and classification. Corrections create new versions or correction events; they do not destroy what informed earlier intelligence.

## 15. Provenance architecture

Provenance is a first-class graph of derivation, not a descriptive text field. Each governed object records its source or upstream objects, responsible actor or agent, method/version, timestamps, and review state where applicable.

The minimum traceability path is bidirectional:

```text
Decision ← Recommendation ← Decision Context ← Finding ← Pattern ← Signal ← Evidence ← Source Document
```

Objects may cite multiple upstream types only through constrained relationship tables defined in DB-001. Provenance edges are append-oriented and tenant ownership must be compatible across both ends.

## 16. Temporal architecture

BIOS distinguishes:

- **system time:** when BIOS recorded or changed an object;
- **source publication time:** when source material was published;
- **observed time:** when an underlying event was observed;
- **valid time:** when a statement or relationship applies in the represented world;
- **decision time:** when a recommendation or decision became effective.

Corrections, supersession, and expiry are recorded without rewriting history. Temporal precision and uncertainty may be recorded when a point timestamp would claim false precision.

## 17. Intelligence architecture

- A **Signal** is a noteworthy evidence-backed change or indicator.
- A **Pattern** is a supported relationship or recurrence across signals.
- A **Finding** is an analytical conclusion supported by evidence and/or patterns.

Signals, patterns, and findings are tenant-scoped by default. They may combine shared reference knowledge with tenant-private evidence, but the resulting object remains owned by the tenant and inaccessible without that tenant’s authorization. Confidence, method, lifecycle, creator, and review state are explicit.

Automated pattern generation is a future capability. The Phase 1 model permits human-authored patterns without requiring automation infrastructure.

## 18. Decision Context architecture

A Decision Context is the governed package for a decision question: objective, scope, stakeholders, time horizon, constraints, evidence, findings, alternatives, and review state. It is tenant-scoped and is the primary intelligence-delivery object under **UNVALIDATED ASSUMPTION A-040**.

A Decision Context may span multiple markets and domains/categories through explicit links. It must never span tenants. Cross-workspace scope is **PROVISIONAL** under A-041; Phase 1 should either require one workspace or allow multiple tenant-consistent workspace links behind policy, without embedding a global assumption.

## 19. Recommendations and decisions

A Recommendation is a proposed action with rationale, alternatives, assumptions, confidence, supporting findings, and review state. A Decision is an authorized choice with owner, rationale, effective time, scope, and follow-up obligations.

**ACCEPTED DESIGN DECISION:** Decisions may exist without a BIOS-authored recommendation so that BIOS can record externally made decisions. Such decisions still require provenance describing their authority and origin.

**PROVISIONAL — A-043:** Recommendations must receive human approval before they trigger externally consequential action. Low-risk internal drafts may remain unapproved and must be labeled accordingly.

## 20. Human review architecture

Human review is a reusable governed event with reviewer membership, target, decision, reason, time, and policy/version. Review states are explicit and do not overwrite the reviewed object’s history. High-risk actions require separation of duties where policy demands it.

Review policies may vary by tenant, market, workflow, and risk, but configuration may not bypass platform minimums.

## 21. Agent architecture

Agents are bounded workers, not autonomous owners of decisions. An agent run has a tenant, purpose, input scope, tool grants, model/configuration version, execution record, outputs, cost/usage metadata, and review state.

Agents access data through the same authorization boundaries as other services. Tool calls are allow-listed and auditable. Prompt injection, unsupported claims, provenance loss, cross-tenant leakage, and unsafe action are evaluation targets.

**UNVALIDATED ASSUMPTION — A-033:** Specialist agents may eventually justify orchestration complexity. Agent-run persistence is deferred from Migration 001 unless required by the first executable workflow.

## 22. Ingestion architecture

Ingestion is idempotent, observable, and separable into acquire, preserve, extract, normalize, classify, link, and review stages. Raw source artifacts are preserved in approved object storage when rights and classification allow; PostgreSQL stores canonical metadata and governed extracted evidence.

Connectors are adapters behind an owned contract. Manual upload is a valid Phase 1 ingestion path. A source connector registry is deferred until at least one automated connector is implemented.

## 23. Multilingual normalization

Normalization creates versioned derivative representations rather than replacing source content. Each representation records source representation, target language/locale, method/model/version, glossary or pack version, confidence, reviewer, and creation time.

Entity resolution and taxonomy mapping operate on both original and normalized text. Decision-critical quotations must remain viewable in original form with translation status.

## 24. Audit architecture

Audit events record security-sensitive and governance-significant activity: membership changes, privileged access, knowledge promotion, review, decision authorization, configuration change, agent action, and correction/supersession.

Audit data is append-oriented, protected from ordinary application mutation, attributable to actor or service, tenant-aware, and retained according to policy. Application logs are not a substitute for audit events.

## 25. PostgreSQL and Supabase

Per [ADR-001](../decisions/ADR-001_PostgreSQL_and_Supabase.md), PostgreSQL is the canonical transactional system of record and Supabase is the initial PostgreSQL-centered platform layer. Supabase Auth provides identities; RLS protects exposed tenant-scoped data; Storage may preserve source artifacts; server-side functions or services enforce privileged workflows.

PostgreSQL-standard normalized structures are preferred. JSONB is restricted to governed variable extension values and operational metadata that do not require canonical relational integrity. Vector capability is a derived index or projection, never the sole canonical representation, under A-032.

## 26. Deployment posture

### 26.1 Local first

**ACCEPTED DESIGN DECISION:** migrations, seed data, authentication flows, RLS tests, and core integration tests must run locally from version-controlled configuration. Production credentials and data are unnecessary for routine development.

### 26.2 Future topology

The intended path is local → development → staging → production, promoting the same immutable artifacts. Shared environments use separate databases, credentials, storage, and secrets. Production requires backup/restore testing, telemetry, recovery targets, audit retention, and controlled administrative access.

Geographic replication, data residency partitions, warehouses, queues, search engines, and vector services are deferred until validated requirements justify them.

## 27. Extensibility

- Add new markets, languages, domains, categories, and entity types through governed records and packs.
- Add capabilities through owned modules and versioned contracts.
- Preserve stable identifiers and additive schema evolution.
- Treat indexes, vectors, search documents, and warehouse models as rebuildable projections.
- Promote repeated extension attributes into canonical fields only after Atlas evidence and migration review.
- Use feature and configuration scope without weakening tenant or audit policy.

## 28. Prohibited hard-coding

The platform must not hard-code:

- named countries, priority tiers, or Greater China semantics into schema constraints;
- dairy or any other category into core table structure;
- a fixed list of languages, entity types, sources, use cases, or decision types;
- one-client-per-tenant or one-workspace-per-tenant before A-041 resolution;
- shared access based on a null `tenant_id` convention;
- unvalidated ontology, pack, agent, or vector assumptions into irreversible structures;
- authorization only in the client interface;
- normalized text in place of original evidence.

## 29. Atlas integration and decision map

| Architecture area | Posture | Atlas dependency |
|---|---|---|
| PostgreSQL/Supabase core | Accepted | A-032 for vector sufficiency only |
| Tenant as security boundary | Accepted | A-041 for client/workspace semantics |
| Category-neutral abstraction | Provisional | A-025, A-027, A-035 |
| Market/Domain Packs | Provisional | A-026, A-035, A-036 |
| Multilingual normalization | Provisional | A-028 |
| Specialist agents | Deferred/provisional | A-033 |
| Decision Context as primary delivery object | Provisional | A-040 |
| Shared-knowledge promotion | Disabled in Phase 1 | A-042 |
| Consequential recommendation approval | Provisional safeguard | A-043 |

Atlas resolution may refine architecture through reviewed document changes and migrations. It must not mutate implementation silently.

## 30. Reported ambiguities

1. The governing documents define Tenant but do not define Client or Workspace; A-041 contains the unresolved model.
2. The governing documents mention languages but do not establish a complete multilingual representation model; A-028 covers efficacy, while DB-001 adopts a reversible version model.
3. The governing documents distinguish shared and tenant-scoped data but do not approve promotion of tenant-derived knowledge; A-042 prohibits Phase 1 promotion by default.
4. The role of Decision Context is canonical in the intelligence chain but its status as the primary delivery object remains an Atlas assumption under A-040.

## 31. Version history

| Version | Date | Change |
|---|---|---|
| 1.0 | 2026-08-02 | Initial canonical platform architecture |
