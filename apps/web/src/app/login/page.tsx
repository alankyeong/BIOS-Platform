import { safeInternalRedirect } from "@/lib/auth/redirect";
import { LoginForm } from "./login-form";

export const instant = false;

type LoginPageProps = {
  searchParams: Promise<Record<string, string | string[] | undefined>>;
};

export default async function LoginPage({ searchParams }: LoginPageProps) {
  const params = await searchParams;
  const next = safeInternalRedirect(typeof params.next === "string" ? params.next : undefined);
  return <main className="flex min-h-screen items-center justify-center bg-zinc-100 px-6 py-12"><section className="w-full max-w-md rounded-2xl bg-white p-8 shadow-sm">
    <p className="mb-2 text-sm font-semibold uppercase tracking-widest text-zinc-500">BIOS</p><h1 className="text-2xl font-semibold text-zinc-950">Sign in</h1><p className="mb-8 mt-2 text-sm text-zinc-600">Use the account provided by your administrator.</p>
    {params.error === "authentication_failed" ? <p aria-live="polite" className="mb-5 rounded-lg bg-red-50 p-3 text-sm text-red-700" role="alert">Authentication could not be completed. Please try again.</p> : null}
    <LoginForm next={next} />
  </section></main>;
}

