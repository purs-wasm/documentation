import { defineConfig } from 'vite'
import { fileURLToPath } from 'node:url'
import tailwindcss from '@tailwindcss/vite'

// The PureScript output lives in ../output, so npm packages imported from FFI
// modules (e.g. minisearch) aren't resolvable from the importer's directory.
// Alias them explicitly to this package's node_modules.
const pkg = (name: string) =>
  fileURLToPath(new URL(`./node_modules/${name}`, import.meta.url))

// The published version of the `purs-wasm` npm package, resolved at build time
// and inlined as `__PURS_WASM_VERSION__` (see src/.../Version.js). The header
// renders it as a version pill. Falls back to an empty string (pill hidden) if
// the registry is unreachable, e.g. offline dev.
async function fetchPursWasmVersion(): Promise<string> {
  try {
    const res = await fetch('https://registry.npmjs.org/purs-wasm/latest')
    if (!res.ok) return ''
    const json = (await res.json()) as { version?: string }
    return json.version ?? ''
  } catch {
    return ''
  }
}

export default defineConfig(async () => ({
  // Served from https://purs-wasm.github.io/documentation/ (GitHub project page).
  base: '/documentation/',
  define: {
    __PURS_WASM_VERSION__: JSON.stringify(await fetchPursWasmVersion()),
  },
  plugins: [
    tailwindcss(),
  ],
  resolve: {
    alias: {
      minisearch: pkg('minisearch'),
    },
  },
}))
