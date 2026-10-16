import { logout } from "./login/actions";

export default function Home() {
  return (
    <main className="flex min-h-screen items-center justify-center bg-zinc-100 px-6">
      <section className="w-full max-w-2xl rounded-2xl bg-white p-8 shadow-sm">
        <div className="flex items-center justify-between gap-6">
          <div>
            <p className="text-sm font-semibold uppercase tracking-widest text-zinc-500">BIOS</p>
            <h1 className="mt-2 text-3xl font-semibold text-zinc-950">Intelligence workspace</h1>
          </div>
          <form action={logout}>
            <button className="rounded-lg border border-zinc-300 px-4 py-2 text-sm font-medium text-zinc-800" type="submit">Sign out</button>
          </form>
        </div>
      </section>
    </main>
  );
}

