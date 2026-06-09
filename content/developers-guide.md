# Developer's Guide

This section publishes technical documentation for readers interested in the
compiler's internals and for future contributors.

## Table of Contents

- **[Supported Features](/dev/supported-features.md)** — the PureScript language
  features the current `purs-wasm` compiler supports.

- **[Runtime Representation](/dev/runtime-representation.md)** — how PureScript
  values are represented as WebAssembly GC values.

- **[Compilation Pipeline](/dev/compilation-pipeline.md)** — a concise
  walkthrough of how CoreFn and Externs are compiled down to WebAssembly.

- **[Optimizations](/dev/optimizations.md)** — a thorough, detailed account of
  the optimization techniques `purs-wasm` performs.

## Design Decisions

Adding WebAssembly as a compilation target for PureScript is a substantial
undertaking, and it forces many decisions along the way. We record every such
decision as an **ADR (Architectural Decision Record)**.

Why the current `purs-wasm` compiler behaves the way it does — and why the
competing alternatives were not chosen — is described in detail in these ADRs.
If you are interested, see
[https://github.com/katsujukou/purescript-backend-wasm/tree/main/docs/design-decisions](https://github.com/katsujukou/purescript-backend-wasm/tree/main/docs/design-decisions).
