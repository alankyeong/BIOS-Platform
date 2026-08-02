# ARCH-002 — BIOS Architecture Assumption Register

| Field | Value |
|---|---|
| Document ID | ARCH-002 |
| Title | BIOS Architecture Assumption Register |
| Version | 1.0 |
| Status | Canonical |
| Effective date | 2026-08-02 |
| Owner | BIOS Executive Office — Project Atlas |
| Dependencies | ENG-001, CANON-001, ARCH-001, DB-001 |
| Supersedes | None |
| Review cadence | At every engineering gate and monthly while assumptions are active |
| Related documents | [README](../../README.md), [ENG-001](../engineering/ENG-001_BIOS_Engineering_Handbook.md), [CANON-001](../engineering/CANON-001_Repository_and_Engineering_Standards.md), [ADR-001](../decisions/ADR-001_PostgreSQL_and_Supabase.md), [ARCH-001](../architecture/ARCH-001_Canonical_Platform_Architecture.md), [DB-001](../database/DB-001_Canonical_Data_Model.md) |

## 1. Purpose

This register makes the assumptions beneath the BIOS canonical architecture visible, falsifiable, owned, and replaceable. Atlas validates assumptions; Engineering implements approved architecture; the Executive Office defines product direction.

An assumption is not an established fact. No item in this Version 1.0 register is marked `Validated` because the supplied approved source material contains no validation evidence package.

## 2. Lifecycle and controls

```text
Proposed → Registered → Testing
                         ├→ Validated
                         ├→ Refuted
                         └→ Superseded
```

`Validated`, `Refuted`, and `Superseded` are possible resolution states. A later result may supersede a prior resolution through a new linked assumption; `Validated → Refuted` is not represented as the normal lifecycle.

### 2.1 Status entry and exit rules

| Status | Entry condition | Exit evidence |
|---|---|---|
| Proposed | Falsifiable proposition and owner identified | Executive Office or Atlas accepts it into the register |
| Registered | Impact, method, and criteria are documented | Approved test plan and evidence collection begin |
| Testing | Validation is actively producing controlled evidence | Evidence review resolves the assumption |
| Validated | Predetermined success criteria are satisfied within stated scope | Revisit trigger or superseding assumption |
| Refuted | Predetermined refutation criteria are met | Replacement decision or retirement |
| Superseded | A newer identified assumption or decision replaces it | None; retained historically |

### 2.2 Evidence rule

Each validation package must identify source, date, scope, markets, categories, tenants, languages, method, limitations, and reviewer. Success criteria must be fixed before results are assessed. A narrow pilot validates only its stated scope.

## 3. Register summary

| ID | Short statement | Classification | Status | Risk | Migration 001 impact |
|---|---|---|---|---|---|
| A-025 | Common category abstraction | Product architecture | Registered | High | Keep domain model configurable |
| A-026 | Market variation via configuration | Platform architecture | Registered | High | Normalize markets and packs |
| A-027 | Common Consumer Decision Ontology | Knowledge architecture | Registered | High | Defer advanced ontology |
| A-028 | Reliable cross-language normalization | Intelligence quality | Registered | High | Preserve original and version derivatives |
| A-029 | Provisional shared/private knowledge boundary | Governance architecture | Proposed | High | Default to tenant-private |
| A-030 | Provisional temporal model sufficiency | Data architecture | Proposed | Medium | Preserve essential time dimensions |
| A-031 | Provisional cross-context entity model | Knowledge architecture | Proposed | High | Use extensible entity registry |
| A-032 | PostgreSQL plus vector sufficiency | Technology architecture | Registered | Medium | Defer vector infrastructure |
| A-033 | Specialist-agent value | Agent architecture | Registered | Medium | Defer agent-run schema |
| A-034 | Provisional human-review governance | Governance architecture | Proposed | High | Keep review model minimal or deferred |
| A-035 | Domain Packs avoid schema redesign | Extension architecture | Registered | High | Use definitions plus bounded extensions |
| A-036 | Market Packs avoid platform forks | Extension architecture | Registered | High | Packs are configuration, not forks |
| A-037 | Provisional tenant configuration model | Platform architecture | Proposed | Medium | Avoid tenant-specific schema |
| A-038 | Provisional multilingual provenance model | Data architecture | Proposed | High | Version representations |
| A-039 | Provisional common decision chain | Product architecture | Proposed | High | Keep stages distinct and optional |
| A-040 | Decision Context as primary delivery object | Product architecture | Registered | High | Include minimal decision context core |
| A-041 | Tenant/client/workspace relationship | Security architecture | Registered | Critical | Tenant boundary; reversible workspace model |
| A-042 | Tenant knowledge promotion | Governance architecture | Registered | Critical | No promotion workflow in Migration 001 |
| A-043 | Human approval for consequential recommendations | Decision governance | Registered | High | No automated consequential action |

