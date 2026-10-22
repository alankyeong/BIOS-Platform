import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { parseBiosUserContext, resolveBiosUserContext } from "./context.ts";

const validContext = {
  profile: { id: "profile-1", display_name: "Analyst", preferred_language_code: null },
  memberships: [{
    id: "membership-1",
    tenant: {
      id: "tenant-1",
      code: "tenant_one",
      name: "Tenant One",
      default_locale: "en-MY",
      default_time_zone: "Asia/Kuala_Lumpur",
    },
    roles: [{
      id: "role-1",
      code: "viewer",
      name: "Viewer",
      capabilities: {
        manage_memberships: false,
        manage_role_assignments: false,
        read_audit: false,
      },
    }],
  }],
};

describe("BIOS user context", () => {
  it("accepts the resolver response contract", () => {
    assert.deepEqual(parseBiosUserContext(validContext), validContext);
  });

  it("represents an authenticated user without an active BIOS profile as null", () => {
    assert.equal(parseBiosUserContext(null), null);
  });

  it("rejects malformed resolver data", () => {
    assert.throws(
      () => parseBiosUserContext({ ...validContext, memberships: [{ id: "membership-1" }] }),
      /Invalid BIOS access context response/,
    );
  });

  it("uses only the narrow read RPC", async () => {
    const calls = [];
    const client = {
      rpc: async (name) => {
        calls.push(name);
        return { data: validContext, error: null };
      },
    };
    assert.deepEqual(await resolveBiosUserContext(client), validContext);
    assert.deepEqual(calls, ["resolve_bios_user_context"]);
  });

  it("does not expose database error details", async () => {
    const client = { rpc: async () => ({ data: null, error: { message: "internal detail" } }) };
    await assert.rejects(
      resolveBiosUserContext(client),
      (error) => error.message === "Unable to resolve BIOS access context." && error.cause.message === "internal detail",
    );
  });
});
