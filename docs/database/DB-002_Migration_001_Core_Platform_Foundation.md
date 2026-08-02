# DB-002 — BIOS Migration 001: Core Platform Foundation

| Field | Value |
|---|---|
| Document ID | DB-002 |
| Title | BIOS Migration 001 — Core Platform Foundation |
| Version | 1.0 |
| Status | Canonical |
| Effective date | 2026-08-02 |
| Owner | BIOS Executive Office — Data Architecture and Engineering |
| Dependencies | ADR-001, ARCH-001, ARCH-002, DB-001, ENG-001, CANON-001 |
| Supersedes | None |
| Review cadence | Before SQL implementation, before merge, and after any relevant Atlas resolution |
| Related documents | [README](../../README.md), [ENG-001](../engineering/ENG-001_BIOS_Engineering_Handbook.md), [CANON-001](../engineering/CANON-001_Repository_and_Engineering_Standards.md), [ADR-001](../decisions/ADR-001_PostgreSQL_and_Supabase.md), [ARCH-001](../architecture/ARCH-001_Canonical_Platform_Architecture.md), [ARCH-002](../architecture/ARCH-002_Architecture_Assumption_Register.md), [DB-001](DB-001_Canonical_Data_Model.md) |

## 1. Purpose

DB-002 defines exactly what the first executable PostgreSQL/Supabase migration is permitted to create. Migration 001 establishes the smallest stable BIOS identity, tenancy, authorization, audit, and Row Level Security foundation. It does not create the BIOS knowledge, intelligence, or decision platform.

This document is an implementation design specification. It contains no SQL.

## 2. Required proof

Migration 001 must prove that:

1. the application schemas can be created reproducibly from source control;
2. a BIOS profile can reference a Supabase Auth identity without duplicating authentication;
3. Tenant is structurally enforced as the primary data-security and ownership boundary;
4. one profile can hold independent memberships in multiple tenants;
5. membership-based roles can authorize tenant operations without a global application super-user;
6. RLS permits authorized same-tenant access and denies cross-tenant, anonymous, missing-context, forged-context, and revoked-member access;
7. security/governance-significant changes create minimal append-oriented audit events; and
8. a clean local reset reconstructs an equivalent database structure.

## 3. Authority and design labels

This specification implements the reduced Migration 001 scope in [DB-001](DB-001_Canonical_Data_Model.md), the Tenant security boundary in [ARCH-001](../architecture/ARCH-001_Canonical_Platform_Architecture.md), and the reversible Tenant/Client/Workspace posture in A-041 of [ARCH-002](../architecture/ARCH-002_Architecture_Assumption_Register.md).

The following labels distinguish authority:

- **Canonical requirement:** required by the governing documents.
- **Implementation decision — approval required:** a least-coupled choice not forced by the governing documents.
- **Deferred:** valid future scope that Migration 001 must not encode.

Any conflict with a governing document blocks the affected SQL until resolved; DB-002 does not silently override canonical architecture.

## 4. Exact permitted migration surface

Migration 001 may create only the following objects.

### 4.1 Namespaces

- `bios_core`
- `bios_knowledge`
- `bios_intelligence`
- `bios_governance`
- `bios_internal`

The last four may remain empty where no listed object belongs in them. Their creation establishes namespace ownership; it does not authorize speculative tables.

### 4.2 Tables

- `bios_core.profiles`
- `bios_core.tenants`
- `bios_core.tenant_memberships`
- `bios_core.roles`
- `bios_core.membership_roles`
- `bios_governance.audit_events`

### 4.3 Supporting database objects

Migration 001 may create only supporting objects necessary to enforce this design:

- primary, foreign-key, unique, check, and not-null constraints;
- indexes specified in this document;
- RLS policies and grants;
- deterministic shared role reference rows;
- narrowly scoped helper functions for identity lookup, active-membership checks, and capability checks;
- narrowly scoped trusted functions for tenant bootstrap, governed membership transitions, role grants/revocations, and their audit writes;
- trigger functions for `updated_at`, immutable ownership fields, and append-only audit protection where constraints/grants alone are insufficient;
- comments or metadata needed to document ownership and security intent.

Helper and trusted functions belong in `bios_internal`, must use explicit argument and return types, a fixed safe `search_path`, least privilege, and revoked public execution. Security-definer functions require explicit review and named grants.

