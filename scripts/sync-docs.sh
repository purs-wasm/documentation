#!/usr/bin/env bash
#
# sync-docs.sh — Fetch the `docs/` directory from the purescript-backend-wasm
# source repository and render it into the web app's `web/docs/` directory.
#
# The actual rendering (Markdown -> HTML via marked + shiki, plus a manifest.json
# describing the section/page tree and a search-index.json) is done by the Node
# renderer, which is *directory driven*: see web/scripts/render-docs.mjs for the
# section table that maps each upstream subdir (getting-started/, developers-guide/)
# to a site section. Adding a section there needs no change to this script.
#
# The Markdown is the single source of truth in the source repo; this site never
# commits the docs (see .gitignore). The Halogen SPA loads the manifest + rendered
# HTML fragments from web/docs/ to build its sidebar, routes, and content. Run this
# before building/serving the site, or whenever you want the latest docs.
#
# Usage:
#   scripts/sync-docs.sh                 # fetch from default repo @ main
#   scripts/sync-docs.sh v1.2.0          # fetch a specific branch/tag/commit
#   scripts/sync-docs.sh -l ~/Projects/purescript-backend-wasm
#                                        # render from a local clone (offline)
#   DOCS_LOCAL=~/Projects/purescript-backend-wasm scripts/sync-docs.sh
#                                        # same, via environment variable
#
# Benchmark images: the docs reference result charts at
# /documentation/images/bench/<name>.png, served from this site's public assets.
# The images themselves are published on the source project's GitHub Pages, so we
# discover the set referenced by the rendered docs and download each one into
# web/public/images/bench/ (git-ignored — generated, like web/docs).
#
# Environment variables:
#   DOCS_REPO    Git URL of the source repo
#                (default: https://github.com/purs-wasm/purescript-backend-wasm.git)
#   DOCS_REF     Branch, tag, or commit to fetch (default: main; overridden by $1)
#   DOCS_SUBDIR  Subdirectory in the source repo to sync (default: docs)
#   DOCS_DEST    Destination for rendered HTML (default: web/docs)
#   DOCS_LOCAL   Path to a local clone of the source repo. When set, docs are
#                rendered from there instead of cloning over the network.
#                (the -l/--local flag sets this too, taking precedence.)
#   BENCH_BASE   Base URL the benchmark images are published at
#                (default: https://purs-wasm.github.io/purescript-backend-wasm)
#   BENCH_DEST   Destination for downloaded images (default: web/public/images/bench)

set -euo pipefail

usage() {
  cat >&2 <<'EOF'
Usage: sync-docs.sh [-l|--local <dir>] [<ref>]
  <ref>              git branch/tag/commit to fetch (default: main)
  -l, --local <dir>  render from a local clone instead of fetching over the network
  -h, --help         show this help
EOF
  exit "${1:-0}"
}

# Parse flags; the first non-flag positional is the git ref (branch/tag/commit).
REF_ARG=""
while [ $# -gt 0 ]; do
  case "$1" in
    -l | --local)
      [ $# -ge 2 ] || { printf '%s\n' "missing argument for $1" >&2; exit 2; }
      DOCS_LOCAL="$2"; shift 2 ;;
    --local=*) DOCS_LOCAL="${1#*=}"; shift ;;
    --) shift ;; # drop a stray separator (e.g. forwarded by `pnpm run sync --`)
    -h | --help) usage 0 ;;
    -*) printf '%s\n' "unknown option: $1" >&2; usage 2 ;;
    *) REF_ARG="$1"; shift ;;
  esac
done

DOCS_REPO="${DOCS_REPO:-https://github.com/purs-wasm/purescript-backend-wasm.git}"
DOCS_REF="${REF_ARG:-${DOCS_REF:-main}}"
DOCS_SUBDIR="${DOCS_SUBDIR:-docs}"
BENCH_BASE="${BENCH_BASE:-https://purs-wasm.github.io/purescript-backend-wasm}"

# Resolve paths relative to the repo root (the parent of scripts/).
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DOCS_DEST="${DOCS_DEST:-$REPO_ROOT/web/docs}"
BENCH_DEST="${BENCH_DEST:-$REPO_ROOT/web/public/images/bench}"

log() { printf '\033[1;34m[sync-docs]\033[0m %s\n' "$*"; }
err() { printf '\033[1;31m[sync-docs]\033[0m %s\n' "$*" >&2; }

RENDERER="$REPO_ROOT/web/scripts/render-docs.mjs"
if [ ! -f "$REPO_ROOT/web/node_modules/marked/package.json" ]; then
  err "'marked' is not installed. Run 'pnpm install' in web/ first."
  exit 1
