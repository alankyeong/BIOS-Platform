# BIOS — BRG Intelligence Operating System

> A decision-centric intelligence platform for turning governed evidence into traceable decisions across markets, categories, and clients.

| Document status | Value |
|---|---|
| Version | 1.0 |
| Status | Canonical |
| Effective date | 2026-08-01 |
| Owner | BIOS Executive Office |

## What BIOS is

BIOS is the shared intelligence operating system of the BRG Executive Office. It is designed to help decision-makers understand a situation, test assumptions, choose an action, and retain the evidence and reasoning behind that choice.

BIOS is not a collection of disconnected dashboards or an ungoverned document repository. It is a platform in which evidence, signals, patterns, findings, decision contexts, recommendations, and decisions remain connected and auditable.

## Product principles

- **Decision-centric:** every capability must improve a defined decision or its traceability.
- **Evidence-led:** important claims must be attributable to governed evidence.
- **Multi-tenant by design:** tenant boundaries are explicit and enforced at every layer.
- **Multi-market and multi-category:** market and category are first-class dimensions, not labels added later.
- **Canonical core, configurable edge:** shared concepts remain stable while tenant, market, and category behavior is configurable.
- **Human-accountable intelligence:** automation may assist analysis; authorized people remain accountable for consequential decisions.
- **Atlas-validated:** material assumptions are registered, tested, and promoted only with evidence.
- **Local-first engineering:** routine development and validation must work locally before reliance on hosted environments.

## Platform architecture

```text
Executive Office decisions and workflows
                    ↑
Applications: dashboards, briefs, evidence room, review
                    ↑
Agent platform: evidence, signal, intelligence, critic, human review
                    ↑
Intelligence platform: signals, patterns, findings, decision contexts
                    ↑
Knowledge architecture: provenance, taxonomy, relationships, semantics
                    ↑
Canonical platform: tenants, markets, categories, domains, entities, evidence
                    ↑
Engineering foundation: standards, security, environments, tests, delivery
```

The canonical decision chain is:

```text
Evidence → Signal → Pattern → Finding → Decision Context → Recommendation → Decision
```

Each step must preserve provenance to preceding steps. A presentation may summarize the chain, but it must not become the system of record.

## Tenancy and analytical scope

Every tenant-scoped record belongs to exactly one tenant. Access is denied unless tenant context is established and authorized. Shared reference data is explicitly designated; it is never shared merely because a tenant identifier is absent.

Markets and categories are independently governed registries. A decision context can span one or more markets and categories through explicit relationships. Domains describe the business subject being analyzed; entities describe identifiable actors or objects. These concepts must not be collapsed into one generic tag system.

## Project Atlas

Project Atlas is the validation discipline for BIOS. It keeps assumptions visible and prevents untested architecture or product beliefs from silently becoming permanent design constraints.

An Atlas item records an assumption, its decision impact, validation method, evidence, owner, and state. The standard lifecycle is:

```text
Proposed → Registered → Testing → Validated | Refuted | Superseded
```

Validation is proportional to reversibility and risk. A refuted assumption is a useful result and must remain in the history. Atlas validates the architecture; it does not bypass engineering or decision governance.

## Repository map

```text
.
├── README.md
├── apps/                   # User-facing applications
├── packages/               # Reusable product and platform modules
├── services/               # Independently operated backend services
├── supabase/               # Local backend config, migrations, seed data
├── docs/
│   ├── architecture/       # ARCH documents
│   ├── database/           # DB documents
│   ├── decisions/          # ADR documents
│   ├── engineering/        # ENG and CANON documents
│   ├── atlas/              # ATLAS assumption register and evidence
│   ├── product/            # Product specifications
│   └── operations/         # Runbooks and operational standards
├── tests/                  # Cross-system and acceptance tests
├── tools/                  # Developer tooling and automation
└── .github/                # Review and delivery workflows
```

Directories are created when first needed; empty placeholders are not required. The detailed rules are defined in [CANON-001](docs/engineering/CANON-001_Repository_and_Engineering_Standards.md).

## Local development

The initial backend standard is PostgreSQL delivered locally through Supabase. Before application code is introduced, the repository will add exact prerequisites and executable setup commands. The intended developer path is:

1. Clone the repository.
2. Install the repository-pinned toolchain.
3. Copy versioned example configuration to a local, ignored environment file.
4. Start the local Supabase stack.
5. Apply migrations and seed non-sensitive development data.
6. Run formatting, static checks, tests, and tenant-isolation checks.

No production credentials or production data are required for routine development. Hosted infrastructure is an integration and release target, not the only place the system can run.

## Engineering workflow

Work begins with a traceable issue, specification, or Atlas assumption. Changes are made on a short-lived branch, validated locally, and merged through review after automated checks pass. Database changes are forward, versioned migrations; schema edits made only through a hosted console are prohibited.

See the [BIOS Engineering Handbook](docs/engineering/ENG-001_BIOS_Engineering_Handbook.md) for the lifecycle and [ADR-001](docs/decisions/ADR-001_PostgreSQL_and_Supabase.md) for the initial backend decision.

## Canonical documents

| ID | Document | Purpose |
|---|---|---|
| ENG-001 | [BIOS Engineering Handbook](docs/engineering/ENG-001_BIOS_Engineering_Handbook.md) | Engineering constitution and delivery lifecycle |
| CANON-001 | [Repository and Engineering Standards](docs/engineering/CANON-001_Repository_and_Engineering_Standards.md) | Mandatory repository, naming, documentation, and quality rules |
| ADR-001 | [PostgreSQL and Supabase](docs/decisions/ADR-001_PostgreSQL_and_Supabase.md) | Initial canonical database and backend decision |

Planned companion records include `ARCH-001` for the canonical platform architecture, `DB-001` for the canonical data model, and `ATLAS-001` for the architecture assumption register.

## Governance

“Canonical” means approved as the current baseline, not immutable. Material changes require review, a version-history entry, and—when they alter a significant technical decision—a new ADR that supersedes the prior one. If this README conflicts with a more specific canonical standard, the more specific document governs and the inconsistency must be corrected.

## License and confidentiality

No public license is granted by this document. Until the BIOS Executive Office publishes an explicit license and classification policy, treat repository contents as proprietary internal material.
