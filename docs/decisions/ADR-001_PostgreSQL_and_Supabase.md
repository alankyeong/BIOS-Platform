# ADR-001 — PostgreSQL and Supabase for the BIOS Canonical Platform

| Field | Value |
|---|---|
| Document ID | ADR-001 |
| Version | 1.0 |
| Status | Accepted |
| Decision date | 2026-08-01 |
| Owners | BIOS Executive Office — Architecture and Engineering |
| Scope | Canonical transactional database and initial backend platform |

## Context

BIOS needs a trustworthy foundation for multi-tenant, multi-market, and multi-category intelligence. Its core records are strongly related: tenants, markets, categories, domains, entities, evidence, signals, patterns, findings, decision contexts, recommendations, decisions, reviews, and provenance.

The first engineering phase also needs rapid local setup, versioned database evolution, authentication, authorization close to the data, and a credible path from a small founding team to a larger engineering organization. Routine work must not depend on an always-online proprietary development environment.

This ADR decides the initial canonical transactional platform. It does not decide every future storage need. Search indexes, object storage, analytical warehouses, caches, queues, graph projections, or vector indexes may be added behind explicit contracts when validated needs justify them.

## Decision drivers

- Strong relational integrity and transactions for governed decision records.
- Expressive modeling of many-to-many scope across tenants, markets, categories, domains, and entities.
- Enforceable tenant isolation at the data layer.
- Durable provenance, audit, and temporal metadata.
- Reproducible local development and testing.
- Version-controlled schema migrations.
- Fast delivery of authentication, API, storage, and event capabilities without surrendering database portability.
- Broad skills ecosystem, mature tooling, and an operational path beyond a single vendor.
- Support for extensions where justified, without making extensions the canonical data model.

## Decision

BIOS will use **PostgreSQL as its canonical transactional database** and **Supabase as its initial PostgreSQL-centered backend platform**.

The repository will contain the authoritative database migrations, policy definitions, local configuration, and non-sensitive seed data under `supabase/`. Developers will run the supported Supabase stack locally. Hosted Supabase environments may provide managed PostgreSQL and platform services for shared development, staging, and production.

PostgreSQL remains the system of record. Supabase services are adopted selectively and accessed through owned application boundaries so that convenience features do not obscure data ownership or make core domain logic dependent on generated interfaces.

## Mandatory implementation constraints

### Tenant isolation

- Every tenant-scoped table carries a non-null tenant identifier or derives ownership through an equally explicit, approved relationship.
- Row Level Security is enabled and policy-tested for exposed tenant-scoped tables.
- Application and service authorization supplements database policy; it does not replace it.
- Service-role credentials are restricted to trusted server-side operations and never distributed to clients.
- Cross-tenant administration and analysis use explicit privileged workflows with audit records.
- Shared reference data is modeled and governed explicitly; absence of a tenant identifier does not imply public access.

### Market and category design

Markets and categories use independent canonical registries with stable identifiers and lifecycle metadata. Records spanning multiple markets or categories use explicit association tables. Tenant-specific aliases or configurations may extend canonical registries without duplicating their identity.

### Provenance and decisions

Derived intelligence retains references to supporting evidence and relevant transformation, rule, model, and review metadata. Database constraints protect invariants that must hold regardless of application path. Audit history is append-oriented where reconstruction or accountability is required.

### Schema evolution

- All changes use ordered SQL migrations committed to source control.
- Applied migrations are immutable; corrections are new migrations.
- Local environments must be rebuildable from the repository.
- Production changes favor expand/migrate/contract sequencing.
- Destructive changes require an impact analysis, verified backup and restore posture, and a rollback or recovery plan.
- Ad hoc production or hosted-console schema changes are prohibited except during a documented incident and must be reconciled immediately afterward.

### Portability and boundaries

- Domain code uses owned repositories or service boundaries rather than spreading vendor SDK calls throughout the codebase.
- PostgreSQL-standard capabilities are preferred for canonical behavior.
- Supabase-specific features require tests, documentation, and an understood exit cost.
- Generated APIs are not automatically approved as public or cross-module contracts.

## Local-first operating model

