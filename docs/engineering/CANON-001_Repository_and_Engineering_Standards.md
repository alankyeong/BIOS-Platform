# CANON-001 — BIOS Repository and Engineering Standards

| Field | Value |
|---|---|
| Document ID | CANON-001 |
| Version | 1.0 |
| Status | Canonical |
| Effective date | 2026-08-01 |
| Owner | BIOS Executive Office — Engineering |
| Normative language | MUST, MUST NOT, SHOULD, SHOULD NOT, MAY |

## 1. Purpose and precedence

This document defines the mandatory repository, naming, documentation, Git, database, quality, and local-development standards for BIOS. It operationalizes [ENG-001](ENG-001_BIOS_Engineering_Handbook.md).

`MUST` and `MUST NOT` are requirements. `SHOULD` and `SHOULD NOT` may be varied only with a documented reason. `MAY` denotes an allowed choice.

When standards conflict, use this precedence:

1. Applicable law, contractual obligations, and approved security policy.
2. Accepted ADRs within their stated decision scope.
3. This canonical standard.
4. The engineering handbook.
5. Module-level guidance and local conventions.

Conflicts MUST be raised and resolved; lower-level guidance MUST NOT silently override a higher authority.

## 2. Canonical repository structure

BIOS uses a monorepo until an accepted ADR decides otherwise.

```text
.
├── README.md
├── apps/
│   └── <application>/
├── packages/
│   └── <package>/
├── services/
│   └── <service>/
├── supabase/
│   ├── config.toml
│   ├── migrations/
│   ├── seed.sql
│   └── tests/
├── docs/
│   ├── architecture/
│   ├── atlas/
│   ├── database/
│   ├── decisions/
│   ├── engineering/
│   ├── operations/
│   └── product/
├── tests/
│   ├── acceptance/
│   ├── integration/
│   └── security/
├── tools/
├── .github/
│   ├── ISSUE_TEMPLATE/
│   ├── workflows/
│   └── CODEOWNERS
├── .editorconfig
├── .gitignore
└── <root toolchain manifests>
```

### 2.1 Directory ownership

| Path | Purpose | Rule |
|---|---|---|
| `apps/` | Deployable user interfaces and application entry points | MUST consume owned platform contracts |
| `packages/` | Reusable libraries, schemas, clients, and design primitives | MUST have a clear owner and public surface |
| `services/` | Independently operated backend processes | MUST define ownership and operational expectations |
| `supabase/` | Canonical local backend configuration and database history | MUST be sufficient to reconstruct local database state |
| `docs/` | Versioned product, engineering, and governance knowledge | MUST use the document system in section 4 |
| `tests/` | Cross-component acceptance, integration, and security suites | MUST NOT duplicate tests better owned beside a module |
| `tools/` | Repository automation and developer utilities | MUST be documented and safe by default |

Directories SHOULD be created when needed. Empty directory scaffolding is not required. A new top-level directory requires an update to this standard or an accepted ADR.

### 2.2 Module standard

Each deployable application, service, or substantial package MUST contain:

- a `README.md` describing purpose, owner, interfaces, local commands, and dependencies;
- an explicit public entry point or interface boundary;
- tests proportionate to risk;
- configuration validation and an example when configuration exists;
- no undocumented dependency on another module’s private implementation.

## 3. Naming standards

### 3.1 General

- Names MUST use clear domain language from the canonical glossary.
- Avoid unexplained abbreviations and overloaded terms.
- Source directories and file names SHOULD use lowercase `kebab-case`, except where the language or framework has an established convention.
- Code identifiers MUST follow the formatter and idioms of their language.
- Environment variables MUST use uppercase `SNAKE_CASE` and a `BIOS_` prefix for BIOS-owned global configuration.
- Feature flags SHOULD use `<domain>.<capability>.<behavior>` and MUST have an owner and removal condition.

### 3.2 Database

- Schemas, tables, columns, indexes, constraints, and policies MUST use lowercase `snake_case`.
- Table names SHOULD be plural nouns; join tables SHOULD combine the two plural concepts in stable alphabetical or domain-natural order.
- Primary keys MUST be named `id`; foreign keys MUST be named `<singular>_id`.
- Tenant-scoped tables MUST expose `tenant_id` unless an accepted data-model decision defines an equally explicit ownership path.
- Timestamps MUST use timezone-aware types and names such as `created_at`, `updated_at`, and domain-specific `<event>_at`.
- Boolean names SHOULD describe a positive predicate, such as `is_active`.
- Constraint and index names MUST be deterministic and descriptive.
- Migration file names MUST follow the Supabase timestamp convention: `<UTC timestamp>_<short_description>.sql`.

Stable identifiers MUST NOT encode mutable market, category, tenant, or organizational meaning.

## 4. Documentation system

### 4.1 Document families