## 4. Historical assumptions A-025–A-040

### A-025 — Common intelligence abstraction

| Field | Entry |
|---|---|
| Statement | Different industries/categories share a sufficiently common intelligence abstraction. |
| Classification | Product architecture |
| Current Atlas status | Registered |
| Architecture affected | Domain, intelligence chain, canonical data model |
| Why BIOS needs it | A category-neutral platform depends on stable core concepts across categories. |
| Risk if wrong | Category forks, incompatible findings, and costly schema divergence. |
| Reversibility | Medium; packs are replaceable, but a deeply embedded abstraction is expensive to unwind. |
| Evidence required | Comparable end-to-end cases from materially different categories. |
| Validation method | Model at least three decision workflows in at least two materially different categories using the same core entities. |
| Success criteria | Core intelligence objects and provenance remain unchanged; variation is expressed through governed configuration. |
| Refutation criteria | A category requires incompatible meanings or structural changes to core chain objects. |
| Owner | Executive Office — Product Architecture |
| Review gate | Before declaring Domain Packs generally supported |
| Dependencies | A-027, A-035, A-039 |
| Replacement/supersession path | Introduce bounded domain kernels and supersede the single-common-abstraction design. |
| Notes | Validation is category-scoped; success in dairy alone is insufficient. |

### A-026 — Market variation through configuration

| Field | Entry |
|---|---|
| Statement | Market-specific variation can substantially be handled through configuration/Market Packs rather than core architecture forks. |
| Classification | Platform architecture |
| Current Atlas status | Registered |
| Architecture affected | Markets, languages, ingestion, workflow, configuration |
| Why BIOS needs it | A shared platform must serve priority and future markets without divergent codebases. |
| Risk if wrong | Market forks, duplicated controls, inconsistent upgrades, and high operating cost. |
| Reversibility | Medium; pack contracts can evolve, but deployed forks are costly. |
| Evidence required | Market workflow and regulatory variation across representative Priority 1 markets. |
| Validation method | Configure Japan, Malaysia, and one Greater China constituent without core code forks. |
| Success criteria | Differences fit governed configuration or bounded adapters while security and provenance remain common. |
| Refutation criteria | A market requires incompatible core ownership, intelligence, or audit behavior. |
| Owner | Executive Office — Market Architecture |
| Review gate | Before third production market |
| Dependencies | A-028, A-036, A-037 |
| Replacement/supersession path | Define explicit regional modules behind shared contracts. |
| Notes | Priority is operational data, not a schema rule. |

### A-027 — Common Consumer Decision Ontology

| Field | Entry |
|---|---|
| Statement | A common Consumer Decision Ontology can operate across materially different categories. |
| Classification | Knowledge architecture |
| Current Atlas status | Registered |
| Architecture affected | Domains, taxonomy, entities, findings, decision contexts |
| Why BIOS needs it | Cross-category comparison requires shared meaning without erasing domain nuance. |
| Risk if wrong | Misclassification, false comparability, or category-specific ontologies with weak interoperability. |
| Reversibility | Medium if ontology is versioned and mappings remain explicit. |
| Evidence required | Coverage, disagreement, and mapping results across diverse categories and markets. |
| Validation method | Annotate representative evidence and decision contexts using a versioned candidate ontology. |
| Success criteria | Shared upper concepts cover common workflows with domain extensions and acceptable reviewer agreement. |
| Refutation criteria | Material concepts are forced, ambiguous, or systematically lost across categories. |
| Owner | Executive Office — Knowledge Architecture |
| Review gate | Before ontology fields become mandatory |
| Dependencies | A-025, A-035 |
| Replacement/supersession path | Use federated domain ontologies mapped to a smaller shared upper model. |
| Notes | Advanced ontology tables are deferred from Migration 001. |

