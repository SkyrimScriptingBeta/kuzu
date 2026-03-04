// Kuzu WASM Worker
// Runs the WASM module off the main thread so OPFS backend can safely initialize.
// Communicates with the main page via postMessage.

importScripts('kuzu-opfs.js');

let kuzu = null;
let db = null;
let conn = null;

// Resolve the absolute URL for kuzu-opfs.js so Emscripten spawns pthread
// workers using the correct script (not kuzu-worker.js).
const kuzuScriptUrl = new URL('kuzu-opfs.js', self.location.href).href;

// Serialization: all RPC calls wait for init to complete first.
let initPromise = null;

async function init() {
    initPromise = createKuzu({ mainScriptUrlOrBlob: kuzuScriptUrl });
    kuzu = await initPromise;
    return {
        version: kuzu.KuzuWasm.version(),
        storageVersion: Number(kuzu.KuzuWasm.storageVersion()),
        hasOPFS: kuzu.KuzuWasm.hasOPFS(),
    };
}

async function ensureReady() {
    if (initPromise) await initPromise;
    if (!kuzu) throw new Error('WASM not initialized — call init first');
}

async function createDatabase(path, bufferPoolSize) {
    await ensureReady();
    if (conn) { conn.delete(); conn = null; }
    if (db) { db.delete(); db = null; }
    db = new kuzu.KuzuDatabase(path, bufferPoolSize);
    conn = new kuzu.KuzuConnection(db);
    return { success: true };
}

async function query(cypher) {
    await ensureReady();
    if (!conn) return { success: false, error: 'No connection' };
    return conn.queryResult(cypher);
}

async function queryString(cypher) {
    await ensureReady();
    if (!conn) return 'ERROR: No connection';
    return conn.query(cypher);
}

async function closeDatabase() {
    await ensureReady();
    if (conn) { conn.delete(); conn = null; }
    if (db) { db.delete(); db = null; }
    return { success: true };
}

// Message handler
self.onmessage = async function(e) {
    const { id, action, args } = e.data;
    try {
        let result;
        switch (action) {
            case 'init':
                result = await init();
                break;
            case 'createDatabase':
                result = await createDatabase(args.path, args.bufferPoolSize);
                break;
            case 'query':
                result = await query(args.cypher);
                break;
            case 'queryString':
                result = await queryString(args.cypher);
                break;
            case 'close':
                result = await closeDatabase();
                break;
            default:
                result = { error: `Unknown action: ${action}` };
        }
        self.postMessage({ id, result });
    } catch (err) {
        self.postMessage({ id, error: err.message || String(err) });
    }
};
