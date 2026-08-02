# ENG-001 — BIOS Engineering Handbook

| Field | Value |
|---|---|
| Document ID | ENG-001 |
| Version | 1.0 |
| Status | Canonical |
| Effective date | 2026-08-01 |
| Owner | BIOS Executive Office — Engineering |
| Review cadence | At least annually and after material architecture change |

## 1. Purpose

This handbook is the engineering constitution for the BRG Intelligence Operating System (BIOS). It defines how BIOS is designed, built, reviewed, operated, and changed so that the platform can safely grow from a small founding team to a multi-team engineering organization.

It governs all production code, database changes, infrastructure definitions, technical documentation, automated agents, and delivery workflows in the BIOS repository. Detailed mandatory conventions are delegated to [CANON-001](CANON-001_Repository_and_Engineering_Standards.md).

## 2. Product and architecture context

BIOS serves the Executive Office by converting governed evidence into decision-ready intelligence. The platform is organized around the traceable decision chain:

```text
Evidence → Signal → Pattern → Finding → Decision Context → Recommendation → Decision
```

The architecture has six cooperating layers:

1. **Engineering foundation** — environments, security, quality, delivery, and observability.
2. **Canonical platform** — tenants, identities, markets, categories, domains, entities, and governed records.
3. **Knowledge architecture** — provenance, classification, semantics, and relationships.
4. **Intelligence platform** — evidence ingestion, signals, patterns, findings, and decision contexts.
5. **Agent platform** — bounded agent assistance, criticism, and human review.
6. **Applications** — dashboards, decision briefs, evidence rooms, and executive workflows.

Higher layers depend on stable contracts below them. Applications must not recreate canonical business rules or create shadow systems of record.

## 3. Engineering principles

### 3.1 Optimize for decisions

Begin with the decision, user, and outcome. A feature without a defined decision contribution is not ready for implementation.

### 3.2 Preserve evidence and provenance

Material outputs must be traceable to sources, transformations, model or rule versions, reviewers, and timestamps. Derived intelligence must not overwrite its inputs.

### 3.3 Make isolation structural

BIOS is multi-tenant from the first schema and request path. Tenant isolation is enforced in the database and verified in tests; user-interface filtering is not a security boundary.

### 3.4 Model market and category explicitly

Markets and categories are independent, governed dimensions with stable identifiers. Cross-market and cross-category analysis is represented by relationships, not duplicated records or free-text labels.

### 3.5 Prefer a canonical core

Core concepts have one authoritative definition and owner. Variation belongs in configuration, policy, or extension points. Tenant-specific forks of core behavior require explicit architecture approval.

### 3.6 Validate assumptions through Atlas

Architectural and product assumptions with material decision impact are registered in Project Atlas. Experiments produce evidence; they do not quietly redefine the platform.

### 3.7 Keep humans accountable

Agents may collect, classify, summarize, challenge, and propose. Consequential recommendations and decisions require the human review appropriate to their risk. Agent actions must be observable and attributable.

### 3.8 Build locally, promote deliberately

Routine development, migrations, and tests must run in a reproducible local environment. The same versioned artifacts are promoted through shared environments. Production is never the development environment.

### 3.9 Design for reversibility

Prefer small changes, compatible interfaces, feature controls, and expand/migrate/contract database evolution. Irreversible choices require stronger evidence and approval.

### 3.10 Secure and operate by design

Security, privacy, auditability, accessibility, observability, and recovery are acceptance criteria—not later enhancements.

## 4. Canonical domain boundaries

| Concept | Canonical meaning |
|---|---|
| Tenant | The primary security and ownership boundary for customer or organizational data |
| Market | A governed geographic or commercial market dimension |
| Category | A governed product, service, or analytical category dimension |
| Domain | A governed subject area within which intelligence is organized |
| Entity | An identifiable organization, person, product, brand, place, or other analyzed object |
| Evidence | A preserved source item or observation with provenance and classification |
| Signal | A noteworthy evidence-backed change or indicator |
| Pattern | A supported relationship or recurrence across signals |
| Finding | An analytical conclusion supported by evidence and reasoning |
| Decision context | The governed package of question, scope, evidence, findings, constraints, and stakeholders for a decision |
| Recommendation | A proposed action with rationale, assumptions, alternatives, and confidence |
| Decision | An authorized choice with owner, date, rationale, and follow-up obligations |