### A-028 — Cross-language semantic normalization

| Field | Entry |
|---|---|
| Statement | Cross-language semantic normalization can achieve sufficient reliability for BIOS intelligence workflows. |
| Classification | Intelligence quality |
| Current Atlas status | Registered |
| Architecture affected | Evidence, search, entities, taxonomy, findings |
| Why BIOS needs it | BIOS must compare and synthesize evidence across multilingual markets. |
| Risk if wrong | Meaning loss, false matches, biased findings, and unsafe recommendations. |
| Reversibility | High if originals and versioned derivatives are retained. |
| Evidence required | Bilingual expert review sets by language, market, domain, and task. |
| Validation method | Blind evaluation of translation, entity linking, taxonomy mapping, and finding support. |
| Success criteria | Task-specific quality thresholds are met with calibrated confidence and review routing. |
| Refutation criteria | Critical semantic errors remain above approved risk thresholds. |
| Owner | Executive Office — Multilingual Intelligence |
| Review gate | Before automated multilingual findings inform consequential recommendations |
| Dependencies | A-026, A-038 |
| Replacement/supersession path | Limit workflows by language or require human translation/review. |
| Notes | “Sufficient” must be defined per workflow before testing. |

### A-029 — Shared and tenant-private knowledge coexistence

> **PROVISIONAL RECONSTRUCTION — requires Executive Office / Atlas confirmation**

| Field | Entry |
|---|---|
| Statement | Shared reference knowledge and tenant-private knowledge can coexist with explicit scope and provenance boundaries. |
| Classification | Governance architecture |
| Current Atlas status | Proposed |
| Architecture affected | Knowledge scope, tenancy, evidence, provenance |
| Why BIOS needs it | BIOS needs reusable reference context without exposing tenant material. |
| Risk if wrong | Cross-tenant leakage or duplication of all reference knowledge per tenant. |
| Reversibility | Medium; explicit scope fields allow separation or duplication later. |
| Evidence required | Rights, privacy, access-policy, and query tests using mixed-scope cases. |
| Validation method | Threat-model and execute positive/negative access tests on a representative mixed-scope decision context. |
| Success criteria | Shared material is reusable while tenant-private content and inference remain isolated. |
| Refutation criteria | Ownership cannot be resolved or derived outputs leak private information. |
| Owner | Executive Office — Data Governance |
| Review gate | Before any shared/tenant mixed intelligence workflow enters production |
| Dependencies | A-041, A-042 |
| Replacement/supersession path | Physically separate shared and tenant knowledge stores with curated import. |
| Notes | Exact historical wording was not present in supplied approved material. |

### A-030 — Temporal model sufficiency

> **PROVISIONAL RECONSTRUCTION — requires Executive Office / Atlas confirmation**

| Field | Entry |
|---|---|
| Statement | BIOS can represent required system, source, observed, valid, and decision time without a specialized temporal database. |
| Classification | Data architecture |
| Current Atlas status | Proposed |
| Architecture affected | Evidence, entity relationships, findings, decisions, audit |
| Why BIOS needs it | Intelligence must distinguish when something happened, applied, and was known. |
| Risk if wrong | Incorrect historical reconstruction and misleading trend analysis. |
| Reversibility | Medium with append-oriented records and explicit temporal fields. |
| Evidence required | Backdated corrections, uncertain dates, supersession, and historical-as-of queries. |
| Validation method | Implement representative temporal scenarios in PostgreSQL design tests. |
| Success criteria | Required histories and as-of views are reconstructable without destructive edits. |
| Refutation criteria | Core queries require impractical logic or lose valid/system-time distinctions. |
| Owner | Engineering — Data Architecture |
| Review gate | Before Migration 002 intelligence tables |
| Dependencies | A-038, A-039 |
| Replacement/supersession path | Add explicit bitemporal structures or a temporal projection. |
| Notes | Exact historical wording was not present in supplied approved material. |

### A-031 — Cross-context entity model

