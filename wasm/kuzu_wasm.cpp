#include <emscripten/bind.h>
#include <memory>
#include <string>

#include "main/kuzu.h"

using namespace emscripten;
using namespace kuzu::main;

// Thin wrapper around Kuzu's C++ API for WASM/embind exposure.
// Avoids raw pointers and complex types that embind can't handle directly.

class KuzuWasm {
public:
    static std::string version() { return std::string(Version::getVersion()); }

    static uint64_t storageVersion() { return Version::getStorageVersion(); }
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
        .class_function("storageVersion", &KuzuWasm::storageVersion);

    class_<KuzuDatabase>("KuzuDatabase")
        .constructor<const std::string&, uint64_t>();

    class_<KuzuConnection>("KuzuConnection")
        .constructor<KuzuDatabase&>()
        .function("query", &KuzuConnection::query)
        .function("queryResult", &KuzuConnection::queryResult);
}
