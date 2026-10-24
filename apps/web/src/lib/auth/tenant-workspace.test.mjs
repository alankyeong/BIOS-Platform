import assert from "node:assert/strict";
import { describe, it } from "node:test";

import { decideTenantWorkspaceEntry } from "./tenant-workspace.ts";

const authorized = {
  status: "authorized",
  profile: {
    id: "profile-1",
    display_name: "Analyst",
    preferred_language_code: null,
  },
  membership: {
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
};

describe("tenant workspace entry", () => {
  it("passes through only trusted authorized context", () => {
    assert.deepEqual(decideTenantWorkspaceEntry(authorized, "tenant_one"), {
      kind: "authorized",
      profile: authorized.profile,
      membership: authorized.membership,
    });
  });

  it("sends an invalid session to sign in with a safe return path", () => {
    assert.deepEqual(
      decideTenantWorkspaceEntry({ status: "unauthenticated" }, "tenant_one"),
      {
        kind: "redirect_to_login",
        destination: "/login?next=%2Ftenants%2Ftenant_one",
      },
    );
  });

  it("rejects a malformed tenant path before constructing a login return URL", () => {
    assert.deepEqual(
      decideTenantWorkspaceEntry({ status: "unauthenticated" }, "tenant one/../../admin"),
      { kind: "workspace_unavailable" },
    );
  });

  it("handles a missing BIOS profile without granting workspace access", () => {
    assert.deepEqual(
      decideTenantWorkspaceEntry({ status: "profile_unavailable" }, "tenant_one"),
      { kind: "profile_unavailable" },
    );
  });

  it("does not reveal whether an unauthorized workspace exists", () => {
    assert.deepEqual(
      decideTenantWorkspaceEntry({ status: "tenant_not_authorized" }, "secret_tenant"),
      { kind: "workspace_unavailable" },
    );
  });

  it("fails closed when access cannot be verified", () => {
    assert.deepEqual(
      decideTenantWorkspaceEntry({ status: "resolution_error" }, "tenant_one"),
      { kind: "verification_error" },
    );
  });
});
