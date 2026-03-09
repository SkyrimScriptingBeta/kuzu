// 🧪 kuzu-experiment-concurrent
// Proves that a read-only Database can open alongside a read/write Database.
//
// Tests:
// 1. Same-process: writer (rw) + reader (readonly) on the same path
// 2. Cross-process: parent holds writer open, child opens readonly
// 3. Two writers on the same path — should STILL fail (safety check)

#include <iostream>
#include <string>
#include <filesystem>
#include <cstdlib>

#include "main/kuzu.h"

using namespace kuzu::main;
namespace fs = std::filesystem;

static void separator() {
    std::cout << "\n" << std::string(70, '=') << "\n" << std::endl;
}

static void populate(Connection* conn) {
    conn->query("CREATE NODE TABLE Person(name STRING, age INT64, PRIMARY KEY(name));");
    conn->query("CREATE (:Person {name: 'Alice', age: 25});");
    conn->query("CREATE (:Person {name: 'Bob', age: 30});");
    conn->query("CREATE (:Person {name: 'Charlie', age: 35});");
    conn->query("CHECKPOINT;");
}

static bool query_and_print(Connection* conn, const std::string& label) {
    auto result = conn->query("MATCH (p:Person) RETURN p.name, p.age;");
    if (result->isSuccess()) {
        std::cout << "✅ " << label << " query succeeded:" << std::endl;
        std::cout << result->toString() << std::endl;
        return true;
    }
    std::cout << "❌ " << label << " query failed: " << result->getErrorMessage() << std::endl;
    return false;
}

// =========================================================================
// Test 1: Same-process — writer (rw) + reader (readonly)
// =========================================================================
static bool test_same_process(const std::string& dbPath) {
    std::cout << "🧪 TEST 1: Same-process writer + read-only reader" << std::endl;
    separator();

    if (fs::exists(dbPath)) fs::remove_all(dbPath);

    // Writer
    std::cout << "✏️  Opening writer (read/write)..." << std::endl;
    SystemConfig wCfg;
    wCfg.forceCheckpointOnClose = true;
    auto writerDb = std::make_unique<Database>(dbPath, wCfg);
    auto writerConn = std::make_unique<Connection>(writerDb.get());
    populate(writerConn.get());
    std::cout << "✅ Writer ready, data checkpointed." << std::endl;
    query_and_print(writerConn.get(), "Writer");

    // Reader
    std::cout << "🔍 Opening reader (read-only) on the SAME path..." << std::endl;
    try {
        SystemConfig rCfg;
        rCfg.readOnly = true;
        auto readerDb = std::make_unique<Database>(dbPath, rCfg);
        auto readerConn = std::make_unique<Connection>(readerDb.get());

        if (query_and_print(readerConn.get(), "Reader")) {
            std::cout << "🎉 TEST 1 PASSED" << std::endl;
            return true;
        }
    } catch (const std::exception& e) {
        std::cout << "❌ Failed to open read-only instance: " << e.what() << std::endl;
    }
    std::cout << "💀 TEST 1 FAILED" << std::endl;
    return false;
}

// =========================================================================
// Test 2: Cross-process — parent writer, child reader
// =========================================================================
static bool child_reader(const std::string& dbPath) {
    std::cout << "🔍 CHILD: Opening database read-only..." << std::endl;
    try {
        SystemConfig cfg;
        cfg.readOnly = true;
        auto db = std::make_unique<Database>(dbPath, cfg);
        auto conn = std::make_unique<Connection>(db.get());
        if (query_and_print(conn.get(), "CHILD")) {
            return true;
        }
    } catch (const std::exception& e) {
        std::cout << "❌ CHILD: " << e.what() << std::endl;
    }
    return false;
}

