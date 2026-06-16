// render-docs.mjs — Render Markdown to HTML with `marked`, adding
// GitHub-compatible heading ids (so in-page #anchor links resolve) and
// build-time syntax highlighting via `shiki` for purescript / javascript / wat.
//
// The upstream docs are organised into sibling section directories
// (getting-started/, developers-guide/, …). This script is *directory driven*:
// the SECTIONS table below maps each upstream subdirectory to a site section,
// its route prefix, and the order/labels of its pages. To surface a new section
// (e.g. design-decisions/) just add an entry — no per-page wiring elsewhere.
//
// Outputs into <destDir> (web/docs):
//   * <dir>/<file>.html            rendered page fragments (per section)
//   * local/<file>.html            pages authored in this repo under content/
//   * manifest.json                the section/page tree the SPA reads to build
//                                  its sidebar, routes, and content lookup
//   * search-index.json            one record per heading, for full-text search
//
// Usage: node web/scripts/render-docs.mjs <srcDir> <destDir>
// Invoked by scripts/sync-docs.sh. Lives under web/ so it resolves the
// marked / marked-gfm-heading-id / shiki packages from web/node_modules.

import { promises as fs } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { marked } from "marked";
import { gfmHeadingId } from "marked-gfm-heading-id";
import { createHighlighter } from "shiki";

const [srcDir, destDir] = process.argv.slice(2);

if (!srcDir || !destDir) {
  console.error("usage: render-docs.mjs <srcDir> <destDir>");
  process.exit(1);
}

const REPO_ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../..");
const CONTENT_DIR = path.join(REPO_ROOT, "content");

// Dual themes: the light theme is applied inline, the dark theme as CSS vars
// (--shiki-dark) that index.css switches to under `.dark`.
const THEMES = { light: "github-light", dark: "github-dark" };

// Markdown code-fence language -> shiki language. Anything not listed here
// (e.g. ```text, ```plain, or no language) is rendered as a plain code block.
const LANG_ALIASES = {
  purescript: "purescript",
  purs: "purescript",
  javascript: "javascript",
  js: "javascript",
  wat: "wasm",
  wasm: "wasm",
};

// ---------------------------------------------------------------------------
// Site information architecture. Each section maps an upstream subdirectory to
// a route prefix and an ordered page list. `landing` is the page shown at the
// prefix root (and reached by clicking the sidebar headline); it is either an
// upstream file (`file`) or a page authored in this repo (`content`). `pages`
// are listed in order with a short sidebar `nav` label; files not listed are
// appended alphabetically using their H1 as the label.
// ---------------------------------------------------------------------------
const SECTIONS = [
  {
    id: "getting-started",
    title: "Getting Started",
    dir: "getting-started",
    prefix: "/getting-started",
    landing: { content: "getting-started.md" },
    pages: [
      { file: "overview.md", nav: "Overview" },
      { file: "differences-to-PS-for-JS.md", nav: "Differences from JS" },
      { file: "ffi-and-js-interop.md", nav: "FFI & JS Interop" },
      { file: "module-resolution-and-ulib.md", nav: "Modules & ulib" },
      { file: "performance-and-limitations.md", nav: "Performance & Limits" },
    ],
  },
  {
    id: "developers-guide",
    title: "Developer's Guide",
    dir: "developers-guide",
    prefix: "/dev",
    landing: { content: "developers-guide.md" },
    pages: [
      { file: "supported-features.md", nav: "Supported Features" },
      { file: "runtime-representation.md", nav: "Runtime Representation" },
      { file: "compilation-pipeline.md", nav: "Compilation Pipeline" },
      { file: "optimizations.md", nav: "Optimizations" },
      { file: "interop.md", nav: "JS↔WASM Interop" },
      { file: "a-tour-for-hackers.md", nav: "A Tour for Hackers"}
    ],
  },
];

// Excluded docs (e.g. design-decisions/) are not part of the site; links to
// them are rewritten to the source repo on GitHub instead of 404-ing.
const GH_BLOB = "https://github.com/purs-wasm/purescript-backend-wasm/blob/main/docs";

// docs-relative markdown path (e.g. "developers-guide/interop.md") -> app route.
// A section's landing file maps to the prefix root; other pages drop the
// extension (so "./interop.md" -> "/dev/interop", clean and dev-server friendly).
const routeMap = {};
for (const s of SECTIONS) {
  if (s.landing.file) routeMap[`${s.dir}/${s.landing.file}`] = s.prefix;
  for (const p of s.pages) {
    routeMap[`${s.dir}/${p.file}`] = `${s.prefix}/${p.file.replace(/\.(md|markdown)$/i, "")}`;
  }
}

// Rewrite the cross-document .md links in rendered HTML (the upstream docs link
// each other with relative paths like "./interop.md#anchor"). `fileDir` is the
// linking file's directory relative to the docs root.
function rewriteLinks(html, fileDir) {
  return html.replace(/href="([^"]+)"/g, (whole, href) => {
    if (/^(https?:|mailto:|#|\/)/i.test(href)) return whole; // external / anchor / already absolute
    const [rawPath, anchor] = href.split("#");
    if (!/\.(md|markdown)$/i.test(rawPath)) return whole;
    const rel = path.posix.normalize(path.posix.join(fileDir, rawPath));
    const frag = anchor ? `#${anchor}` : "";
    if (routeMap[rel]) return `href="${routeMap[rel]}${frag}"`;
    if (rel.startsWith("design-decisions/")) return `href="${GH_BLOB}/${rel}${frag}"`;
    return whole;
  });
}