Migration 001 must not add a new extension unless SQL implementation proves a listed object cannot be implemented with the PostgreSQL capabilities already supplied by the supported local Supabase stack. Any extension requires an ADR or approved amendment to DB-002.

## 5. Explicit exclusions

Migration 001 must not create Client, Workspace, workspace membership, geography, market, market group, language, domain, domain node, Market Pack, Domain Pack, entity, alias, source, source document, ingestion, evidence, representation, provenance, signal, pattern, finding, Decision Context, recommendation, decision, human review, assumption, connector, agent, vector, ontology, flexible-attribute, or knowledge-promotion tables or infrastructure.

These exclusions are scope controls, not rejection of the Phase 1 concepts in DB-001.

### 5.1 A-041 reversibility rule

Tenant is the accepted hard security boundary. Client semantics remain unresolved. Workspace is deferred. Migration 001 must contain no workspace field, workspace role, workspace policy, client identifier, or one-client-per-tenant assumption. This preserves a clean additive path for the Executive Office to resolve A-041 later.

## 6. Common data conventions

| Concern | Migration 001 rule |
|---|---|
| Identifier | PostgreSQL `uuid`; BIOS-owned primary keys default to `gen_random_uuid()` |
| Time | `timestamptz`, stored in UTC; database-generated `created_at` and `updated_at` |
| Codes | Lowercase stable identifiers matching `^[a-z][a-z0-9_]*$` |
| Status | Lowercase text constrained to the exact lifecycle values listed per table |
| Tenant ownership | Non-null `tenant_id` on tenant-owned relationship/assignment rows |
| Sharing | Never inferred from a null `tenant_id` |
| Mutable business data | Updated only through authorized paths; ownership keys are immutable |
| Historical records | Revoked, suspended, archived, or superseded rather than routinely deleted |
| Audit metadata | Contains identifiers and safe structured metadata, not secrets or unrestricted payloads |

All database names use lowercase `snake_case` in accordance with CANON-001.

## 7. Identity key implementation decision

### 7.1 Options evaluated

| Option | Benefit | Cost/risk |
|---|---|---|
| `profiles.id = auth.users.id` | Simple joins and one identifier | Couples BIOS domain identity directly to the current authentication provider and complicates future identity linking |
| Independent `profiles.id` plus unique `auth_user_id` | Separates BIOS identity from Supabase Auth and permits controlled future identity evolution | Adds one join and requires strict one-to-one uniqueness |

### 7.2 Recommendation

**Implementation decision M001-D01 — approval required:** use an independent BIOS UUID primary key and a non-null, unique `auth_user_id` foreign key to `auth.users.id`.

This is the least-coupled option and matches DB-001’s proposed boundary. It preserves Supabase ownership of authentication while ensuring one Phase 1 profile per Auth identity. Migration 001 must not copy passwords, providers, MFA state, tokens, email verification state, or other Supabase-controlled fields.

## 8. Table specifications

### 8.1 `bios_core.profiles`

#### Purpose and security

BIOS-owned application representation of an authenticated Supabase identity. It is global identity metadata, not a tenant authorization source. RLS is required if the table is exposed through a Supabase API.

#### Fields

| Field | Type | Null | Default | Rule |
|---|---|---:|---|---|
| `id` | `uuid` | No | Generated UUID | Primary key, immutable |
| `auth_user_id` | `uuid` | No | None | FK to `auth.users.id`, immutable, unique |
| `display_name` | `text` | No | None | Trimmed; length 1–200 |
| `preferred_language_code` | `text` | Yes | Null | Temporary BCP 47-style code; future FK to Language registry |
| `status` | `text` | No | `active` | `active`, `suspended`, or `deactivated` |
| `created_at` | `timestamptz` | No | Transaction time | Immutable |
| `updated_at` | `timestamptz` | No | Transaction time | Updated on permitted change |

#### Constraints and indexes

- Primary key: `id`.
- Unique constraint: `auth_user_id`.
- Foreign key: `auth_user_id → auth.users.id`; no cascade deletion.
- Checks: permitted status; trimmed display-name length; preferred language code is null or bounded to 2–35 characters.
- Index: unique index supporting `auth_user_id` lookup. No global display-name index in Migration 001.

#### Lifecycle, access, and deletion

