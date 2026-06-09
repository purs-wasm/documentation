// Scroll to the element matching the current URL hash. The Markdown HTML is
// injected via innerHTML after the route resolves, so the browser's own
// on-load hash scroll runs too early (the heading doesn't exist yet). We
// re-trigger it from a lifecycle effect, on the next frame to be safe.
export const scrollToCurrentHash = () => {
  const id = decodeURIComponent(window.location.hash.replace(/^#/, ""));
  if (!id) return;
  requestAnimationFrame(() => {
    const el = document.getElementById(id);
    if (el) el.scrollIntoView({ block: "start" });
  });
};

// Root-absolute links authored in the Markdown (e.g. /dev/optimizations.md) are
// missing the deploy base path, so prefix it here after the HTML is injected.
// Idempotent, and a no-op when served from the root.
export const prefixInternalLinks = () => {
  const base = (import.meta.env && import.meta.env.BASE_URL) || "/";
  if (base === "/") return;
  const prefix = base.replace(/\/$/, "");
  document.querySelectorAll(".md-doc a[href^='/']").forEach((a) => {
    const href = a.getAttribute("href");
    if (href.startsWith("//") || href.startsWith(prefix + "/")) return;
    a.setAttribute("href", prefix + href);
  });
};