| Prefix | Family | Location | Example purpose |
|---|---|---|---|
| `ENG` | Engineering handbook or policy | `docs/engineering/` | Engineering lifecycle |
| `CANON` | Mandatory canonical standard | Relevant canonical folder | Repository rules |
| `ARCH` | Architecture description | `docs/architecture/` | Platform structure and flows |
| `ADR` | Architecture decision record | `docs/decisions/` | Durable technical decision |
| `DB` | Canonical data model | `docs/database/` | Entities, relationships, invariants |
| `ATLAS` | Assumption and validation record | `docs/atlas/` | Architecture assumption register |
| `PRD` | Product requirement | `docs/product/` | Outcome and acceptance criteria |
| `RUN` | Operational runbook | `docs/operations/` | Repeatable operating procedure |

Document identifiers are allocated sequentially within a family and MUST NOT be reused. Filenames use `<PREFIX>-<NNN>_<Title_With_Underscores>.md`. The repository `README.md` is the intentional exception.

### 4.2 Required metadata

Canonical documents MUST state:

- document ID;
- version;
- status;
- effective or decision date;
- accountable owner;
- version history.

Documents SHOULD link to canonical definitions rather than copy them. Relative links MUST resolve in repository rendering.

### 4.3 Status and versioning

Standard document states are `Draft`, `In Review`, `Canonical`, `Deprecated`, and `Superseded`. ADRs use `Proposed`, `Accepted`, `Rejected`, `Deprecated`, and `Superseded`. Atlas uses its lifecycle defined in ENG-001.

Canonical document versions follow semantic intent:

- **Major:** changes authority, meaning, obligations, or architecture materially.
- **Minor:** adds compatible guidance or clarifies a new supported case.
- **Patch:** corrects wording, links, or non-semantic errors.

Material updates MUST include review and a version-history entry. Accepted ADR decisions MUST be superseded by a new ADR, not reversed in place.

## 5. Architecture and decision records

Architecture MUST preserve the separation of tenants, markets, categories, domains, and entities. The canonical intelligence flow is:

```text
Evidence → Signal → Pattern → Finding → Decision Context → Recommendation → Decision
```

Implementations MAY skip a derived stage when a use case does not require it, but MUST NOT mislabel one stage as another or sever provenance.

An ADR MUST be created before merging a material and durable decision involving:

- system boundaries or data ownership;
- database or infrastructure technology;
- authentication, authorization, or tenant isolation;
- public or cross-module contracts;
- major dependency or vendor commitment;
- material operating cost, resilience, or data-residency trade-offs.

ADRs MUST include context, drivers, decision, options, consequences, risks, validation, and revisit triggers.

## 6. Git standards

### 6.1 Branches

- `main` MUST be protected and releasable.
- Work MUST occur on short-lived branches.
- Branch names MUST follow `<type>/<issue>-<description>` when an issue exists, or `<type>/<description>` during repository bootstrap.
- Allowed types are `feat`, `fix`, `docs`, `refactor`, `test`, `build`, `ci`, `chore`, `perf`, and `revert`.
- Branches SHOULD be updated from `main` before merge and deleted after merge.

### 6.2 Commits

Commit subjects MUST follow Conventional Commits:

```text
<type>(<optional-scope>): <imperative summary>
```

Commits MUST NOT contain secrets, generated build output, editor state, production data, or unrelated changes. A commit SHOULD represent one coherent reason for change.

### 6.3 Pull requests

Every non-emergency change to `main` MUST use a pull request. The pull request MUST include:

- problem and intended decision outcome;
- summary of the implementation;
- verification evidence;
- tenant, market, and category impact where relevant;
- security, privacy, migration, rollout, and rollback considerations;
- linked issue, PRD, ADR, or Atlas record where applicable.

At least one qualified approval and all required automated checks are required. The author MUST NOT be the sole approver. CODEOWNERS review is required for owned critical areas.

## 7. Code and dependency standards

- Each language MUST have one repository-pinned formatter and linter.
- Formatting MUST be automated; style debates SHOULD be resolved by tooling.
- Public functions, modules, and contracts MUST communicate intent through types and concise documentation.
- Inputs MUST be validated at trust boundaries.
- Errors MUST preserve diagnostic context without leaking secrets or sensitive data.
- Dependencies MUST be pinned through the ecosystem lockfile, reviewed for purpose and risk, and updated deliberately.
- Core domain behavior MUST NOT depend directly on user-interface state or a vendor SDK.
- Dead code, expired flags, and temporary compatibility paths MUST have a tracked removal condition.

Language-specific standards MAY be added under `docs/engineering/` when the stack is selected.

## 8. Database and tenancy standards

[ADR-001](../decisions/ADR-001_PostgreSQL_and_Supabase.md) governs the initial platform choice.

