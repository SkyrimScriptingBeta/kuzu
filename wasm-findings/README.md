# Kuzu WASM Spike Findings

Findings from the Kuzu WASM + OPFS spike (2026-03-04).

## Quick Links

- [01 - Initial Compilation](./01-initial-compilation.md) — First WASM build, zero source changes
- [02 - Full Spike Results](./02-full-spike-results.md) — All build targets, test results, architecture

## Status: Working

Kuzu compiles to WASM and executes Cypher queries correctly. Three build targets exist:

| Target | Size | Storage | Use Case |
|--------|------|---------|----------|
| `kuzu_wasm` | 10 MB | In-memory | Browser (volatile) |
| `kuzu_wasm_node` | 10 MB | Local FS | Node/Bun testing |
| `kuzu_wasm_opfs` | 11 MB | OPFS (persistent) | Browser (survives reloads) |

## How to Build & Test

```bash
# Build (Windows, from repo root)
cmd.exe /c "emsdk_env.bat && xmake f -p wasm -c -y && xmake"

# Test with bun
cd wasm/test-node && bun run test.mjs

# Test in browser
cd wasm/test-browser && bun run serve.ts
# http://localhost:9876/           -> in-memory test
# http://localhost:9876/opfs.html  -> OPFS persistence test
```
