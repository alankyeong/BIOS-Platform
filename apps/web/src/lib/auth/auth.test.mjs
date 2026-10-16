import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { authBoundaryRedirect, isPublicAuthRoute } from "./boundary.ts";
import { safeInternalRedirect } from "./redirect.ts";

describe("safeInternalRedirect", () => {
  it("accepts internal destinations", () => {
    assert.equal(safeInternalRedirect("/"), "/");
    assert.equal(safeInternalRedirect("/reports?period=q4#summary"), "/reports?period=q4#summary");
  });
  for (const candidate of ["https://attacker.example/path", "//attacker.example/path", "\\\\attacker.example\\path", "/safe\\@attacker.example", "javascript:alert(1)", "/path\nLocation: https://attacker.example"]) {
    it(`rejects unsafe destination ${JSON.stringify(candidate)}`, () => assert.equal(safeInternalRedirect(candidate), "/"));
  }
});

describe("authentication boundary", () => {
  it("keeps only exact auth entry routes public", () => {
    assert.equal(isPublicAuthRoute("/login"), true);
    assert.equal(isPublicAuthRoute("/auth/callback"), true);
    assert.equal(isPublicAuthRoute("/auth/callback/extra"), false);
  });
  it("redirects anonymous protected requests", () => {
    assert.equal(authBoundaryRedirect("/", false), "/login");
    assert.equal(authBoundaryRedirect("/admin", false), "/login");
    assert.equal(authBoundaryRedirect("/login", false), null);
  });
  it("redirects authenticated users away from login", () => {
    assert.equal(authBoundaryRedirect("/login", true), "/");
    assert.equal(authBoundaryRedirect("/admin", true), null);
  });
});

