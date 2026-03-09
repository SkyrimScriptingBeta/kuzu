// 🔥 kuzu-experiment-writer
// Opens a Kuzu database for read/write, creates some data, then HOLDS IT OPEN.
// Run this first, then try running the reader in another terminal.

#include <iostream>
#include <string>
#include <thread>
#include <chrono>
#include <filesystem>

#include "main/kuzu.h"

using namespace kuzu::main;
namespace fs = std::filesystem;

int main(int argc, char* argv[]) {
    std::string dbPath = "experiment.kuzu";
    if (argc > 1) dbPath = argv[1];

    // Clean slate
    if (fs::exists(dbPath)) {
        std::cout << "🧹 Removing existing database at: " << dbPath << std::endl;
        fs::remove_all(dbPath);
    }

    std::cout << "✏️  Opening database (read/write) at: " << dbPath << std::endl;

    SystemConfig config;
    config.forceCheckpointOnClose = true;
    auto database = std::make_unique<Database>(dbPath, config);
    auto connection = std::make_unique<Connection>(database.get());

    std::cout << "📝 Creating schema and inserting data..." << std::endl;

    auto r1 = connection->query("CREATE NODE TABLE Person(name STRING, age INT64, PRIMARY KEY(name));");
    if (!r1->isSuccess()) {
        std::cerr << "💀 Schema creation failed: " << r1->getErrorMessage() << std::endl;
        return 1;
    }

    connection->query("CREATE (:Person {name: 'Alice', age: 25});");
    connection->query("CREATE (:Person {name: 'Bob', age: 30});");
    connection->query("CREATE (:Person {name: 'Charlie', age: 35});");

    auto result = connection->query("MATCH (p:Person) RETURN p.name, p.age;");
    std::cout << "✅ Data inserted. Current contents:" << std::endl;
    std::cout << result->toString() << std::endl;

    // Now checkpoint so data is flushed to disk (not just in WAL)
    std::cout << "💾 Running CHECKPOINT to flush data to disk..." << std::endl;
    auto cpResult = connection->query("CHECKPOINT;");
    if (cpResult->isSuccess()) {
        std::cout << "✅ Checkpoint complete." << std::endl;
    } else {
        std::cout << "⚠️  Checkpoint result: " << cpResult->getErrorMessage() << std::endl;
    }

    std::cout << std::endl;
    std::cout << "🔒 DATABASE IS NOW HELD OPEN (read/write mode)." << std::endl;
    std::cout << "👉 Go run kuzu-experiment-reader in another terminal!" << std::endl;
    std::cout << "   Press ENTER to close the database and exit..." << std::endl;

    // Keep the database open
    std::string line;
    std::getline(std::cin, line);

    std::cout << "👋 Closing database. Bye!" << std::endl;
    return 0;
}