- A trusted provisioning path or authenticated self-provisioning path may create the profile only when `auth_user_id = auth.uid()`; SQL review must select one path and test it.
- The authenticated person may read their own profile and update only approved self-service fields: `display_name` and `preferred_language_code`.
- Migration 001 permits direct profile reads only by the profile owner and trusted server/exceptional administration paths. Co-member directory access is deferred until a workflow defines an approved projection or function; there is no global profile directory.
- Status changes are trusted server or exceptional administration operations.
- Ordinary deletion is prohibited. Auth-user deletion does not cascade; retention/anonymization is a later governed workflow.

#### Ownership, audit, and compatibility

Profile records have no tenant owner. Authorization is derived through `tenant_memberships`. Profile creation, suspension, and deactivation are auditable when performed by BIOS-controlled functions. Future migrations may add identity links or Language FKs without changing membership ownership.

**Atlas dependency:** A-041. **Implementation dependency:** M001-D01.

### 8.2 `bios_core.tenants`

#### Purpose and security

Primary BIOS ownership and data-security boundary. Tenant records are platform-governed; active authorized members may read their tenant’s safe fields. RLS is required.

#### Fields

| Field | Type | Null | Default | Rule |
|---|---|---:|---|---|
| `id` | `uuid` | No | Generated UUID | Primary key, immutable |
| `code` | `text` | No | None | Globally unique stable code, immutable after activation |
| `name` | `text` | No | None | Trimmed; length 1–200 |
| `status` | `text` | No | `provisioning` | `provisioning`, `active`, `suspended`, or `archived` |
| `default_locale` | `text` | Yes | Null | Configuration placeholder, not a Language FK |
| `default_time_zone` | `text` | Yes | Null | IANA time-zone name validated by trusted application path |
| `created_at` | `timestamptz` | No | Transaction time | Immutable |
| `updated_at` | `timestamptz` | No | Transaction time | Updated on permitted change |
| `activated_at` | `timestamptz` | Yes | Null | Required when active or later |
| `archived_at` | `timestamptz` | Yes | Null | Required only when archived |

#### Constraints and indexes

- Primary key: `id`.
- Unique constraint: `code`; codes use the common stable-code format and are globally unique.
- Checks: name length; permitted status; activation/archive timestamp consistency.
- Index: status for controlled platform operations; unique code index satisfies code lookup.

#### Lifecycle and invariants

```text
provisioning → active → suspended → active
                    └→ archived
suspended ───────────────────────→ archived
```

- Tenant `id` and `code` are immutable after activation.
- A tenant has many tenant memberships.
- A profile may belong to many tenants through independent memberships.
- Tenant-private records must never infer sharing from null ownership.
- `suspended` denies ordinary tenant operations but preserves records and memberships.
- `archived` is terminal for Migration 001 and denies ordinary tenant operations.
- Physical tenant deletion is prohibited after any membership or audit event exists. Local test reset may drop the entire local database under the guarded Supabase reset workflow.

#### Access, audit, and compatibility

Tenant creation and initial administrator assignment occur together through one trusted server transaction. Ordinary members may read safe fields of active tenants in which they have active membership. Tenant administrators cannot change tenant security status directly. Status transitions and tenant creation require audit events. Future tables reference this same immutable tenant key.

**Atlas dependency:** A-041.

### 8.3 `bios_core.tenant_memberships`

#### Purpose and security

Auditable relationship between one profile and one tenant. It is the ordinary tenant authorization principal. It is tenant-scoped and requires RLS.

#### Fields

| Field | Type | Null | Default | Rule |
|---|---|---:|---|---|
| `id` | `uuid` | No | Generated UUID | Primary key, immutable |
| `tenant_id` | `uuid` | No | None | FK to tenant, immutable |
| `profile_id` | `uuid` | No | None | FK to profile, immutable for the membership episode |
| `status` | `text` | No | `invited` | `invited`, `active`, `suspended`, or `revoked` |
| `invited_at` | `timestamptz` | No | Transaction time | Start of episode |
| `activated_at` | `timestamptz` | Yes | Null | Required once activated |
| `suspended_at` | `timestamptz` | Yes | Null | Required while suspended |
| `revoked_at` | `timestamptz` | Yes | Null | Required when revoked |
| `valid_from` | `timestamptz` | Yes | Null | Authorization begins; normally activation time |
| `valid_until` | `timestamptz` | Yes | Null | Optional authorization expiry; must follow `valid_from` |
| `created_by_profile_id` | `uuid` | Yes | Null | Actor profile when user-initiated; service bootstrap may be null |
| `created_at` | `timestamptz` | No | Transaction time | Immutable |
| `updated_at` | `timestamptz` | No | Transaction time | Updated on transition |

