import "server-only";

import { createClient } from "@/lib/supabase/server";
import { resolveBiosUserContext } from "./context";
import {
  authorizeBiosTenantWithDependencies,
  type BiosTenantAuthorization,
} from "./tenant-authorization";

export async function authorizeBiosTenant(
  tenantCode: string,
): Promise<BiosTenantAuthorization> {
  try {
    const client = await createClient();

    return authorizeBiosTenantWithDependencies(tenantCode, {
      getAuthenticatedUser: async () => {
        const { data, error } = await client.auth.getUser();
        return { user: data.user, error };
      },
      resolveContext: () => resolveBiosUserContext(client),
    });
  } catch {
    return { status: "resolution_error" };
  }
}