> **PROVISIONAL RECONSTRUCTION — requires Executive Office / Atlas confirmation**

| Field | Entry |
|---|---|
| Statement | A canonical entity registry can represent relevant actors and objects across markets and domains using governed types and extensions. |
| Classification | Knowledge architecture |
| Current Atlas status | Proposed |
| Architecture affected | Entities, aliases, relationships, markets, domains |
| Why BIOS needs it | Evidence and decisions require stable identity across sources and contexts. |
| Risk if wrong | Duplicate identities, false merges, or category-specific entity tables. |
| Reversibility | Medium if merges are auditable and types are governed data. |
| Evidence required | Entity resolution cases across languages, markets, and categories. |
| Validation method | Curate and resolve a representative entity corpus with human adjudication. |
| Success criteria | Required identities and relationships fit without hard-coded entity subclasses. |
| Refutation criteria | Material entity types need incompatible ownership or identity semantics. |
| Owner | Executive Office — Knowledge Architecture |
| Review gate | Before automated entity merging |
| Dependencies | A-027, A-028, A-035 |
| Replacement/supersession path | Use domain-specific registries mapped to a small shared identity layer. |
| Notes | Exact historical wording was not present in supplied approved material. |

### A-032 — PostgreSQL plus vector capabilities

| Field | Entry |
|---|---|
| Statement | PostgreSQL plus vector capabilities is sufficient for Phase 1 knowledge/intelligence requirements. |
| Classification | Technology architecture |
| Current Atlas status | Registered |
| Architecture affected | Storage, retrieval, search, intelligence |
| Why BIOS needs it | Phase 1 benefits from one canonical store and minimal operating complexity. |
| Risk if wrong | Poor retrieval performance or premature replatforming. |
| Reversibility | High if vectors remain rebuildable projections. |
| Evidence required | Representative corpus size, query mix, relevance, latency, and cost. |
| Validation method | Benchmark PostgreSQL relational and vector retrieval against agreed Phase 1 workloads. |
| Success criteria | Relevance and service targets are met with acceptable operational cost. |
| Refutation criteria | Validated workloads fail targets after reasonable tuning. |
| Owner | Engineering — Platform Architecture |
| Review gate | Before selecting production vector infrastructure |
| Dependencies | A-028, A-031 |
| Replacement/supersession path | Add a specialized search/vector projection behind an owned interface. |
| Notes | Vector infrastructure is not required in Migration 001. |

### A-033 — Specialist agents

| Field | Entry |
|---|---|
| Statement | Specialist agents will eventually justify the additional orchestration complexity. |
| Classification | Agent architecture |
| Current Atlas status | Registered |
| Architecture affected | Agent platform, workflow, audit, human review |
| Why BIOS needs it | Specialized assistance may improve quality and division of analytical work. |
| Risk if wrong | Higher cost, latency, failure modes, and governance burden without better outcomes. |
| Reversibility | High if agents use bounded contracts and canonical records. |
| Evidence required | Controlled comparison against simpler workflows and single-agent baselines. |
| Validation method | Evaluate task quality, provenance, review effort, latency, reliability, and cost. |
| Success criteria | Material net improvement on predefined workflows without unacceptable safety degradation. |
| Refutation criteria | Complexity and cost exceed demonstrated benefit. |
| Owner | Engineering — Agent Platform |
| Review gate | Before multi-agent orchestration becomes a platform dependency |
| Dependencies | A-034, A-043 |
| Replacement/supersession path | Use deterministic workflows or a single bounded assistant. |
| Notes | Agent-run persistence is deferred from Migration 001. |

### A-034 — Human review governs automated intelligence

> **PROVISIONAL RECONSTRUCTION — requires Executive Office / Atlas confirmation**