#### Constraints and indexes

- Primary key: `id`.
- Foreign keys: tenant, profile, and optional creator profile; no cascade deletion.
- Composite unique constraint on `(id, tenant_id)` to support tenant-compatible assignment FKs.
- Partial unique index on `(tenant_id, profile_id)` where status is not `revoked`, allowing one current episode and multiple historical revoked episodes.
- Indexes on `profile_id`, `(tenant_id, status)`, and active membership lookup.
- Checks enforce lifecycle timestamp consistency and `valid_until > valid_from` when both exist.

#### Lifecycle and history

```text
invited → active ↔ suspended → revoked
    └──────────────────────→ revoked
```

- A Migration 001 invitation requires an existing BIOS profile; pre-registration email invitation is deferred to a separate future invitation model.
- `revoked` is terminal. Rejoining creates a new membership episode with a new ID.
- Suspended memberships retain assignments and history but confer no access.
- A membership is authorizing only if the tenant is active, membership is active, and current time is inside its validity interval.
- Membership ownership (`tenant_id`) and subject (`profile_id`) never change.

#### Access, audit, and compatibility

Members may read their own membership. Tenant administrators with the appropriate capability may read tenant memberships. Creation and lifecycle transitions are allowed only through trusted functions that validate authority and emit invitation, activation, suspension, or revocation audit events in the same transaction. Ordinary hard deletion is prohibited.

Future Workspace membership must reference an active/historical tenant membership and the same tenant; Migration 001 does not encode Workspace.

**Atlas dependency:** A-041.

### 8.4 `bios_core.roles`

#### Purpose and security

Minimal shared platform role definitions used to demonstrate membership authorization. Migration 001 does not establish the final enterprise role taxonomy or tenant-defined roles.

#### Implementation decision

**M001-D02 — approval required:** roles are shared, platform-governed reference records in Migration 001. Tenant-defined roles are deferred. The minimum role records are:

- `tenant_admin`
- `analyst`
- `viewer`

Authorization uses explicit minimal capability flags rather than treating role name or numeric rank as unrestricted power. The initial flags are `can_manage_memberships`, `can_manage_role_assignments`, and `can_read_audit`. Future migration may normalize capabilities without changing assignment history.

#### Fields

| Field | Type | Null | Default | Rule |
|---|---|---:|---|---|
| `id` | `uuid` | No | Generated UUID | Primary key, immutable |
| `code` | `text` | No | None | Unique stable platform code |
| `name` | `text` | No | None | Human-readable name |
| `description` | `text` | No | Empty text | Bounded description |
| `can_manage_memberships` | `boolean` | No | `false` | Minimal capability |
| `can_manage_role_assignments` | `boolean` | No | `false` | Minimal capability |
| `can_read_audit` | `boolean` | No | `false` | Minimal capability |
| `is_assignable` | `boolean` | No | `true` | False prevents new grants |
| `status` | `text` | No | `active` | `active` or `deprecated` |
| `created_at` | `timestamptz` | No | Transaction time | Immutable |
| `updated_at` | `timestamptz` | No | Transaction time | Updated only by platform migration/admin path |

#### Constraints, access, and compatibility

- Primary key: `id`; unique constraint on `code`.
- Checks enforce stable-code format, permitted status, and name/description bounds.
- Active authenticated members may read active shared roles needed to understand their assignments.
- Clients and tenant administrators cannot insert, update, or delete role definitions.
- Role changes require a reviewed migration or exceptional audited platform path.
- Referenced roles are deprecated, not deleted.

**Atlas dependencies:** A-037 and A-041.

### 8.5 `bios_core.membership_roles`

#### Purpose and security

Auditable assignment of a shared role to one tenant membership. It is tenant-scoped and requires RLS.

#### Fields