fi

# Render every Markdown file under $src to HTML under $dst (preserving the
# directory layout, foo.md -> foo.html) via the Node renderer, which adds
# GitHub-style heading ids so in-page #anchor links resolve.
render_tree() {
  local src="$1" dst="$2"
  if [ ! -d "$src" ]; then
    err "subdirectory '$DOCS_SUBDIR' not found in source ($src)"
    exit 1
  fi
  rm -rf "$dst"
  mkdir -p "$dst"
  node "$RENDERER" "$src" "$dst"
}

# Download every benchmark image referenced by the rendered docs from BENCH_BASE
# into BENCH_DEST. Individual misses are warned about but don't fail the sync, so
# a not-yet-published chart never blocks a deploy.
sync_bench() {
  local names
  names="$(grep -rho 'images/bench/[A-Za-z0-9._-]*\.png' "$DOCS_DEST" 2>/dev/null \
    | sed 's#.*/##' | sort -u)"
  if [ -z "$names" ]; then
    log "No benchmark images referenced in docs; skipping image sync"
    return
  fi
  rm -rf "$BENCH_DEST"
  mkdir -p "$BENCH_DEST"
  local ok=0 miss=0
  while IFS= read -r name; do
    [ -z "$name" ] && continue
    # Retry transient failures (GitHub Pages occasionally rate-limits/resets) so a
    # blip doesn't leave a broken image on the deployed site.
    if curl -fsSL --retry 5 --retry-delay 2 --retry-all-errors \
      "$BENCH_BASE/$name" -o "$BENCH_DEST/$name" 2>/dev/null; then
      ok=$((ok + 1))
    else
      rm -f "$BENCH_DEST/$name"
      err "could not fetch benchmark image: $BENCH_BASE/$name (skipping)"
      miss=$((miss + 1))
    fi
  done <<<"$names"
  log "Downloaded $ok benchmark image(s) into $BENCH_DEST ($miss missing)"
}

if [ -n "${DOCS_LOCAL:-}" ]; then
  # --- Offline: render from a local clone -------------------------------------
  log "Rendering from local clone: $DOCS_LOCAL"
  SRC_DOCS="$DOCS_LOCAL/$DOCS_SUBDIR"
  SOURCE_REF="$(git -C "$DOCS_LOCAL" rev-parse --short HEAD 2>/dev/null || echo 'unknown')"
  SOURCE_DESC="local clone @ $SOURCE_REF"
else
  # --- Network: shallow, blobless, sparse clone of just the docs subdir -------
  log "Fetching '$DOCS_SUBDIR' from $DOCS_REPO @ $DOCS_REF"
  TMP="$(mktemp -d)"
  trap 'rm -rf "$TMP"' EXIT

  git clone \
    --quiet \
    --depth 1 \
    --filter=blob:none \
    --sparse \
    --branch "$DOCS_REF" \
    "$DOCS_REPO" "$TMP" 2>/dev/null \
    || git clone --quiet --depth 1 --filter=blob:none --sparse "$DOCS_REPO" "$TMP"

  git -C "$TMP" sparse-checkout set "$DOCS_SUBDIR"

  # If --branch failed (e.g. DOCS_REF is a commit SHA), check it out explicitly.
  if [ "$(git -C "$TMP" rev-parse --abbrev-ref HEAD)" != "$DOCS_REF" ] \
    && [ "$DOCS_REF" != "main" ]; then
    git -C "$TMP" fetch --quiet --depth 1 origin "$DOCS_REF" 2>/dev/null \
      && git -C "$TMP" checkout --quiet FETCH_HEAD 2>/dev/null || true
  fi

  SRC_DOCS="$TMP/$DOCS_SUBDIR"
  SOURCE_REF="$(git -C "$TMP" rev-parse --short HEAD)"
  SOURCE_DESC="$DOCS_REPO @ $DOCS_REF ($SOURCE_REF)"
fi

log "Rendering Markdown -> HTML (marked + gfm heading ids)"
render_tree "$SRC_DOCS" "$DOCS_DEST"

# Record provenance so it's obvious where the rendered docs came from.
cat >"$DOCS_DEST/.synced-from" <<EOF
# Auto-generated by scripts/sync-docs.sh — do not edit.
# These HTML files are rendered from the purescript-backend-wasm docs.
source = "$SOURCE_DESC"
ref    = "$DOCS_REF"
EOF

log "Downloading benchmark images referenced by the docs from $BENCH_BASE"
sync_bench

log "Done. Rendered $(find "$DOCS_DEST" -name '*.html' | wc -l | tr -d ' ') HTML files into $DOCS_DEST"
