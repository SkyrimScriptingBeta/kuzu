# Finding 02: Full WASM Spike Results

**Date:** 2026-03-04
**Status:** SUCCESS - OPFS persistence verified across hard page reloads

## TL;DR

Kuzu compiles to WASM and **runs graph queries correctly** with **persistent OPFS storage**.
Schema creation, node/relationship insertion, Cypher queries, and graph traversal all work.
Data survives hard browser refreshes. Zero source code changes to Kuzu itself.

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

## OPFS Persistence Verified

```
=== First Load ===
Creating database at /opfs/kuzu-test-db ...
Database created and connected!
> CREATE NODE TABLE IF NOT EXISTS Person(name STRING, age INT64, PRIMARY KEY (name))
> CREATE (p:Person {name: 'Alice', age: 30})
> CREATE (p:Person {name: 'Bob', age: 25})
> CREATE (p:Person {name: 'Charlie', age: 35})
> MATCH (a:Person)-[k:Knows]->(b:Person) RETURN ...
Alice|Bob|2020
Bob|Charlie|2021

=== After Hard Refresh (Ctrl+Shift+R) ===
=== Persistence Verification ===
Opening database at /opfs/kuzu-test-db ...
DATA PERSISTED ACROSS PAGE RELOAD!
p.name|p.age
Alice|30
Bob|25
Charlie|35
Found 3 rows
```

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

### The Correct Architecture (arrived at through iteration)

```
Main Page (opfs.html)
  |
  | postMessage RPC
  v
Web Worker (kuzu-worker.js)
  |
  | importScripts + createKuzu({ mainScriptUrlOrBlob })
  v
Emscripten WASM Module (kuzu-opfs.js/wasm)
  |
  | wasmfs_before_preload() hook
  v
WasmFS OPFS Backend mounted at /opfs
  |
  | standard POSIX file I/O (fopen, fread, fwrite...)
  v
Kuzu Database Engine (unchanged C++ code)
```

Key constraints that drove this design:
1. **OPFS backend must initialize off the main browser thread** — Emscripten assertion enforces this
2. **pthreads required** — WasmFS OPFS backend uses `createSyncAccessHandle()` which needs worker context
3. **All libraries compiled twice** — once without pthread (for MEMFS/Node targets), once with pthread (for OPFS target)
4. **`mainScriptUrlOrBlob`** — must be set when calling `createKuzu()` inside a worker so Emscripten spawns pthread workers using the correct script URL

### xmake.lua Changes

Refactored with `define_kuzu_targets(suffix)` function to create all 17 third-party libs + kuzu
in both single-threaded and pthreaded (`_mt`) variants:

```lua
if is_plat("wasm") then
    add_defines("__WASM__", "__SINGLE_THREADED__", "BM_MALLOC", {public = true})
    add_cxxflags("-fexceptions", "-w", {force = true})
    add_cflags("-fexceptions", "-w", {force = true})
    -- _mt suffix targets also get: add_cxxflags("-pthread", {force = true})
```

### Embind Wrapper (`wasm/kuzu_wasm.cpp`)

Thin C++ wrapper exposing:
- `KuzuWasm::version()` / `KuzuWasm::storageVersion()` / `KuzuWasm::hasOPFS()` — static info
- `KuzuDatabase(path, bufferPoolSize)` — database constructor
- `KuzuConnection(db)` — connection constructor
- `conn.query(cypher)` — returns string result
- `conn.queryResult(cypher)` — returns JS object with success/error/data/columns/numTuples

OPFS mount hook (only in WasmFS builds):
```cpp
#if HAS_WASMFS
extern "C" {
void wasmfs_before_preload(void) {
    backend_t opfs = wasmfs_create_opfs_backend();
    wasmfs_create_directory("/opfs", 0777, opfs);
}
} // extern "C"
#endif
```

### Web Worker (`kuzu-worker.js`)

RPC layer between main page and WASM module:
```javascript
importScripts('kuzu-opfs.js');
const kuzuScriptUrl = new URL('kuzu-opfs.js', self.location.href).href;

async function init() {
    initPromise = createKuzu({ mainScriptUrlOrBlob: kuzuScriptUrl });
    kuzu = await initPromise;
    // ...
}
```

## Pitfalls We Hit (and solved)

| Problem | Cause | Fix |
|---------|-------|-----|
| `createKuzu is not a function` | Emscripten MODULARIZE outputs UMD, not ESM | Use `<script src>` or `importScripts`, not `import` |
| `SuspendError: trying to suspend without WebAssembly.promising` | JSPI requires Chrome flags | Switched from JSPI to pthreads |
| `--shared-memory disallowed` | Link-time `-pthread` not enough, all `.o` files need atomics | Recompile all libs with `-pthread` (`_mt` suffix) |
| Data not persisted | WasmFS defaults to MEMFS, not OPFS | Added `wasmfs_before_preload()` hook to mount OPFS at `/opfs` |
| `Cannot safely create OPFS backend on main browser thread` | OPFS backend init must be off main thread | Move WASM module into Web Worker |
| `Cannot read properties of null (reading 'KuzuDatabase')` | pthread workers loading wrong script | Pass `mainScriptUrlOrBlob` to `createKuzu()` |

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
# Open http://localhost:9876/          (in-memory)
# Open http://localhost:9876/opfs.html (OPFS persistent - the one that works!)
```

### OPFS Persistence Test Flow
1. Open http://localhost:9876/opfs.html
2. Click "Create Persistent DB"
3. Click "Insert Test Data"
4. Hard refresh (Ctrl+Shift+R)
5. Click "Verify Persistence"
6. Data survives!

## Known Limitations

- **Single-threaded queries** — all queries run sequentially (acceptable for conversation memory)
- **No extensions** — Kuzu extensions are not loaded in WASM builds
- **Browser support** — Chrome 102+, Edge, Firefox 111+ for OPFS (we target Chromium)
- **SharedArrayBuffer required** — COOP/COEP headers must be set on the server
- **Web Worker required** — OPFS build must run in a worker, not on main thread

## What's Next

1. **Performance benchmarking** — measure query times for realistic graph sizes
2. **Integration with Skykit** — wire up as optional client-side knowledge graph
3. **Graphiti integration** — implement the temporal episode/entity/relationship model
   on top of Kuzu WASM
4. **Bundle size optimization** — investigate `-Oz`, dead code elimination, wasm-opt
