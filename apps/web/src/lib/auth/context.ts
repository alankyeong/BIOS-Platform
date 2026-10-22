import type { SupabaseClient } from "@supabase/supabase-js";

export type BiosRole = {
  id: string;
  code: string;
  name: string;
  capabilities: {
    manage_memberships: boolean;
    manage_role_assignments: boolean;
    read_audit: boolean;
  };
};

export type BiosMembership = {
  id: string;
  tenant: {
    id: string;
    code: string;
    name: string;
    default_locale: string | null;
    default_time_zone: string | null;
  };
  roles: BiosRole[];
};

export type BiosUserContext = {
  profile: {
    id: string;
    display_name: string;
    preferred_language_code: string | null;
  };
  memberships: BiosMembership[];
};

const isRecord = (value: unknown): value is Record<string, unknown> =>
  typeof value === "object" && value !== null && !Array.isArray(value);

const isNullableString = (value: unknown): value is string | null =>
  typeof value === "string" || value === null;

function parseRole(value: unknown): BiosRole | null {
  if (!isRecord(value) || !isRecord(value.capabilities)) return null;
  const capabilities = value.capabilities;
  if (
    typeof value.id !== "string" ||
    typeof value.code !== "string" ||
    typeof value.name !== "string" ||
    typeof capabilities.manage_memberships !== "boolean" ||
    typeof capabilities.manage_role_assignments !== "boolean" ||
    typeof capabilities.read_audit !== "boolean"
  ) return null;
  return {
    id: value.id,
    code: value.code,
    name: value.name,
    capabilities: {
      manage_memberships: capabilities.manage_memberships,
      manage_role_assignments: capabilities.manage_role_assignments,
      read_audit: capabilities.read_audit,
    },
  };
}

function parseMembership(value: unknown): BiosMembership | null {
  if (!isRecord(value) || !isRecord(value.tenant) || !Array.isArray(value.roles)) return null;
  const tenant = value.tenant;
  const roles = value.roles.map(parseRole);
  if (
    typeof value.id !== "string" ||
    typeof tenant.id !== "string" ||
    typeof tenant.code !== "string" ||
    typeof tenant.name !== "string" ||
    !isNullableString(tenant.default_locale) ||
    !isNullableString(tenant.default_time_zone) ||
    roles.some((role) => role === null)
  ) return null;
  return {
    id: value.id,
    tenant: {
      id: tenant.id,
      code: tenant.code,
      name: tenant.name,
      default_locale: tenant.default_locale,
      default_time_zone: tenant.default_time_zone,
    },
    roles: roles as BiosRole[],
  };
}

export function parseBiosUserContext(value: unknown): BiosUserContext | null {
  if (value === null) return null;
  if (!isRecord(value) || !isRecord(value.profile) || !Array.isArray(value.memberships)) {
    throw new Error("Invalid BIOS access context response.");
  }
  const profile = value.profile;
  const memberships = value.memberships.map(parseMembership);
  if (
    typeof profile.id !== "string" ||
    typeof profile.display_name !== "string" ||
    !isNullableString(profile.preferred_language_code) ||
    memberships.some((membership) => membership === null)
  ) throw new Error("Invalid BIOS access context response.");
  return {
    profile: {
      id: profile.id,
      display_name: profile.display_name,
      preferred_language_code: profile.preferred_language_code,
    },
    memberships: memberships as BiosMembership[],
  };
}

export async function resolveBiosUserContext(client: SupabaseClient): Promise<BiosUserContext | null> {
  const { data, error } = await client.rpc("resolve_bios_user_context");
  if (error) throw new Error("Unable to resolve BIOS access context.", { cause: error });
  return parseBiosUserContext(data);
}