| Field | Type | Null | Default | Rule |
|---|---|---:|---|---|
| `id` | `uuid` | No | Generated UUID | Primary key, immutable |
| `tenant_id` | `uuid` | No | None | Structural tenant owner, immutable |
| `tenant_membership_id` | `uuid` | No | None | Membership receiving the role, immutable |
| `role_id` | `uuid` | No | None | Shared role definition, immutable for this grant episode |
| `granted_by_profile_id` | `uuid` | Yes | Null | User actor; null only for trusted bootstrap/service operation |
| `granted_at` | `timestamptz` | No | Transaction time | Start of grant |
| `revoked_by_profile_id` | `uuid` | Yes | Null | Actor for revocation when user-initiated |
| `revoked_at` | `timestamptz` | Yes | Null | Null means current grant |
| `revocation_reason` | `text` | Yes | Null | Bounded safe reason |
| `created_at` | `timestamptz` | No | Transaction time | Immutable |

#### Constraints and indexes

- Primary key: `id`.
- Composite FK `(tenant_membership_id, tenant_id) → tenant_memberships(id, tenant_id)` enforces tenant compatibility.
- FKs to role and optional grant/revoke actor profiles; no cascade deletion.
- Partial unique index on `(tenant_membership_id, role_id)` where `revoked_at` is null.
- Indexes on `(tenant_id, tenant_membership_id)`, `(tenant_id, role_id)`, and current grants.
- Checks enforce revocation actor/time consistency and `revoked_at >= granted_at`.

#### Access, audit, and compatibility

Active members may read their own assignments. Authorized tenant administrators may read assignments within their tenant. Grants and revocations occur only through trusted functions; the functions verify active tenant-admin membership, role assignability, tenant compatibility, prevention of self-removal of the last tenant administrator, and same-transaction audit.

Revocation ends a grant but does not delete it. Re-granting creates a new episode. `tenant_id` is never updated. Future tenant-defined roles may extend the referenced role model without changing historical grants.

**Atlas dependencies:** A-037 and A-041. **Implementation dependency:** M001-D02.

### 8.6 `bios_governance.audit_events`

#### Purpose and security

Minimal append-oriented record of security and governance-significant operations. It is not an application log, telemetry store, or arbitrary payload warehouse.

#### Fields

| Field | Type | Null | Default | Rule |
|---|---|---:|---|---|
| `id` | `uuid` | No | Generated UUID | Primary key |
| `scope_type` | `text` | No | None | `tenant` or `platform` |
| `tenant_id` | `uuid` | Yes | Null | Tenant context; null only for genuine platform-scope events |
| `actor_type` | `text` | No | None | `user`, `service`, `platform_admin`, or `system` |
| `actor_profile_id` | `uuid` | Yes | Null | Required for user actor; BIOS profile FK |
| `actor_identifier` | `text` | Yes | Null | Bounded service/platform subject; never a secret |
| `action` | `text` | No | None | Governed initial action code |
| `resource_type` | `text` | No | None | Governed resource code |
| `resource_id` | `uuid` | Yes | Null | Target when represented by UUID |
| `outcome` | `text` | No | None | `succeeded`, `denied`, or `failed` |
| `correlation_id` | `uuid` | No | Generated UUID if absent | Groups related operation events |
| `occurred_at` | `timestamptz` | No | Transaction time | Immutable event time |
| `metadata` | `jsonb` | No | Empty object | Safe bounded object, not arbitrary logs |

Initial action codes are `tenant.created`, `membership.invited`, `membership.activated`, `membership.suspended`, `membership.revoked`, `role.granted`, `role.revoked`, and `platform.privileged_action`. New codes are additive and reviewed.

#### Constraints and indexes

- Primary key: `id`.
- Foreign keys to tenant and actor profile do not cascade.
- Checks enforce enumerated scope/actor/outcome values, action/resource code format, metadata is a JSON object, actor-field compatibility, non-null `tenant_id` for tenant scope, and null `tenant_id` only for explicit platform scope.
- Indexes on `(tenant_id, occurred_at desc)`, `(actor_profile_id, occurred_at desc)`, `correlation_id`, and `(resource_type, resource_id)`.
- No unrestricted metadata search/index in Migration 001.

#### Access, audit, and deletion

