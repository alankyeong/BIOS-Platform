export function safeInternalRedirect(candidate: string | null | undefined, fallback = "/") {
  if (!candidate || !candidate.startsWith("/") || candidate.startsWith("//") || candidate.includes("\\") || /[\u0000-\u001F\u007F]/.test(candidate)) return fallback;
  try {
    const base = new URL("https://bios.invalid");
    const parsed = new URL(candidate, base);
    return parsed.origin === base.origin ? `${parsed.pathname}${parsed.search}${parsed.hash}` : fallback;
  } catch { return fallback; }
}

