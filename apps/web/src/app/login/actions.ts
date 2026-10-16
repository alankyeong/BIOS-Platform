"use server";
import { redirect } from "next/navigation";
import { safeInternalRedirect } from "@/lib/auth/redirect";
import { createClient } from "@/lib/supabase/server";
export type LoginState = { error?: string };
export async function login(_state: LoginState, formData: FormData): Promise<LoginState> {
  const email = formData.get("email");
  const password = formData.get("password");
  if (typeof email !== "string" || typeof password !== "string") return { error: "Unable to sign in with those credentials." };
  const supabase = await createClient();
  const { error } = await supabase.auth.signInWithPassword({ email, password });
  if (error) return { error: "Unable to sign in with those credentials." };
  redirect(safeInternalRedirect(formData.get("next")?.toString()));
}
export async function logout() {
  const supabase = await createClient();
  await supabase.auth.signOut();
  redirect("/login");
}