- Ordinary users cannot insert, update, or delete audit events directly.
- Trusted governed functions and tightly scoped server operations may insert events.
- Active tenant administrators with `can_read_audit` may read tenant-context events for their tenant.
- Ordinary members have no default audit-history access.
- Platform-scope events are visible only through exceptional platform administration.
- Updates and ordinary deletes are prohibited. Retention deletion is deferred to a future approved governance policy.
- A failure to create a required success audit event causes the governed data change to roll back.
- Denied attempts may be captured outside the same failed transaction by the trusted server boundary; Migration 001 does not pretend RLS alone can durably audit a rolled-back denial.

**Atlas dependencies:** A-041 and the governance posture in ARCH-001.

## 9. Role seed specification

Migration 001 may insert only deterministic shared role definitions:

| Code | Membership management | Role assignment | Audit read | Intended baseline |
|---|---:|---:|---:|---|
| `tenant_admin` | Yes | Yes | Yes | Tenant-scoped administration |
| `analyst` | No | No | No | Ordinary analytical work in later migrations |
| `viewer` | No | No | No | Read-only work in later migrations |

Seeds are reference data required by policy tests, not customer data. Stable codes are authoritative; UUID values need not become external business identifiers. Seed application must be idempotent during local reconstruction and must fail on incompatible pre-existing definitions rather than silently changing security meaning.

No real tenant, client, user, market, category, or evidence data belongs in Migration 001. Synthetic tenants and Auth users belong in local/test fixtures under `supabase/tests/` or its approved fixture support.

## 10. RLS design

### 10.1 Authorizing predicate

A tenant access predicate is true only when all are true:

1. `auth.uid()` resolves to exactly one active BIOS profile;
2. the target tenant is active;
3. the profile has an active membership in that tenant;
4. current time is within membership validity bounds; and
5. the requested action is allowed by assignment capability or trusted server path.

Client-provided tenant IDs are selectors, never proof of authority.

### 10.2 Policy matrix

| Object | Authenticated member | Tenant administrator | Trusted server | Exceptional platform administration | Anonymous |
|---|---|---|---|---|---|
| `profiles` | Read self; update approved self fields; no co-member directory | Same; profile-table access does not broaden with tenant role | Provision/status operations as scoped | Exceptional governed access | Deny |
| `tenants` | Read safe fields of own active tenant | Same; no direct security-status mutation | Bootstrap and governed status operations | Exceptional governed access | Deny |
| `tenant_memberships` | Read self in own tenant | Read own-tenant memberships; transition via trusted function | Scoped provisioning/transitions | Exceptional governed access | Deny |
| `roles` | Read active assignable definitions | Read only | Reference maintenance only when explicitly authorized | Exceptional governed access | Deny |
| `membership_roles` | Read own current/history needed for authorization | Read own-tenant assignments; grant/revoke via trusted function | Bootstrap and scoped operations | Exceptional governed access | Deny |
| `audit_events` | Deny by default | Read own-tenant events with `can_read_audit`; never mutate | Insert required events; scoped reads | Platform and tenant-aware reads | Deny |

### 10.3 Write boundary

Direct client writes to membership lifecycle, role assignments, tenant lifecycle, and audit events are denied. Trusted functions provide a narrow transactional interface and must:

- derive actor identity from authenticated context rather than a caller-supplied profile ID;
- verify tenant and required capability;
- lock or otherwise protect invariants affected by concurrency;
- prohibit tenant ownership mutation;
- write the domain change and required audit event atomically;
- reject arbitrary role, tenant, actor, or audit metadata injection; and
- expose execution only to named authenticated or server roles.

## 11. Privileged administrative path

### 11.1 Authenticated client/user operations

May read/update approved self profile fields and read authorized self/tenant data through RLS. Cannot directly manage memberships, roles, tenant status, or audit rows.

### 11.2 Tenant-administrator operations

An active membership with an active `tenant_admin` assignment supplies only the explicit minimal capabilities. Tenant-admin changes use trusted functions and remain limited to the administrator’s tenant. Tenant administrators cannot define platform roles, bypass RLS, create arbitrary tenants, access platform-scope audit, or change tenant ownership.

### 11.3 Trusted BIOS server/service operations

Uses Supabase service-role credentials only in trusted server-side infrastructure. Credentials never reach clients, tests committed to Git, logs, or prompts. Server operations are purpose-scoped in application code, validate tenant context explicitly, and emit audit events. Service-role RLS bypass is not treated as authorization by itself.