| Field | Entry |
|---|---|
| Statement | Risk-based human review can provide adequate governance for automated intelligence and agent outputs. |
| Classification | Governance architecture |
| Current Atlas status | Proposed |
| Architecture affected | Human review, agents, recommendations, decisions |
| Why BIOS needs it | BIOS requires accountable use of automation without reviewing every low-risk operation equally. |
| Risk if wrong | Unsafe action, review bottlenecks, or ceremonial approval. |
| Reversibility | High through policy and workflow changes. |
| Evidence required | Review accuracy, disagreement, escalation, throughput, and incident data. |
| Validation method | Pilot tiered review policies on representative workflows. |
| Success criteria | High-risk errors are intercepted within agreed throughput and accountability thresholds. |
| Refutation criteria | Review fails to detect material errors or makes workflows unusable. |
| Owner | Executive Office — Intelligence Governance |
| Review gate | Before external consequential agent actions |
| Dependencies | A-033, A-043 |
| Replacement/supersession path | Require deterministic controls, dual approval, or prohibit automation by risk tier. |
| Notes | Exact historical wording was not present in supplied approved material. |

### A-035 — Domain Packs

| Field | Entry |
|---|---|
| Statement | Domain Packs can support new categories without requiring core schema redesign. |
| Classification | Extension architecture |
| Current Atlas status | Registered |
| Architecture affected | Domains, categories, extensions, ingestion, workflows |
| Why BIOS needs it | New categories must not require platform forks. |
| Risk if wrong | JSONB sprawl, schema churn, or category-specific services. |
| Reversibility | Medium with versioned pack definitions and promotion rules. |
| Evidence required | At least two materially different category implementations. |
| Validation method | Configure taxonomy, attributes, rules, and workflows using the same core schema. |
| Success criteria | New categories require configuration and bounded adapters, not core redesign. |
| Refutation criteria | Stable category requirements cannot be represented or queried safely. |
| Owner | Executive Office — Domain Architecture |
| Review gate | Before a second category is declared supported |
| Dependencies | A-025, A-027 |
| Replacement/supersession path | Add versioned domain modules with explicit contracts. |
| Notes | Flexible attributes need usage evidence before canonical promotion. |

### A-036 — Market Packs

| Field | Entry |
|---|---|
| Statement | Market Packs can capture sufficient market-specific variation without creating market-specific platform forks. |
| Classification | Extension architecture |
| Current Atlas status | Registered |
| Architecture affected | Markets, languages, configuration, sources, policies |
| Why BIOS needs it | BIOS must scale across operational priority markets on one platform. |
| Risk if wrong | Divergent code, control inconsistency, and delayed market onboarding. |
| Reversibility | Medium with bounded pack interfaces. |
| Evidence required | Comparative requirements and configured pilots from dissimilar markets. |
| Validation method | Implement representative language, source, taxonomy, and workflow differences as packs. |
| Success criteria | No core fork; pack behavior remains testable, versioned, and secure. |
| Refutation criteria | Market requirements alter core tenancy, provenance, or decision semantics. |
| Owner | Executive Office — Market Architecture |
| Review gate | Before broad Priority 1 rollout |
| Dependencies | A-026, A-028, A-037 |
| Replacement/supersession path | Introduce regional modules behind common contracts. |
| Notes | Greater China is not a fixed parent market. |

### A-037 — Tenant configuration sufficiency

> **PROVISIONAL RECONSTRUCTION — requires Executive Office / Atlas confirmation**

| Field | Entry |
|---|---|
| Statement | Tenant and workspace variation can be represented through governed configuration without tenant-specific schema forks. |
| Classification | Platform architecture |
| Current Atlas status | Proposed |
| Architecture affected | Tenancy, workspaces, packs, workflow configuration |
| Why BIOS needs it | A multi-tenant product requires customization without divergent deployments. |
| Risk if wrong | Per-client forks, unsafe overrides, and difficult upgrades. |
| Reversibility | Medium if configuration is versioned and bounded. |
| Evidence required | Configuration needs from multiple prospective tenants and workflows. |
| Validation method | Model representative policy and workflow differences using layered configuration. |
| Success criteria | Required variation fits approved settings without weakening platform controls. |
| Refutation criteria | A tenant requires incompatible core data ownership or behavior. |
| Owner | Executive Office — Platform Product |
| Review gate | Before second production tenant |
| Dependencies | A-026, A-036, A-041 |
| Replacement/supersession path | Add isolated deployment profiles or bounded tenant modules. |
| Notes | Exact historical wording was not present in supplied approved material. |

### A-038 — Multilingual provenance model

> **PROVISIONAL RECONSTRUCTION — requires Executive Office / Atlas confirmation**

