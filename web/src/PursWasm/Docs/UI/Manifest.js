// Build-time docs manifest + rendered HTML, produced by web/scripts/render-docs.mjs
// (run via scripts/sync-docs.sh before dev/build). The manifest describes the
// section/page tree; the HTML fragments are eagerly inlined here so the SPA can
// render a page without a runtime fetch. Adding/removing docs upstream requires
// no change to this file — it is fully data driven off manifest.json.

import manifest from "../../web/docs/manifest.json";

const htmls = import.meta.glob("../../web/docs/**/*.html", {
  query: "?raw",
  import: "default",
  eager: true,
});

const htmlOf = (rel) => htmls["../../web/docs/" + rel] ?? "";

const withHtml = (p) => ({ path: p.path, title: p.title, nav: p.nav ?? p.title, html: htmlOf(p.html) });

export const sections = manifest.sections.map((s) => ({
  id: s.id,
  title: s.title,
  landing: withHtml(s.landing),
  pages: s.pages.map(withHtml),
}));
