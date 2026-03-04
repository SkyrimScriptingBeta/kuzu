# Finding 01: Initial WASM Compilation

**Date:** 2026-03-04
**Status:** SUCCESS

## Summary

Kuzu compiles to WASM via Emscripten with zero source code modifications on the first attempt.

## Environment

- **Emscripten:** 5.0.1
- **xmake:** with `-p wasm` flag
- **Platform:** Windows 11, Git Bash
- **Kuzu version:** 0.11.2.2

## Build Command

```bash
# Activate Emscripten SDK
source /c/Code/mrowr/emscripten-core/emsdk/emsdk_env.sh
# Or on Windows: emsdk_env.bat

# Configure and build
xmake f -p wasm -c -y
xmake build kuzu
```

Note: On Windows, `emcc` is a `.bat` file. Git Bash can't run it directly, so use:
```bash
cmd.exe //c "emsdk_env.bat >NUL 2>&1 && xmake f -p wasm -c -y && xmake build kuzu"
```

## Results

- **Build time:** ~117 seconds
- **Static library size:** 35MB (`libkuzu.a`)
- **Errors:** 0
- **Warnings:** Suppressed (consistent with native builds)

## Critical WASM Defines Added to xmake.lua

The initial build compiled but was missing critical WASM-specific preprocessor defines.
These were added to `xmake.lua` under a new `is_plat("wasm")` block:

| Define | Purpose |
|--------|---------|
| `__WASM__` | Enables WASM-specific code paths throughout Kuzu |
| `__SINGLE_THREADED__` | Disables threading (pthreads not available in basic WASM) |
| `BM_MALLOC` | Uses malloc-based buffer manager instead of mmap/VirtualAlloc |

Without `BM_MALLOC`, Kuzu would try to use `mmap()` / `VirtualAlloc()` for its buffer pool,
which would crash in WASM. The malloc buffer manager allocates pages via `std::make_unique<uint8_t[]>()`.

Without `__SINGLE_THREADED__`, Kuzu would try to spawn worker threads via pthreads,
which requires SharedArrayBuffer + Cross-Origin-Isolation headers in the browser.
Single-threaded mode uses a simplified sequential task scheduler.

## Architecture Notes

Kuzu's codebase is already well-prepared for WASM:

1. **VirtualFileSystem abstraction** — file I/O goes through `VirtualFileSystem` which dispatches
   to `LocalFileSystem`. Emscripten intercepts POSIX calls (`fopen`/`fread`/`fwrite`) and redirects
   them to its own virtual FS backends (MEMFS, IDBFS, OPFS, etc.)

2. **Malloc buffer manager** — completely bypasses mmap, using heap allocation instead

3. **Single-threaded task scheduler** — sequential execution, no thread synchronization needed

4. **Exception handling** — `-fexceptions` flag enables C++ exceptions in WASM (required by Kuzu)

## Next Steps

- Rebuild with proper defines and verify compilation still succeeds
- Create a test binary that links against the WASM library
- Test with Emscripten's OPFS backend for persistent storage