The minimum bootstrap operation creates a tenant, creates the initial membership for an existing profile, grants `tenant_admin`, and writes audit events in one transaction. Failure rolls back the entire bootstrap.

### 11.4 Exceptional platform administration

There is no unrestricted global application-admin role in Migration 001. Exceptional access uses controlled infrastructure credentials, named human authorization outside ordinary application roles, least privilege, time-bounded access where supported, and a `platform.privileged_action` audit event with justification and correlation ID. A later operational standard must define break-glass approval and credential custody before hosted production use.

**Implementation decision M001-D03 — approval required:** accept this four-path model and trusted-function surface as the minimum Phase 1 privileged design.

## 12. Required audit obligations

| Operation | Required event | Transaction rule |
|---|---|---|
| Tenant bootstrap | `tenant.created`, initial membership/role events | Same transaction |
| Membership invitation | `membership.invited` | Same transaction |
| Membership activation | `membership.activated` | Same transaction |
| Membership suspension | `membership.suspended` | Same transaction |
| Membership revocation | `membership.revoked` | Same transaction |
| Role grant | `role.granted` | Same transaction |
| Role revocation | `role.revoked` | Same transaction |
| Exceptional platform change | `platform.privileged_action` | Same transaction when possible; otherwise correlated durable server audit |

Metadata may include reason, prior/new status, role code, and request channel when safe. It must not contain credentials, tokens, unrestricted request bodies, or sensitive profile data.

## 13. Acceptance test plan

### 13.1 Database tests in `supabase/tests/`

The executable database test suite must include:

1. clean local reset creates all five schemas and exactly the permitted tables;
2. `auth.users` remains Supabase-owned and no BIOS authentication-state columns exist;
3. a BIOS profile references a valid Auth user and rejects an invalid or duplicate Auth identity;
4. one profile can have an active membership in Tenant A and independently in Tenant B;
5. an active Tenant A member can read permitted Tenant A records;
6. that member cannot read Tenant B membership or assignment rows without Tenant B authorization;
7. cross-tenant inserts and updates are denied;
8. a forged Tenant B `tenant_id` is rejected even when supplied by an authenticated Tenant A member;
9. `tenant_id` mutation is rejected;
10. missing authentication/tenant authorization and anonymous access are denied;
11. suspended and revoked memberships grant no tenant access;
12. expired/not-yet-valid membership grants no tenant access;
13. unauthorized membership transition and role grant fail;
14. authorized tenant-admin transition and role grant succeed only through the intended path;
15. assignment tenant compatibility FK rejects mismatched tenant/membership values;
16. concurrent or repeated grants do not create duplicate current assignments;
17. revocation preserves assignment history and re-granting creates a new episode;
18. ordinary users cannot mutate audit rows;
19. governed success writes the required audit event atomically;
20. no operation may remove the last active tenant administrator without an approved replacement in the same transaction;
21. suspended/archived tenant denies ordinary tenant access;
22. migration seed roles have the expected immutable codes and minimal capabilities;
23. a second migration replay attempt is handled according to Supabase migration tracking rather than duplicating objects; and
24. structural snapshot/catalog assertions match the reviewed Migration 001 specification.

Tests must assume authenticated identities using supported Supabase/PostgreSQL test helpers and must explicitly reset identity/session context between cases.

### 13.2 Later integration tests

Integration tests may validate:

- signup/provisioning from Supabase Auth to BIOS profile;
- server-held service-role isolation from browser/client bundles;
- tenant bootstrap through the server boundary;
- API behavior and safe error responses;
- correlated audit across application and database boundary;
- revoked-session behavior and token refresh timing; and
- clean-machine Docker/Supabase reconstruction.

Database RLS correctness must not be deferred to integration tests.

## 14. Migration safety and evolution

### 14.1 Forward behavior

Migration 001 creates namespaces, tables, constraints, indexes, reference roles, functions, grants, RLS policies, and tests as one reviewed version-controlled foundation. It must fail visibly on incompatible existing objects rather than silently adopt unknown definitions.

### 14.2 Local reset

The approved local Supabase reset may destroy only the explicitly targeted local development database and rebuild it from committed migrations and safe fixtures. Production or shared environment credentials must not be required. The reset target must be visibly guarded.

### 14.3 Rollback and recovery

