-- | The published `purs-wasm` npm package version, inlined at build time by
-- | vite (see vite.config.ts `define`). Empty when unavailable (offline build);
-- | the header hides the version pill in that case.
module PursWasm.Docs.UI.Version (pursWasmVersion) where

foreign import pursWasmVersion :: String
