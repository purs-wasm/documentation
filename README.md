# Documentation site for `purs-backend-wasm`

The documentation content is **not** maintained here. It lives in the
[`purescript-backend-wasm`](https://github.com/katsujukou/purescript-backend-wasm)
source repository under `docs/`, which is the single source of truth.

This repo only holds the site tooling. `scripts/sync-docs.sh` fetches the latest
Markdown on demand, renders it to HTML with [`marked`](https://marked.js.org/),
and writes the fragments into `web/docs/` for the Halogen SPA to load and inject.

## Syncing the docs

```sh
# Fetch + render the latest docs from the source repo's main branch
scripts/sync-docs.sh

# Pin to a specific branch, tag, or commit
scripts/sync-docs.sh v1.2.0

# Render from a local clone instead of cloning over the network (offline)
DOCS_LOCAL=~/Projects/purescript-backend-wasm scripts/sync-docs.sh
```

Requires `marked` (declared in `web/package.json`); run `pnpm install` in `web/`
first. Run the sync before building/serving the site (and as a prebuild step in
CI). The output includes `web/docs/.synced-from` recording the source provenance.

> Note: internal cross-links in the docs still point at `.md` (e.g.
> `./optimizations.md`). The SPA router is expected to resolve those — the script
> intentionally does not rewrite them, to avoid imposing a routing scheme.

See `scripts/sync-docs.sh` for all configuration options (`DOCS_REPO`,
`DOCS_REF`, `DOCS_SUBDIR`, `DOCS_DEST`, `DOCS_LOCAL`).
