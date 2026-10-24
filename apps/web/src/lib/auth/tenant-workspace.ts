import type { BiosTenantAuthorization } from "./tenant-authorization";

export type TenantWorkspaceDecision =
  | {
      kind: "authorized";
      profile: Extract<BiosTenantAuthorization, { status: "authorized" }>["profile"];
      membership: Extract<BiosTenantAuthorization, { status: "authorized" }>["membership"];
    }
  | { kind: "redirect_to_login"; destination: string }
  | { kind: "profile_unavailable" }
  | { kind: "workspace_unavailable" }
  | { kind: "verification_error" };

export function decideTenantWorkspaceEntry(
  authorization: BiosTenantAuthorization,
  tenantCode: string,
): TenantWorkspaceDecision {
  // Tenant codes use the canonical database vocabulary. Reject malformed path
  // values before constructing a return URL or attempting to locate a tenant.
  if (!/^[a-z][a-z0-9_]*$/.test(tenantCode)) {
    return { kind: "workspace_unavailable" };
  }

  switch (authorization.status) {
    case "authorized":
      return {
        kind: "authorized",
        profile: authorization.profile,
        membership: authorization.membership,
      };
    case "unauthenticated": {
      const workspacePath = `/tenants/${encodeURIComponent(tenantCode)}`;
      return {
        kind: "redirect_to_login",
        destination: `/login?next=${encodeURIComponent(workspacePath)}`,
      };
    }
    case "profile_unavailable":
      return { kind: "profile_unavailable" };
    case "tenant_not_authorized":
      return { kind: "workspace_unavailable" };
    case "resolution_error":
      return { kind: "verification_error" };
  }
}