static bool test_cross_process(const std::string& dbPath, const std::string& exe) {
    std::cout << "🧪 TEST 2: Cross-process writer + read-only reader" << std::endl;
    separator();

    if (fs::exists(dbPath)) fs::remove_all(dbPath);

    std::cout << "✏️  PARENT: Opening writer (read/write)..." << std::endl;
    SystemConfig wCfg;
    wCfg.forceCheckpointOnClose = true;
    auto writerDb = std::make_unique<Database>(dbPath, wCfg);
    auto writerConn = std::make_unique<Connection>(writerDb.get());
    populate(writerConn.get());
    std::cout << "✅ PARENT: Writer ready, DB held open." << std::endl;

    // Use absolute path for the db so the child can find it.
    // Windows cmd.exe needs the entire command wrapped in outer quotes when the exe path has spaces.
    auto absDbPath = fs::absolute(dbPath).string();
#if defined(_WIN32)
    std::string cmd = "\"\"" + exe + "\" --child-reader \"" + absDbPath + "\"\"";
#else
    std::string cmd = "\"" + exe + "\" --child-reader \"" + absDbPath + "\"";
#endif
    std::cout << "🚀 Launching child: " << cmd << std::endl;

    int rc = std::system(cmd.c_str());

    if (rc == 0) {
        std::cout << "🎉 TEST 2 PASSED" << std::endl;
        return true;
    }
    std::cout << "💀 TEST 2 FAILED (child exit code " << rc << ")" << std::endl;
    return false;
}

// =========================================================================
// Test 3: Two writers — MUST still fail (safety)
// =========================================================================
static bool test_two_writers(const std::string& dbPath) {
    std::cout << "🧪 TEST 3: Two writers on the same path (should FAIL)" << std::endl;
    separator();

    if (fs::exists(dbPath)) fs::remove_all(dbPath);

    auto db1 = std::make_unique<Database>(dbPath);
    auto conn1 = std::make_unique<Connection>(db1.get());
    populate(conn1.get());
    std::cout << "✅ First writer open." << std::endl;

    std::cout << "🔍 Opening second writer..." << std::endl;
    try {
        auto db2 = std::make_unique<Database>(dbPath);
        std::cout << "❌ Second writer opened — lock didn't prevent it!" << std::endl;
        std::cout << "💀 TEST 3 FAILED (expected failure, got success)" << std::endl;
        return false;
    } catch (const std::exception& e) {
        std::cout << "✅ Second writer correctly blocked: " << e.what() << std::endl;
        std::cout << "🎉 TEST 3 PASSED (two writers blocked as expected)" << std::endl;
        return true;
    }
}

// =========================================================================
int main(int argc, char* argv[]) {
    // Child reader mode (spawned by test 2)
    if (argc >= 3 && std::string(argv[1]) == "--child-reader") {
        return child_reader(argv[2]) ? 0 : 1;
    }

    auto absExe = fs::absolute(argv[0]).string();
    std::string dbPath = "experiment_concurrent.kuzu";

    std::cout << "🔬 KUZU CONCURRENT ACCESS EXPERIMENT" << std::endl;
    std::cout << "   Testing read-only access while writer holds the database open" << std::endl;
    separator();

    bool t1 = test_same_process(dbPath);
    separator();
    bool t2 = test_cross_process(dbPath, absExe);
    separator();
    bool t3 = test_two_writers(dbPath);
    separator();

    std::cout << "📊 RESULTS SUMMARY" << std::endl;
    std::cout << "   Test 1 (same-process, rw + readonly):  " << (t1 ? "✅ PASS" : "💀 FAIL") << std::endl;
    std::cout << "   Test 2 (cross-process, rw + readonly): " << (t2 ? "✅ PASS" : "💀 FAIL") << std::endl;
    std::cout << "   Test 3 (two writers blocked):          " << (t3 ? "✅ PASS" : "💀 FAIL") << std::endl;

    if (fs::exists(dbPath)) fs::remove_all(dbPath);

    bool allPassed = t1 && t2 && t3;
    std::cout << "\n" << (allPassed ? "🎉 ALL TESTS PASSED" : "💀 SOME TESTS FAILED") << std::endl;
    return allPassed ? 0 : 1;
}
