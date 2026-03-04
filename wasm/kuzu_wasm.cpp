#include <emscripten/bind.h>
#include <memory>
#include <string>

#include "main/kuzu.h"

// OPFS backend support (only in the pthreaded/WasmFS build)
#if __has_include(<emscripten/wasmfs.h>)
#include <emscripten/wasmfs.h>
#define HAS_WASMFS 1
#else
#define HAS_WASMFS 0
#endif

using namespace emscripten;
using namespace kuzu::main;

// ============================================================================
// WasmFS OPFS mount hook
// ============================================================================
// wasmfs_before_preload() is called by WasmFS during startup, before file
// preloading. We use it to mount the OPFS backend at /opfs so that any
// database created at /opfs/... is transparently persisted to OPFS.
//
// This hook is only linked in the WasmFS build (kuzu_wasm_opfs target).
// The non-WasmFS builds (kuzu_wasm, kuzu_wasm_node) ignore this.
// ============================================================================

#if HAS_WASMFS
extern "C" {

void wasmfs_before_preload(void) {
    backend_t opfs = wasmfs_create_opfs_backend();
    wasmfs_create_directory("/opfs", 0777, opfs);
}

} // extern "C"
#endif

// ============================================================================
// Embind wrapper
// ============================================================================

class KuzuWasm {
public:
    static std::string version() { return std::string(Version::getVersion()); }

    static uint64_t storageVersion() { return Version::getStorageVersion(); }

    static bool hasOPFS() {
#if HAS_WASMFS
        return true;
#else
        return false;
#endif
    }
};

class KuzuDatabase {
public:
    KuzuDatabase(const std::string& path, uint64_t bufferPoolSize) {
        auto config = SystemConfig();
        config.bufferPoolSize = bufferPoolSize;
        config.maxNumThreads = 1;
        db_ = std::make_unique<Database>(path, config);
    }

    Database* get() { return db_.get(); }

private:
    std::unique_ptr<Database> db_;
};

class KuzuConnection {
public:
    KuzuConnection(KuzuDatabase& db) {
        conn_ = std::make_unique<Connection>(db.get());
    }

    std::string query(const std::string& cypher) {
        auto result = conn_->query(cypher);
        if (!result->isSuccess()) {
            return std::string("ERROR: ") + result->getErrorMessage();
        }
        return result->toString();
    }

    // Returns JSON-like result: success status + data
    val queryResult(const std::string& cypher) {
        auto result = conn_->query(cypher);
        val obj = val::object();
        obj.set("success", result->isSuccess());
        if (!result->isSuccess()) {
            obj.set("error", result->getErrorMessage());
            obj.set("data", val::null());
        } else {
            obj.set("error", val::null());
            obj.set("data", result->toString());
            obj.set("numTuples", (double)result->getNumTuples());
            obj.set("numColumns", (double)result->getNumColumns());

            // Column names
            val colNames = val::array();
            auto names = result->getColumnNames();
            for (size_t i = 0; i < names.size(); i++) {
                colNames.call<void>("push", names[i]);
            }
            obj.set("columnNames", colNames);
        }
        return obj;
    }

private:
    std::unique_ptr<Connection> conn_;
};

EMSCRIPTEN_BINDINGS(kuzu_wasm) {
    class_<KuzuWasm>("KuzuWasm")
        .class_function("version", &KuzuWasm::version)
        .class_function("storageVersion", &KuzuWasm::storageVersion)
        .class_function("hasOPFS", &KuzuWasm::hasOPFS);

    class_<KuzuDatabase>("KuzuDatabase")
        .constructor<const std::string&, uint64_t>();

    class_<KuzuConnection>("KuzuConnection")
        .constructor<KuzuDatabase&>()
        .function("query", &KuzuConnection::query)
        .function("queryResult", &KuzuConnection::queryResult);
}