The local stack is the default place to develop and validate database behavior. It must support migrations, seed data, authentication flows, storage emulation where needed, and policy tests without production access.

Shared environments validate integration, deployment, and managed-service behavior. The same committed migrations move from local through development, staging, and production. Secrets and environment configuration remain outside version control.

## Options considered

### PostgreSQL without Supabase

This offers maximum platform control and fewer platform-specific dependencies, but requires the founding team to assemble and operate authentication, local orchestration, storage integration, APIs, and administrative tooling earlier. It remains a viable future operating mode because PostgreSQL is canonical, but it is not the fastest responsible starting point.

### Firebase or another document-first backend

These platforms can accelerate real-time application development, but BIOS has a relational, governance-heavy domain with many cross-cutting integrity and audit requirements. Modeling those relationships and enforcing tenant-aware analytical constraints would be less natural and could increase application-level complexity.

### Cloud-vendor proprietary database stack

Deep integration may offer strong scale and operations, but would increase early platform complexity, weaken local parity, and create unnecessary lock-in before Atlas validates those needs.

### Distributed SQL database

Distributed SQL may eventually help with geographic scale or resilience. It introduces operational and design complexity that is not justified by current validated requirements. BIOS will measure scale, residency, and availability needs before considering it.

### Multiple databases from the outset

Polyglot persistence can optimize specific workloads but creates synchronization, ownership, and operating burdens. BIOS will begin with one canonical store and add projections only for demonstrated workloads.

## Consequences

### Positive

- Relational constraints and transactions align with the BIOS decision and provenance model.
- Row Level Security provides a defense-in-depth mechanism for tenant isolation.
- Supabase accelerates local development and initial platform capabilities.
- SQL migrations create a reviewable, reproducible database history.
- PostgreSQL reduces the cost of moving between managed providers or self-managed operation.
- The ecosystem supports future search, vector, geospatial, and analytical extensions when validated.

### Negative and risks

- Row Level Security is powerful but easy to misconfigure; policy tests and review are mandatory.
- Supabase convenience interfaces can encourage accidental coupling or excessive client access.
- Local containers and platform tooling add workstation resource requirements.
- PostgreSQL can become a monolith if module ownership and access boundaries are ignored.
- Analytical or high-volume ingestion workloads may eventually require projections or specialized stores.
- Managed-service features still create exit costs even when the underlying database is portable.

## Risk controls and validation

Project Atlas will validate at least the following assumptions before they become irreversible commitments:

| Assumption | Validation signal |
|---|---|
| PostgreSQL adequately represents the canonical decision chain | Representative schema and decision-brief pilot preserve required relationships and provenance |
| RLS can enforce tenant isolation safely | Automated positive and negative policy tests across representative roles and cross-tenant attempts |
| Market and category registries support real portfolio variation | Atlas pilot covers multiple markets and categories without schema forks |
| Local Supabase provides acceptable developer parity | Clean-machine setup, migration replay, and integration tests succeed consistently |
| Supabase-specific coupling remains controlled | Architecture review can identify bounded adapters and documented exit costs |
| Initial performance is sufficient | Representative ingestion and decision queries meet agreed service targets |

Refuted assumptions trigger redesign, a superseding ADR, or a deliberately scoped exception. They are not concealed by changing success criteria after the test.

## Security and operational implications

Before production use, the team must establish environment separation, credential rotation, backup and restore tests, monitoring, incident access, audit retention, and recovery targets. Data residency and retention requirements are evaluated per tenant and market before sensitive data is stored.

## Revisit triggers

Create a new ADR to revisit this decision if any of the following becomes material:

- validated scale or availability cannot be met responsibly;
- legal or residency requirements cannot be satisfied;
- tenant isolation cannot be demonstrated with acceptable assurance;
- managed-platform coupling materially constrains product or operations;
- specialized workloads justify an additional system of record or projection;
- total cost materially exceeds validated alternatives.

## Supersession policy

This accepted ADR remains as historical evidence. A future decision must be recorded in a new ADR that references and supersedes ADR-001; this document must not be rewritten to imply the earlier decision was different.

## Version history

| Version | Date | Change |
|---|---|---|
| 1.0 | 2026-08-01 | Initial accepted decision |
