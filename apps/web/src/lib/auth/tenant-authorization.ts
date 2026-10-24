import type { BiosMembership, BiosUserContext } from "./context";

export type BiosTenantAuthorization =
  | {
      status: "authorized";
      profile: BiosUserContext["profile"];
      membership: BiosMembership;
    }
  | { status: "unauthenticated" }
  | { status: "profile_unavailable" }
  | { status: "tenant_not_authorized" }
  | { status: "resolution_error" };

export function authorizeTenantFromContext(
  context: BiosUserContext | null,
  tenantCode: string,
): BiosTenantAuthorization {
  if (context === null) return { status: "profile_unavailable" };

  const membership = context.memberships.find(
    (candidate) => candidate.tenant.code === tenantCode,
  );

  if (!membership) return { status: "tenant_not_authorized" };

  return {
    status: "authorized",
    profile: context.profile,
    membership,
  };
}

type TenantAuthorizationDependencies = {
  getAuthenticatedUser: () => Promise<{
    user: unknown | null;
    error: unknown | null;
  }>;
  resolveContext: () => Promise<BiosUserContext | null>;
};

export async function authorizeBiosTenantWithDependencies(
  tenantCode: string,
  dependencies: TenantAuthorizationDependencies,
): Promise<BiosTenantAuthorization> {
  try {
    const { user, error } = await dependencies.getAuthenticatedUser();

    // getUser() validates the session with Supabase Auth. A missing user or an
    // invalidated session must not reach the BIOS context resolver.
    if (error || !user) return { status: "unauthenticated" };

    const context = await dependencies.resolveContext();
    return authorizeTenantFromContext(context, tenantCode);
  } catch {
    return { status: "resolution_error" };
  }
}