During the current local-only phase, recovery is a clean reset and replay. Before any shared or production application, Engineering must document backup/restore posture and a forward recovery migration. A down migration is not required merely for symmetry and must not be improvised against a populated environment.

### 14.4 Immutability

After merge or application to a shared environment, Migration 001 is immutable. Corrections are new ordered migrations. SQL implementation may not be edited in place to change historical meaning.

### 14.5 Additive evolution

Migration 002 and later migrations may add Workspace after A-041 resolution, add registries, or extend identity/authorization through additive tables, columns, and policies. They must not reuse tenant nullability as sharing, change profile/Auth identity coupling without a migration plan, rewrite membership history, or weaken RLS.

## 15. Contradictions and ambiguities reported

No canonical conflict is identified in the requested reduced scope. Three implementation choices are not fully forced by the governing architecture and therefore require approval before SQL:

1. **M001-D01:** independent `profiles.id` plus unique `auth_user_id`.
2. **M001-D02:** shared platform roles with three minimal capability flags and initial `tenant_admin`, `analyst`, and `viewer` seeds; tenant-defined roles deferred.
3. **M001-D03:** four-path administrative model using narrowly scoped trusted functions and server-held service-role credentials, with no global application-admin role.

The currently available workspace does not contain ARCH-001, ARCH-002, or DB-001 at the time DB-002 is written. This is a repository-state issue, not an architecture contradiction. Their approved content supplied in the preceding Gate 4 work was used as the design baseline; the files must be restored at their canonical paths before DB-002 is committed or its links validated in the repository.

## 16. Migration 001 readiness checklist

### Architecture

- [x] Scope matches the reduced Migration 001 in DB-001.
- [x] Tenant is the only encoded security boundary.
- [x] Client and Workspace remain deferred under A-041.
- [x] No market, category, knowledge, intelligence, agent, or vector assumption is encoded.

### Security

- [x] Supabase Auth remains authoritative for authentication.
- [x] No global application super-user is introduced.
- [x] Service-role use is server-only, purpose-scoped, and audited.
- [x] Ownership keys are immutable and tenant compatibility is structural.
- [ ] Executive Office approves M001-D01, M001-D02, and M001-D03.

### Data model

- [x] Exact permitted tables, fields, types, constraints, indexes, lifecycle, and deletion behavior are specified.
- [x] Membership and role-grant history is preserved through episodes and revocation.
- [x] Physical tenant deletion is prohibited after governed history exists.

### RLS

- [x] Deny-by-default policy intent is specified for every included table.
- [x] Positive, negative, forged-context, mutation, suspension, and revocation cases are testable.
- [ ] SQL policy implementation receives security review before merge.

### Audit

- [x] Initial governed actions and safe event fields are defined.
- [x] Ordinary audit mutation is prohibited.
- [x] Required successful changes and audit writes are atomic.

### Testing

- [x] Database and later integration test responsibilities are separated.
- [x] Clean reset, isolation, role, history, and audit cases are defined.
- [ ] Executable tests pass against the SQL implementation.

### Reproducibility

- [x] Safe deterministic role reference data is specified.
- [x] Local reset and migration replay expectations are defined.
- [ ] Clean-machine local rebuild is demonstrated after SQL implementation.

### Documentation

- [x] DB-002 contains no SQL.
- [x] Existing canonical documents were not modified.
- [ ] ARCH-001, ARCH-002, and DB-001 are present at their canonical repository paths before commit.

### Atlas dependencies

- [x] A-041 is preserved as unresolved for Client/Workspace semantics.
- [x] Migration 001 makes no Workspace commitment.
- [x] Implementation choices are explicitly approval-gated.

### Rollback and recovery

- [x] Local reset/replay is the current local-only recovery path.
- [x] Migration immutability and additive correction rules are defined.
- [ ] Shared/production recovery procedures are approved before non-local deployment.

## 17. Readiness recommendation

**READY WITH CONDITIONS**

Engineering may translate DB-002 into SQL after the Executive Office approves M001-D01, M001-D02, and M001-D03 and the three Gate 4 governing files are present at their canonical repository paths. SQL implementation, RLS security review, executable tests, and clean local rebuild remain required before Migration 001 is approved for merge.

## 18. Version history

| Version | Date | Change |
|---|---|---|
| 1.0 | 2026-08-02 | Initial canonical implementation design for the reduced Migration 001 core platform foundation |
