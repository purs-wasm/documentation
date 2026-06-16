// `__PURS_WASM_VERSION__` is replaced at build time by vite's `define` with the
// published npm version (a string literal). The `typeof` guard keeps this safe
// outside the vite bundle (e.g. `spago test` in node), where it stays "".
export const pursWasmVersion =
  typeof __PURS_WASM_VERSION__ === "string" ? __PURS_WASM_VERSION__ : "";
