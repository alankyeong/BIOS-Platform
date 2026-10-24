import Link from "next/link";
import { redirect } from "next/navigation";

import { logout } from "@/app/login/actions";
import { authorizeBiosTenant } from "@/lib/auth/server-tenant-authorization";
import { decideTenantWorkspaceEntry } from "@/lib/auth/tenant-workspace";

export const instant = false;

export default async function TenantWorkspacePage({
  params,
}: PageProps<"/tenants/[tenantCode]">) {
  const { tenantCode } = await params;
  const decision = decideTenantWorkspaceEntry(
    await authorizeBiosTenant(tenantCode),
    tenantCode,
  );

  if (decision.kind === "redirect_to_login") {
    redirect(decision.destination);
  }

  if (decision.kind === "authorized") {
    const { profile, membership } = decision;
    return (
      <WorkspaceFrame>
        <div className="flex flex-col gap-6 sm:flex-row sm:items-start sm:justify-between">
          <div>
            <p className="text-sm font-semibold uppercase tracking-widest text-emerald-700">
              Access confirmed
            </p>
            <h1 className="mt-2 text-3xl font-semibold text-zinc-950">
              {membership.tenant.name}
            </h1>
            <p className="mt-2 text-sm text-zinc-600">
              Welcome, {profile.display_name}. You are securely viewing this organization&apos;s
              BIOS workspace.
            </p>
          </div>
          <SignOutButton />
        </div>

        <dl className="mt-8 grid gap-4 rounded-xl border border-zinc-200 bg-zinc-50 p-5 sm:grid-cols-2">
          <div>
            <dt className="text-xs font-semibold uppercase tracking-wide text-zinc-500">
              Workspace code
            </dt>
            <dd className="mt-1 text-sm font-medium text-zinc-900">
              {membership.tenant.code}
            </dd>
          </div>
          <div>
            <dt className="text-xs font-semibold uppercase tracking-wide text-zinc-500">
              Your access
            </dt>
            <dd className="mt-1 text-sm font-medium text-zinc-900">
              {membership.roles.length > 0
                ? membership.roles.map((role) => role.name).join(", ")
                : "Workspace member"}
            </dd>
          </div>
        </dl>

        <div className="mt-8 rounded-xl border border-dashed border-zinc-300 p-5">
          <h2 className="text-base font-semibold text-zinc-900">Workspace ready</h2>
          <p className="mt-2 text-sm leading-6 text-zinc-600">
            This secure entry point is ready. Evidence, intelligence, and decision tools will
            be introduced in later approved stages.
          </p>
        </div>
      </WorkspaceFrame>
    );
  }

  const content = {
    profile_unavailable: {
      eyebrow: "Profile setup required",
      title: "Your BIOS profile isn’t available",
      message:
        "You are signed in, but your BIOS profile is not active. Contact your BIOS administrator before trying again.",
    },
    workspace_unavailable: {
      eyebrow: "Access unavailable",
      title: "This workspace isn’t available to you",
      message:
        "Check that you used the correct workspace link, or contact your BIOS administrator for access.",
    },
    verification_error: {
      eyebrow: "Access check interrupted",
      title: "We couldn’t verify your access",
      message:
        "Your workspace has not been opened. Please try again. If the problem continues, contact your BIOS administrator.",
    },
  }[decision.kind];

  return (
    <WorkspaceFrame>
      <p className="text-sm font-semibold uppercase tracking-widest text-amber-700">
        {content.eyebrow}
      </p>
      <h1 className="mt-2 text-3xl font-semibold text-zinc-950">{content.title}</h1>
      <p className="mt-3 max-w-xl text-sm leading-6 text-zinc-600">{content.message}</p>
      <div className="mt-8 flex flex-wrap gap-3">
        {decision.kind === "verification_error" ? (
          <Link
            className="rounded-lg bg-zinc-950 px-4 py-2 text-sm font-medium text-white"
            href={`/tenants/${encodeURIComponent(tenantCode)}`}
          >
            Try again
          </Link>
        ) : null}
        <Link
          className="rounded-lg border border-zinc-300 px-4 py-2 text-sm font-medium text-zinc-800"
          href="/"
        >
          Return to BIOS
        </Link>
        <SignOutButton />
      </div>
    </WorkspaceFrame>
  );
}

function WorkspaceFrame({ children }: { children: React.ReactNode }) {
  return (
    <main className="flex min-h-screen items-center justify-center bg-zinc-100 px-6 py-12">
      <section className="w-full max-w-3xl rounded-2xl bg-white p-8 shadow-sm">
        <p className="mb-6 text-sm font-semibold uppercase tracking-widest text-zinc-500">
          BIOS workspace
        </p>
        {children}
      </section>
    </main>
  );
}

function SignOutButton() {
  return (
    <form action={logout}>
      <button
        className="rounded-lg border border-zinc-300 px-4 py-2 text-sm font-medium text-zinc-800"
        type="submit"
      >
        Sign out
      </button>
    </form>
  );
}
