# Finding 02: Full WASM Spike Results

**Date:** 2026-03-04
**Status:** SUCCESS - All targets built and Node test passes

## TL;DR

Kuzu compiles to WASM and **runs graph queries correctly**. Schema creation, node/relationship
insertion, Cypher queries, and graph traversal all work in bun. Three build targets created:
in-memory (browser), Node/Bun, and OPFS-persistent (browser).

## Build Targets

| Target | File | WASM Size | JS Glue | FS Backend | Purpose |
|--------|------|-----------|---------|------------|---------|
| `kuzu_wasm` | kuzu.js/wasm | 10 MB | 193 KB | MEMFS (volatile) | Browser in-memory |
| `kuzu_wasm_node` | kuzu-node.js/wasm | 10 MB | 204 KB | NODERAWFS | Node/Bun testing |
| `kuzu_wasm_opfs` | kuzu-opfs.js/wasm | 11 MB | 152 KB | WasmFS+OPFS (persistent) | Browser persistent |

## Binary Size Analysis

- **10-11 MB WASM** — very reasonable for a full graph database
- Compare: SQLite WASM is ~1.2 MB, but Kuzu includes Cypher parser, query optimizer,
  columnar storage engine, compression (brotli, zstd, lz4, snappy), and more
- The `.wasm` file compresses well with gzip/brotli for network transfer (~3-4 MB compressed)

## Verified Working (Node/Bun Test)

```
Kuzu version: 0.11.2.2
Storage version: 39

--- Creating Schema ---
Table Person has been created.
Table Knows has been created.

--- Querying Data ---
All people:
p.name|p.age
Alice|30
Bob|25
Charlie|35

Relationships:
a.name|b.name|k.since
Alice|Bob|2020
Bob|Charlie|2021

2-hop path from Alice:
b.name
Charlie
Bob

--- Structured Result ---
Success: true
Columns: ["name","age"]
Num tuples: 3
```

## Architecture

### xmake.lua Changes

Added WASM platform detection block to the `kuzu` target:
```lua
if is_plat("wasm") then
    add_defines("__WASM__", "__SINGLE_THREADED__", "BM_MALLOC", {public = true})
    add_cxxflags("-fexceptions", "-w", {force = true})
    add_cflags("-fexceptions", "-w", {force = true})
```

Three binary targets added (browser, node, OPFS) with appropriate Emscripten link flags.

### Embind Wrapper (`wasm/kuzu_wasm.cpp`)

Thin C++ wrapper exposing:
- `KuzuWasm::version()` / `KuzuWasm::storageVersion()` — static info
- `KuzuDatabase(path, bufferPoolSize)` — database constructor
- `KuzuConnection(db)` — connection constructor
- `conn.query(cypher)` — returns string result
- `conn.queryResult(cypher)` — returns JS object with success/error/data/columns/numTuples

### OPFS Persistence Strategy

The `kuzu_wasm_opfs` target uses:
- **WasmFS** (`-sWASMFS`) — modern Emscripten filesystem in C++/WASM linear memory
- **JSPI** (`-sJSPI`) — JavaScript Promise Integration for async-to-sync OPFS bridge
- WasmFS auto-mounts OPFS to `/`, so Kuzu's normal file I/O is transparently persistent

This means `new KuzuDatabase("/my-graph", bufferSize)` in the browser will:
1. Create files in OPFS via WasmFS
2. Persist across page reloads and browser restarts
3. Survive until "Clear Site Data" or explicit deletion

## How to Build

```bash
# Activate Emscripten (Windows)
cmd.exe /c "emsdk_env.bat && xmake f -p wasm -c -y && xmake"

# Or in a Unix-like shell with emsdk in PATH
source emsdk_env.sh
xmake f -p wasm -c -y
xmake
```

## How to Test

### Node/Bun
```bash
cd wasm/test-node
bun run test.mjs
```

### Browser
```bash
cd wasm/test-browser
bun run serve.ts
# Open http://localhost:9876/ (in-memory) or http://localhost:9876/opfs.html (OPFS)
```

## What's Next

1. **Browser testing** — manually verify the browser demos work in Chrome
2. **OPFS persistence verification** — insert data, reload page, confirm data survives
3. **Performance benchmarking** — measure query times for realistic graph sizes
4. **Integration with Skykit** — wire up as optional client-side memory provider
5. **Graphiti integration** — implement the temporal episode/entity/relationship model
   on top of Kuzu WASM

## Known Limitations

- **Single-threaded** — all queries run sequentially (acceptable for conversation memory)
- **No extensions** — Kuzu extensions are not loaded in WASM builds
- **OPFS browser support** — Chrome 102+, Edge, Firefox 111+ (we only target Chromium anyway)
- **JSPI browser support** — Chrome 123+ with origin trial, or flag-enabled
- **No SharedArrayBuffer** — not needed since we use JSPI, but means no multi-threading
