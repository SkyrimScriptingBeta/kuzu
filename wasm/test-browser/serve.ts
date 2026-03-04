// Simple Bun server with Cross-Origin-Isolation headers
// Run with: bun run serve.ts

import { readFileSync, existsSync } from "fs";
import { join, extname } from "path";

const PORT = 9876;
const WASM_DIR = join(import.meta.dir, "../../build/wasm/wasm32/release");
const STATIC_DIR = import.meta.dir;

const MIME_TYPES: Record<string, string> = {
  ".html": "text/html",
  ".js": "application/javascript",
  ".mjs": "application/javascript",
  ".wasm": "application/wasm",
  ".css": "text/css",
  ".json": "application/json",
};

// Cross-Origin-Isolation headers (required for SharedArrayBuffer, good practice for OPFS)
const HEADERS: Record<string, string> = {
  "Cross-Origin-Opener-Policy": "same-origin",
  "Cross-Origin-Embedder-Policy": "require-corp",
};

// WASM build artifacts served from build directory
const WASM_FILES = new Set([
  "kuzu.js", "kuzu.wasm",
  "kuzu-opfs.js", "kuzu-opfs.wasm",
  "kuzu-node.js", "kuzu-node.wasm",
]);

Bun.serve({
  port: PORT,
  fetch(req) {
    const url = new URL(req.url);
    const pathname = url.pathname === "/" ? "/index.html" : url.pathname;
    const filename = pathname.slice(1);

    let filePath: string;
    if (WASM_FILES.has(filename)) {
      filePath = join(WASM_DIR, filename);
    } else {
      filePath = join(STATIC_DIR, filename);
    }

    if (!existsSync(filePath)) {
      return new Response("Not Found", { status: 404, headers: HEADERS });
    }

    const ext = extname(filePath);
    const contentType = MIME_TYPES[ext] || "application/octet-stream";
    const body = readFileSync(filePath);

    return new Response(body, {
      headers: {
        ...HEADERS,
        "Content-Type": contentType,
      },
    });
  },
});

console.log(`
  Kuzu WASM Test Server
  =====================
  http://localhost:${PORT}/           - In-memory WASM test
  http://localhost:${PORT}/opfs.html  - OPFS persistence test

  Cross-Origin-Isolation: enabled
  WASM dir: ${WASM_DIR}
`);