| Field | Entry |
|---|---|
| Statement | Versioned original and normalized language representations can preserve sufficient semantic provenance for multilingual evidence. |
| Classification | Data architecture |
| Current Atlas status | Proposed |
| Architecture affected | Evidence representations, provenance, review, correction |
| Why BIOS needs it | Users must compare normalized content while retaining the original basis. |
| Risk if wrong | Translation history is lost or decision evidence becomes unverifiable. |
| Reversibility | High with immutable representations and explicit lineage. |
| Evidence required | Correction, retranslation, model-change, and human-review scenarios. |
| Validation method | Reconstruct the exact representation used by findings across version changes. |
| Success criteria | Every derived use resolves to an original and a specific transformation version. |
| Refutation criteria | Provenance is ambiguous or corrections rewrite prior decision context. |
| Owner | Engineering — Data Architecture |
| Review gate | Before multilingual evidence ingestion migration |
| Dependencies | A-028, A-030 |
| Replacement/supersession path | Adopt a richer content-version or event model. |
| Notes | Exact historical wording was not present in supplied approved material. |

### A-039 — Common decision chain

> **PROVISIONAL RECONSTRUCTION — requires Executive Office / Atlas confirmation**

| Field | Entry |
|---|---|
| Statement | Evidence, Signal, Pattern, Finding, Decision Context, Recommendation, and Decision form a sufficiently common traceability chain across BIOS use cases. |
| Classification | Product architecture |
| Current Atlas status | Proposed |
| Architecture affected | Intelligence and decision model |
| Why BIOS needs it | BIOS needs consistent provenance and governance across use cases. |
| Risk if wrong | Forced stages, semantic ambiguity, or use-case-specific shadow models. |
| Reversibility | Medium if stages are separate and links are optional but typed. |
| Evidence required | End-to-end workflows across markets, categories, and decision types. |
| Validation method | Map representative workflows and test provenance reconstruction. |
| Success criteria | Workflows preserve semantics without relabeling or mandatory artificial stages. |
| Refutation criteria | Material workflows require incompatible core objects or relationship meanings. |
| Owner | Executive Office — Product Architecture |
| Review gate | Before intelligence schema becomes stable |
| Dependencies | A-025, A-040 |
| Replacement/supersession path | Define multiple governed workflow patterns sharing a smaller provenance core. |
| Notes | Exact historical wording was not present in supplied approved material. |

### A-040 — Decision Context as primary organizing object

| Field | Entry |
|---|---|
| Statement | Decision Context is the appropriate primary organizing object for BIOS intelligence delivery. |
| Classification | Product architecture |
| Current Atlas status | Registered |
| Architecture affected | Applications, intelligence, recommendations, decisions |
| Why BIOS needs it | Intelligence delivery requires a governed unit centered on a real decision. |
| Risk if wrong | Poor workflow fit, duplicated context, or dashboard-centric delivery. |
| Reversibility | Medium; links can be remapped, but product workflows may become dependent. |
| Evidence required | User research and pilot use across representative decision types. |
| Validation method | Operate decision workflows and measure completeness, reuse, decision quality, and user comprehension. |
| Success criteria | Decision Context consistently organizes required scope, intelligence, stakeholders, and outcomes. |
| Refutation criteria | Another object reliably provides better coherence or contexts become artificial containers. |
| Owner | Executive Office — Product |
| Review gate | Before BIOS Pilot exit |
| Dependencies | A-039, A-041, A-043 |
| Replacement/supersession path | Adopt a case, question, project, or portfolio-centered delivery object and preserve mappings. |
| Notes | Minimal Phase 1 representation is justified; broad primacy is not yet validated. |

## 5. New connecting assumptions

### A-041 — Tenant, client, and workspace relationship

