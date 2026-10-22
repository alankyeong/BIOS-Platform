import "server-only";

import { createClient } from "@/lib/supabase/server";
import { resolveBiosUserContext } from "./context";

export async function getBiosUserContext() {
  return resolveBiosUserContext(await createClient());
}
