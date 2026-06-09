// Vite injects the configured base path (e.g. "/documentation/") here at build
// time; in dev it is "/". Always ends with a trailing slash. The guard keeps
// this safe under plain Node (e.g. the spago test runner), where import.meta.env
// is undefined.
export const baseUrl =
  (import.meta.env && import.meta.env.BASE_URL) || "/";
