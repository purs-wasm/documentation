import { defineConfig } from 'vite'
import { fileURLToPath } from 'node:url'
import tailwindcss from '@tailwindcss/vite'

// The PureScript output lives in ../output, so npm packages imported from FFI
// modules (e.g. minisearch) aren't resolvable from the importer's directory.
// Alias them explicitly to this package's node_modules.
const pkg = (name: string) =>
  fileURLToPath(new URL(`./node_modules/${name}`, import.meta.url))

export default defineConfig({
  // Served from https://purs-wasm.github.io/documentation/ (GitHub project page).
  base: '/documentation/',
  plugins: [
    tailwindcss(),
  ],
  resolve: {
    alias: {
      minisearch: pkg('minisearch'),
    },
  },
})
