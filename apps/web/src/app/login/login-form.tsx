"use client";
import { useActionState } from "react";
import { login, type LoginState } from "./actions";
const initialState: LoginState = {};
export function LoginForm({ next }: { next?: string }) {
  const [state, formAction, pending] = useActionState(login, initialState);
  return <form action={formAction} className="space-y-5">
    <input name="next" type="hidden" value={next ?? ""} />
    <div><label className="mb-2 block text-sm font-medium" htmlFor="email">Email</label><input autoComplete="username" className="w-full rounded-lg border border-zinc-300 px-3 py-2 text-zinc-950" id="email" name="email" required type="email" /></div>
    <div><label className="mb-2 block text-sm font-medium" htmlFor="password">Password</label><input autoComplete="current-password" className="w-full rounded-lg border border-zinc-300 px-3 py-2 text-zinc-950" id="password" name="password" required type="password" /></div>
    {state.error ? <p aria-live="polite" className="text-sm text-red-700" role="alert">{state.error}</p> : null}
    <button className="w-full rounded-lg bg-zinc-950 px-4 py-2.5 font-medium text-white disabled:opacity-60" disabled={pending} type="submit">{pending ? "Signing in…" : "Sign in"}</button>
  </form>;
}

