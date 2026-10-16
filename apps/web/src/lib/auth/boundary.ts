const PUBLIC_ROUTES = new Set(["/login", "/auth/callback"]);
export const isPublicAuthRoute = (pathname: string) => PUBLIC_ROUTES.has(pathname);
export function authBoundaryRedirect(pathname: string, authenticated: boolean) {
  if (!authenticated && !isPublicAuthRoute(pathname)) return "/login";
  if (authenticated && pathname === "/login") return "/";
  return null;
}