| Field | Entry |
|---|---|
| Statement | Tenant can serve as the primary security boundary while Client remains a distinct unresolved commercial concept and Workspace is modeled as a replaceable tenant-owned organizational scope. |
| Classification | Security architecture |
| Current Atlas status | Registered |
| Architecture affected | Tenancy, identity, authorization, decision contexts |
| Why BIOS needs it | Migration 001 needs a security boundary without prematurely fixing commercial organization. |
| Risk if wrong | Cross-client leakage, forced customer topology, or expensive ownership migration. |
| Reversibility | Medium; workspace semantics are replaceable if tenant ownership is preserved. |
| Evidence required | Executive Office commercial model, prospective tenant structures, authorization journeys. |
| Validation method | Resolve open questions and test membership/scope scenarios with at least two contrasting organizations. |
| Success criteria | One ownership model supports required organizations without cross-tenant records or special-case authorization. |
| Refutation criteria | Security or commercial needs require different ownership boundaries. |
| Owner | Executive Office — Product and Security Architecture |
| Review gate | Before Migration 001 tenant/workspace constraints are finalized |
| Dependencies | A-029, A-037, A-040 |
| Replacement/supersession path | Introduce explicit client organizations and migrate workspace/client relationships while retaining tenant-owned data. |
| Notes | Phase 1 candidate: each workspace belongs to one tenant; users may hold multiple memberships; no cross-tenant decision context. |

### A-042 — Promotion into shared reference knowledge

| Field | Entry |
|---|---|
| Statement | Tenant-private knowledge may eventually be promoted safely into shared reference knowledge through explicit authorization, rights review, de-identification, human approval, and new provenance. |
| Classification | Governance architecture |
| Current Atlas status | Registered |
| Architecture affected | Knowledge scope, evidence, provenance, audit |
| Why BIOS needs it | Reuse may create platform value, but ownership and confidentiality must remain protected. |
| Risk if wrong | Irreversible confidentiality, licensing, or privacy breach. |
| Reversibility | Low after disclosure; therefore promotion is disabled in Phase 1. |
| Evidence required | Legal, contractual, privacy, security, tenant-consent, and provenance analysis. |
| Validation method | Design and threat-model a promotion workflow using synthetic cases before any real promotion. |
| Success criteria | Rights, consent, de-identification, lineage, revocation limits, and approval are demonstrably controlled. |
| Refutation criteria | Source rights or inference leakage cannot be bounded. |
| Owner | Executive Office — Data Governance and Legal |
| Review gate | Before any tenant-derived record becomes shared |
| Dependencies | A-029, A-041 |
| Replacement/supersession path | Prohibit promotion permanently and curate shared sources independently. |
| Notes | No Migration 001 promotion workflow or null-tenant shortcut. |

### A-043 — Human approval for consequential recommendations

| Field | Entry |
|---|---|
| Statement | A recommendation must receive risk-appropriate human approval before it causes an externally consequential action. |
| Classification | Decision governance |
| Current Atlas status | Registered |
| Architecture affected | Recommendations, decisions, human review, agents |
| Why BIOS needs it | Human accountability is a governing engineering principle. |
| Risk if wrong | Unsafe autonomous action or approval bottlenecks that prevent useful operation. |
| Reversibility | High through policy and workflow configuration. |
| Evidence required | Risk taxonomy, decision authority model, review performance, and incident scenarios. |
| Validation method | Pilot review gates at multiple risk levels without enabling autonomous external action. |
| Success criteria | Consequential actions have attributable authorization with workable throughput and escalation. |
| Refutation criteria | Proposed review design provides neither safety nor practical accountability. |
| Owner | Executive Office — Decision Governance |
| Review gate | Before any recommendation triggers an external action |
| Dependencies | A-033, A-034, A-040 |
| Replacement/supersession path | Adopt stronger dual control or prohibit classes of automated action. |
| Notes | Decisions may be recorded without a BIOS recommendation if their external authority is documented. |

## 6. Migration 001 assumption gates

Before Migration 001 is finalized, the Executive Office and Engineering must agree on the provisional boundary in A-041: Tenant is the security boundary and each Phase 1 Workspace, if included, belongs to exactly one Tenant. The following do not need validation before a reduced-scope Migration 001 because they can remain deferred or configurable: A-025–A-028, A-030–A-040, A-042, and A-043.

Migration 001 must preserve replacement paths by avoiding hard-coded category, market, language, client, ontology, vector, agent, and promotion structures.

## 7. Version history

| Version | Date | Change |
|---|---|---|
| 1.0 | 2026-08-02 | Initial canonical architecture assumption register, including provisional reconstructions where historical wording was unavailable |
