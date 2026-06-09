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