The forthcoming `DB-001` owns precise data definitions. Until it is approved, implementations must preserve these distinctions and flag unresolved semantics in Atlas.

## 5. Project Atlas validation

Atlas is the platform’s assumption register and validation system. Register an assumption when it could materially affect architecture, security, data semantics, user value, cost, or delivery sequencing.

Every registered assumption should include:

- a falsifiable statement;
- the decision or design it influences;
- affected tenants, markets, categories, or layers;
- risk and reversibility;
- owner and review date;
- validation method and success criteria;
- supporting and contradicting evidence;
- current state and resulting action.

Atlas states are `Proposed`, `Registered`, `Testing`, `Validated`, `Refuted`, and `Superseded`. Validation supports a decision; it does not prove universal truth. Important assumptions are revisited when scope or evidence changes.

## 6. Development lifecycle

### 6.1 Shape

Define the decision outcome, users, scope, acceptance criteria, risks, data classification, tenant implications, and operational impact. Create or link the relevant issue, specification, ADR, and Atlas items.

### 6.2 Design

Identify the owning module, contracts, data changes, authorization policy, failure modes, observability, rollout, and rollback. Write an ADR before implementation when the choice is material, durable, or difficult to reverse.

### 6.3 Implement

Work in a short-lived branch. Keep changes cohesive, preserve backward compatibility where practical, add versioned migrations, and update documentation in the same change.

### 6.4 Verify

Run formatting, static analysis, unit tests, integration tests, migration tests, and applicable security and tenant-isolation tests. Decision-chain features also require provenance and audit assertions.

### 6.5 Review

At least one qualified reviewer approves the change. Security-sensitive, tenant-boundary, production-data, and destructive migration changes require review from the accountable owner for that area.

### 6.6 Release

Merge only after required checks pass. Promote the same immutable artifact through environments. Use observable, reversible rollout methods and record release notes for user-visible or operationally material changes.

### 6.7 Learn

Observe adoption, correctness, reliability, and decision impact. Feed new evidence into product work, incident follow-ups, documentation, and Atlas. Do not treat shipment as validation.

## 7. Git and review workflow

- The default branch is `main` and must remain releasable.
- Direct pushes to `main` are prohibited except under a documented emergency procedure.
- Use short-lived branches named `<type>/<issue>-<description>`, for example `feat/142-evidence-ingestion`.
- Use Conventional Commit subjects: `feat`, `fix`, `docs`, `test`, `refactor`, `perf`, `build`, `ci`, `chore`, or `revert`.
- Each pull request explains why, what changed, how it was verified, risks, migration or rollback needs, and linked records.
- Prefer squash merging for a clear mainline unless preserving a structured commit series has explicit value.
- Do not merge with failing required checks, unresolved material comments, or undocumented schema changes.
- Emergency changes follow the same audit and testing expectations, with retrospective review immediately afterward.

## 8. Environments and configuration

The standard environment path is `local → development → staging → production`. Additional ephemeral preview environments may be used when their data and access are controlled.

- Configuration is supplied by environment, validated at startup, and documented in a versioned example file.
- Secrets are stored in an approved secret manager or local ignored file; never in source control, logs, fixtures, screenshots, or prompts.
- Local development uses synthetic or explicitly approved de-identified data.
- Environment-specific behavior must not be implemented as divergent source branches.
- Database state is recreated from migrations and seed scripts, not an engineer’s private snapshot.

## 9. Data, database, and tenancy

PostgreSQL is the canonical transactional data store and Supabase is the initial platform layer, as decided in [ADR-001](../decisions/ADR-001_PostgreSQL_and_Supabase.md).

Mandatory rules:

- Use stable generated identifiers; do not encode mutable business meaning in primary keys.
- Carry tenant ownership on tenant-scoped records and preserve it across derived records.
- Enforce authorization using database policies and server-side checks.
- Treat missing tenant context as denial, not global access.
- Apply schema changes through ordered, immutable migrations committed to the repository.
- Prefer additive migrations; separate destructive contraction until usage and rollback have been verified.
- Record source, lineage, timestamps, and responsible actor for governed records.
- Define retention, deletion, and residency behavior before storing sensitive or regulated data.
- Backups are not considered usable until restoration is tested.

## 10. APIs and module contracts

Contracts are explicit, versioned when externally consumed, and owned by one module. Inputs are validated at trust boundaries. Errors are safe for users and actionable for operators. Idempotency is required for retried writes where duplication would be harmful.

Shared packages may contain stable cross-cutting primitives, but not become an unowned dumping ground. Direct reads across another module’s private tables are prohibited unless documented as an approved transitional design.

## 11. Intelligence and agent engineering

Automated intelligence must record, as applicable, model or rule identity, prompt or configuration version, source references, execution time, confidence or uncertainty, and human review state.

- Separate observed evidence from generated interpretation.
- Do not present generated content as verified fact.
- Constrain tool access and data scope to the task and tenant.
- Evaluate quality across representative markets, categories, languages, and tenant configurations.
- Test for unsupported claims, provenance loss, prompt injection, data leakage, and unsafe tool actions.
- Require human approval for externally consequential or high-risk actions.
- Preserve corrections and reviewer feedback as auditable events.

## 12. Quality strategy

Testing follows risk, with a broad base of fast unit and policy tests, focused integration tests at real boundaries, and a small set of critical end-to-end journeys.

Every change must consider:

- correctness and edge cases;
- tenant isolation and authorization;
- market and category scope;
- provenance and auditability;
- accessibility and supported interfaces;
- performance and cost at expected scale;
- failure, retry, recovery, and rollback behavior.

A defect that can expose one tenant’s data to another is a release blocker and security incident, regardless of likelihood.

## 13. Security and privacy

Use least privilege, deny-by-default access, strong identity controls, dependency and secret scanning, encrypted transport, and appropriate encryption at rest. Classify data before use. Collect only what is needed for an approved purpose.

Threat modeling is required for new trust boundaries, authentication or authorization changes, external ingestion, agent tool use, and sensitive data flows. Vulnerabilities are triaged by impact and exploitability, with remediation targets defined in the security standard when adopted.

## 14. Observability and operations

Production services must provide structured logs, metrics, health signals, and trace or correlation identifiers appropriate to their risk. Telemetry must include tenant-safe context without exposing sensitive content.

Each operated service needs a named owner, service expectations, dependency map, alert route, and recovery procedure before production use. Incidents prioritize safety and restoration, followed by a blameless review and tracked corrective actions.

## 15. Documentation and decisions

Documentation is part of the product. Update it in the same pull request as the behavior it describes. Prefer links to duplication and use stable document identifiers defined in CANON-001.

An ADR is required for decisions that materially affect platform structure, data ownership, security boundaries, technology selection, interoperability, or long-term operating cost. Accepted ADRs are not edited to reverse their decision; create a new ADR that supersedes them.

## 16. Definition of done

A change is done when:

- acceptance criteria and decision outcome are satisfied;
- code and migrations meet canonical standards;
- applicable tests pass, including isolation and provenance checks;
- security, privacy, accessibility, and operational impacts are addressed;
- documentation, contracts, ADRs, and Atlas records are current;
- telemetry and ownership are sufficient to operate the change;
- rollout and rollback are understood;
- required reviewers have approved it.

## 17. Exceptions and governance

Standards may be varied only when the exception is explicit, time-bounded where possible, risk-assessed, and approved by the accountable owner. Record material exceptions in an ADR or tracked engineering-debt item with an owner and exit condition.

This handbook is maintained by BIOS Engineering and approved by the BIOS Executive Office. More specific canonical standards govern within their scope. Conflicts must be raised; silent local conventions do not override canonical documents.

## 18. Version history

| Version | Date | Change |
|---|---|---|
| 1.0 | 2026-08-01 | First canonical engineering foundation |
