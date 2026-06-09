// render-docs.mjs — Render a tree of Markdown files to HTML with `marked`,
// adding GitHub-compatible heading ids (so in-page #anchor links resolve) and
// build-time syntax highlighting via `shiki` for purescript / javascript / wat.
//
// Usage: node web/scripts/render-docs.mjs <srcDir> <destDir>
//
// Invoked by scripts/sync-docs.sh. Lives under web/ so it resolves the
// marked / marked-gfm-heading-id / shiki packages from web/node_modules.

import { promises as fs } from "node:fs";
import path from "node:path";
import { marked } from "marked";
import { gfmHeadingId } from "marked-gfm-heading-id";
import { createHighlighter } from "shiki";

const [srcDir, destDir] = process.argv.slice(2);

if (!srcDir || !destDir) {
  console.error("usage: render-docs.mjs <srcDir> <destDir>");
  process.exit(1);
}

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

const highlighter = await createHighlighter({
  themes: [THEMES.light, THEMES.dark],
  langs: ["purescript", "javascript", "wasm"],
});

const escapeHtml = (s) =>
  s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");

// Docs reachable as app routes — keep in sync with web/.../UI/Route.purs. Only
// these are added to the search index, so every result links to a real page.
// Keyed by path relative to the docs root.
const ROUTED = {
  "supported-features.md": { path: "/dev/supported-features.md", title: "Supported Features" },
  "runtime-representation.md": { path: "/dev/runtime-representation.md", title: "Runtime Representations" },
  "compilation-pipeline.md": { path: "/dev/compilation-pipeline.md", title: "Compilation Pipeline" },
  "optimizations.md": { path: "/dev/optimizations.md", title: "Optimizations" },
  "interop.md": { path: "/dev/interop.md", title: "JS interop" },
};

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

async function walk(dir) {
  const entries = await fs.readdir(dir, { withFileTypes: true });
  const files = await Promise.all(
    entries.map((e) => {
      const full = path.join(dir, e.name);
      return e.isDirectory() ? walk(full) : Promise.resolve([full]);
    }),
  );
  return files.flat();
}

let rendered = 0;
const searchIndex = [];
for (const file of await walk(srcDir)) {
  const rel = path.relative(srcDir, file);
  if (path.basename(rel) === ".DS_Store") continue;

  if (/\.(md|markdown)$/i.test(rel)) {
    const md = await fs.readFile(file, "utf8");
    const html = marked.parse(md);
    const out = path.join(destDir, rel.replace(/\.(md|markdown)$/i, ".html"));
    await fs.mkdir(path.dirname(out), { recursive: true });
    await fs.writeFile(out, html);
    rendered++;

    const route = ROUTED[rel];
    if (route) searchIndex.push(...sectionsOf(html, route));
  } else {
    const out = path.join(destDir, rel);
    await fs.mkdir(path.dirname(out), { recursive: true });
    await fs.copyFile(file, out);
  }
}

await fs.writeFile(path.join(destDir, "search-index.json"), JSON.stringify(searchIndex));

console.error(
  `[render-docs] rendered ${rendered} Markdown files, ${searchIndex.length} search sections`,
);