// Turn `> **Note** …` callouts into an icon: tag the blockquote `note` and swap
// the leading bold "Note" label for an info icon span (styled/themed in index.css).
function decorateNotes(html) {
  return html.replace(
    /<blockquote>\s*<p><strong>Note<\/strong>/g,
    '<blockquote class="note">\n<p><span class="note-icon" role="img" aria-label="Note"></span>',
  );
}

const highlighter = await createHighlighter({
  themes: [THEMES.light, THEMES.dark],
  langs: ["purescript", "javascript", "wasm"],
});

const escapeHtml = (s) =>
  s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");

const stripTags = (s) =>
  s
    .replace(/<[^>]*>/g, " ")
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
    .replace(/&amp;/g, "&")
    .replace(/\s+/g, " ")
    .trim();

// First level-1 heading, with inline markdown stripped — used as the page title
// (search docTitle and the default sidebar label). Falls back to the filename.
function titleOf(md, file) {
  const m = md.match(/^#\s+(.+?)\s*$/m);
  if (m) return m[1].replace(/`/g, "").replace(/[*_]/g, "").trim();
  return path.basename(file).replace(/\.(md|markdown)$/i, "");
}

// Split rendered HTML into one search record per heading section, carrying the
// heading text, its anchor id, and the plain text of the body that follows.
function sectionsOf(html, route) {
  const records = [];
  const re = /<h([1-6]) id="([^"]*)"[^>]*>([\s\S]*?)<\/h\1>/g;
  const headings = [];
  let m;
  while ((m = re.exec(html))) {
    headings.push({ index: m.index, end: re.lastIndex, anchor: m[2], heading: stripTags(m[3]) });
  }
  for (let i = 0; i < headings.length; i++) {
    const h = headings[i];
    const bodyEnd = i + 1 < headings.length ? headings[i + 1].index : html.length;
    records.push({
      id: `${route.path}#${h.anchor}`,
      path: route.path,
      anchor: h.anchor,
      docTitle: route.title,
      heading: h.heading,
      text: stripTags(html.slice(h.end, bodyEnd)),
    });
  }
  return records;
}

// GitHub-style heading ids, e.g. "## Worked example: the Effect monad" ->
// id="worked-example-the-effect-monad", matching the TOC anchors in the source.
marked.use(gfmHeadingId());

// Override the code-block renderer to emit shiki-highlighted HTML.
marked.use({
  renderer: {
    code({ text, lang }) {
      const key = (lang ?? "").trim().split(/\s+/)[0].toLowerCase();
      const shikiLang = LANG_ALIASES[key];
      if (shikiLang) {
        return highlighter.codeToHtml(text, { lang: shikiLang, themes: THEMES });
      }
      return `<pre><code>${escapeHtml(text)}</code></pre>`;
    },
  },
});

const exists = (p) => fs.stat(p).then(() => true, () => false);

// Render one Markdown file to <dst>/<relHtml>, returning { title, html }. When
// `linkDir` is given, cross-document .md links are rewritten to app routes.
async function renderFile(srcFile, dst, relHtml, linkDir) {
  const md = await fs.readFile(srcFile, "utf8");
  let html = decorateNotes(marked.parse(md));
  if (linkDir != null) html = rewriteLinks(html, linkDir);
  const out = path.join(dst, relHtml);
  await fs.mkdir(path.dirname(out), { recursive: true });
  await fs.writeFile(out, html);
  return { title: titleOf(md, srcFile), html };
}

const searchIndex = [];

// Resolve a section page descriptor to its source file + rendered output path.
function pageSource(section, file) {
  const rel = `${section.dir}/${file.replace(/\.(md|markdown)$/i, ".html")}`;
  return { src: path.join(srcDir, section.dir, file), rel };
}

// --- Render each section, building the manifest -----------------------------
const manifest = { sections: [] };
let pageCount = 0;

for (const section of SECTIONS) {
  const dirPath = path.join(srcDir, section.dir);
  if (!(await exists(dirPath))) {
    console.error(`[render-docs] skipping section '${section.id}': ${dirPath} not found`);
    continue;
  }

  // Landing page: either an upstream file or one authored under content/.
  let landing;
  if (section.landing.content) {
    const src = path.join(CONTENT_DIR, section.landing.content);
    const rel = `local/${section.landing.content.replace(/\.(md|markdown)$/i, ".html")}`;
    const { title, html } = await renderFile(src, destDir, rel);
    landing = { path: section.prefix, title, html: rel };
    searchIndex.push(...sectionsOf(html, { path: section.prefix, title }));
  } else {
    const { src, rel } = pageSource(section, section.landing.file);
    const { title, html } = await renderFile(src, destDir, rel, section.dir);
    landing = { path: section.prefix, title, html: rel };
    searchIndex.push(...sectionsOf(html, { path: section.prefix, title }));
  }
  pageCount++;

  const pages = [];
  for (const page of section.pages) {
    const { src, rel } = pageSource(section, page.file);
    if (!(await exists(src))) {
      console.error(`[render-docs] WARNING: ${section.id}: ${page.file} not found, skipping`);
      continue;
    }
    const routePath = `${section.prefix}/${page.file.replace(/\.(md|markdown)$/i, "")}`;
    const { title, html } = await renderFile(src, destDir, rel, section.dir);
    pages.push({ path: routePath, title, nav: page.nav ?? title, html: rel });
    searchIndex.push(...sectionsOf(html, { path: routePath, title }));
    pageCount++;
  }

  manifest.sections.push({ id: section.id, title: section.title, landing, pages });
}

await fs.writeFile(path.join(destDir, "manifest.json"), JSON.stringify(manifest));
await fs.writeFile(path.join(destDir, "search-index.json"), JSON.stringify(searchIndex));

console.error(
  `[render-docs] ${manifest.sections.length} sections, ${pageCount} pages, ${searchIndex.length} search sections`,
);
