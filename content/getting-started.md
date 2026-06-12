# Getting Started

New to purs-wasm? Start here. This section walks you from your first build
through the things you need to know to write PureScript that compiles to fast,
idiomatic WebAssembly.

If you just want to get something running, read the **Overview** first. The rest
of the pages go deeper into how the compiler resolves modules, how to reach
JavaScript when you need to, and how to get the most out of the backend.

## Table of Contents

- **[Overview](/getting-started/overview)** — what purs-wasm is, how to install
  it, and how to compile and run your first program.

- **[Differences from JavaScript-backend PureScript](/getting-started/differences-to-PS-for-JS)**
  — what changes when you target wasm instead of JavaScript, and the handful of
  habits that let purs-wasm's aggressive optimizations do their best work.

- **[FFI & JS Interop](/getting-started/ffi-and-js-interop)** — how to write a
  `foreign import` and how to call your compiled wasm exports from JavaScript —
  and when reaching for the FFI helps versus when it gets in the optimizer's way.

- **[Module Resolution & ulib](/getting-started/module-resolution-and-ulib)** —
  how purs-wasm walks the import graph from your entry modules and, for each
  module, chooses between your project's `purs` output and the precompiled
  **ulib** library.

- **[Performance & Limitations](/getting-started/performance-and-limitations)** —
  the benchmark suite that guards against regressions, where wasm pulls ahead of
  the JavaScript backends, and the cases that are not yet supported or fast.