- The repository migration history is authoritative.
- Every tenant-scoped access path MUST establish an authorized tenant context.
- Row Level Security MUST be enabled and tested on tenant-scoped tables exposed through Supabase APIs.
- Policies MUST deny access when identity or tenant context is absent.
- Cross-tenant operations MUST use named privileged roles or workflows and create audit evidence.
- Canonical market and category registries MUST be independent of tenants; tenant customization MUST use explicit mappings.
- Foreign keys, uniqueness constraints, and checks MUST enforce durable invariants in the database.
- Sensitive changes MUST include forward and recovery procedures.
- Seed data MUST be synthetic, deterministic where practical, and safe to commit.
- Tests MUST prove both allowed and denied behavior for representative roles.

## 9. Project Atlas standards

A change MUST link an Atlas item when it depends on a material unvalidated assumption. The item MUST be falsifiable and define evidence and success criteria before testing.

Validated Atlas evidence MAY justify implementation or promotion. It MUST NOT override tenant isolation, security, legal, or documentation requirements. Refuted and superseded items remain discoverable so the organization retains what it learned.

Architecture intended for broad use SHOULD be tested across representative tenants, at least two markets, and at least two categories before being described as generally validated. A narrower pilot MUST state its scope and limits.

## 10. Testing and quality gates

### 10.1 Required test layers

- Unit tests for domain rules and deterministic transformations.
- Integration tests for database, service, external adapter, and authorization boundaries.
- Policy tests for tenant isolation and privileged operations.
- Migration tests from a clean database and supported upgrade paths.
- End-to-end tests for a small set of critical decision journeys.
- Evaluation suites for agent and intelligence quality when those capabilities are introduced.

### 10.2 Required merge gates

The continuous-integration baseline MUST include:

1. formatting verification;
2. linting and static or type checks;
3. unit and integration tests;
4. database migration and policy tests when relevant;
5. dependency and secret scanning;
6. build verification;
7. documentation link or structure checks when available.

Flaky tests MUST be treated as defects. A test MAY be quarantined only with an owner, tracked issue, reason, and target resolution date.

## 11. Local-first development

Routine development MUST be possible without production connectivity or credentials. The repository MUST eventually provide one documented command or task per common action, including setup, start, stop, format, lint, test, migrate, seed, and reset of local development state.

- Tool versions MUST be pinned or declared.
- `.env.example` files MAY contain names and safe defaults but MUST NOT contain secrets.
- Personal `.env` files MUST be ignored.
- Local services SHOULD run through reproducible containers or equivalent pinned tooling.
- Local database reset MUST target only the local environment and be visibly guarded.
- Clean-clone setup SHOULD reach a verified running state in under 30 minutes once the application stack exists.
- CI SHOULD run the same underlying checks as local commands.

## 12. Security, privacy, and AI safety

- Access MUST use least privilege and deny by default.
- Secrets and sensitive data MUST NOT enter Git history, logs, analytics payloads, test fixtures, or AI prompts without explicit authorization and controls.
- New trust boundaries and sensitive data flows MUST receive threat modeling.
- Dependencies and build workflows MUST use reviewed sources and scoped credentials.
- Logs MUST be structured, attributable, and redacted.
- Agent tools MUST be scoped by tenant, purpose, and action; consequential actions require the appropriate human approval.
- Generated intelligence MUST retain source references, execution metadata, uncertainty, and review state where applicable.

## 13. Releases and operations

- Build once and promote the same immutable artifact through environments.
- Releases MUST be traceable to source revision and migrations.
- Production changes MUST have an owner, verification method, and rollback or recovery plan proportionate to risk.
- User-visible and operationally material changes MUST have release notes.
- Services MUST define health signals and operational ownership before production use.
- Backup restoration MUST be exercised on a documented cadence before backups are relied upon.
- Incidents MUST generate tracked corrective actions; reviews focus on system improvement rather than blame.

## 14. Exceptions

An exception request MUST state the rule, justification, risk, scope, owner, compensating control, expiry or exit condition, and approver. Exceptions MUST be stored in a discoverable issue, ADR, or canonical exception register. Convenience alone is not sufficient justification for weakening tenant isolation, security, provenance, or auditability.

## 15. Initial repository acceptance checklist

The engineering foundation is ready for feature development when:

- the canonical documents are approved and linked from the root README;
- branch protection and review ownership are configured;
- the toolchain and common local commands are pinned and documented;
- local Supabase starts from repository configuration;
- the initial migrations establish explicit tenant, market, and category foundations;
- automated migration, isolation, and baseline quality checks run in CI;
- secrets and environment patterns are documented and ignored;
- `ARCH-001`, `DB-001`, and `ATLAS-001` are approved or tracked as explicit prerequisites.

## 16. Version history

| Version | Date | Change |
|---|---|---|
| 1.0 | 2026-08-01 | First canonical repository and engineering standard |
