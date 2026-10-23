import assert from "node:assert/strict";
import { describe, it } from "node:test";

import {
  authorizeBiosTenantWithDependencies,
  authorizeTenantFromContext,
} from "./tenant-authorization.ts";

const context = {
  profile: {
    id: "profile-1",
    display_name: "Analyst",
    preferred_language_code: null,
  },
  memberships: [
    {
      id: "membership-1",
      tenant: {
        id: "tenant-1",
        code: "tenant_one",
        name: "Tenant One",
        default_locale: "en-MY",
        default_time_zone: "Asia/Kuala_Lumpur",
      },
      roles: [],
    },
  ],
};

function dependenciesWith({
  user = { id: "auth-user-1" },
  authError = null,
  resolverData = context,
  resolverError = null,
} = {}) {
  const calls = [];
  return {
    calls,
    dependencies: {
      getAuthenticatedUser: async () => {
        calls.push("getUser");
        return { user, error: authError };
      },
      resolveContext: async () => {
        calls.push("resolve_bios_user_context");
        if (resolverError) {
          throw new Error("Unable to resolve BIOS access context.", {
            cause: resolverError,
          });
        }
        if (
          resolverData !== null &&
          (!resolverData.profile || !Array.isArray(resolverData.memberships))
        ) {
          throw new Error("Invalid BIOS access context response.");
        }
        return resolverData;
      },
    },
  };
}

describe("tenant authorization selection", () => {
  it("authorizes only the requested active membership", () => {
    assert.deepEqual(authorizeTenantFromContext(context, "tenant_one"), {
      status: "authorized",
      profile: context.profile,
      membership: context.memberships[0],
    });
  });

  it("treats an unknown tenant locator as unauthorized", () => {
    assert.deepEqual(authorizeTenantFromContext(context, "tenant_two"), {
      status: "tenant_not_authorized",
    });
  });

  it("does not normalize or elevate a client-provided locator", () => {
    assert.deepEqual(authorizeTenantFromContext(context, "TENANT_ONE"), {
      status: "tenant_not_authorized",
    });
  });

  it("distinguishes a missing active BIOS profile", () => {
    assert.deepEqual(authorizeTenantFromContext(null, "tenant_one"), {
      status: "profile_unavailable",
    });
  });
});

describe("server tenant authorization orchestration", () => {
  it("checks trusted authentication before resolving and authorizing", async () => {
    const { dependencies, calls } = dependenciesWith();

    assert.equal(
      (await authorizeBiosTenantWithDependencies("tenant_one", dependencies)).status,
      "authorized",
    );
    assert.deepEqual(calls, ["getUser", "resolve_bios_user_context"]);
  });

  it("fails closed for another tenant", async () => {
    const { dependencies } = dependenciesWith();

    assert.deepEqual(await authorizeBiosTenantWithDependencies("tenant_two", dependencies), {
      status: "tenant_not_authorized",
    });
  });

  it("stops before the resolver when the session was invalidated", async () => {
    const { dependencies, calls } = dependenciesWith({
      user: null,
      authError: { message: "User is banned" },
    });

    assert.deepEqual(await authorizeBiosTenantWithDependencies("tenant_one", dependencies), {
      status: "unauthenticated",
    });
    assert.deepEqual(calls, ["getUser"]);
  });

  it("returns profile_unavailable for an authenticated user without an active profile", async () => {
    const { dependencies } = dependenciesWith({ resolverData: null });

    assert.deepEqual(await authorizeBiosTenantWithDependencies("tenant_one", dependencies), {
      status: "profile_unavailable",
    });
  });

  it("fails closed when the trusted resolver returns malformed data", async () => {
    const { dependencies } = dependenciesWith({ resolverData: { memberships: [] } });

    assert.deepEqual(await authorizeBiosTenantWithDependencies("tenant_one", dependencies), {
      status: "resolution_error",
    });
  });

  it("fails closed when the trusted resolver reports an RPC error", async () => {
    const { dependencies } = dependenciesWith({
      resolverData: null,
      resolverError: { message: "database unavailable" },
    });

    assert.deepEqual(await authorizeBiosTenantWithDependencies("tenant_one", dependencies), {
      status: "resolution_error",
    });
  });

  it("does not reuse authorization across requests or tenants", async () => {
    const first = dependenciesWith();
    const second = dependenciesWith({ user: null, authError: { message: "invalid JWT" } });

    assert.equal(
      (await authorizeBiosTenantWithDependencies("tenant_one", first.dependencies)).status,
      "authorized",
    );
    assert.equal(
      (await authorizeBiosTenantWithDependencies("tenant_one", second.dependencies)).status,
      "unauthenticated",
    );
    assert.deepEqual(first.calls, ["getUser", "resolve_bios_user_context"]);
    assert.deepEqual(second.calls, ["getUser"]);
  });
});
