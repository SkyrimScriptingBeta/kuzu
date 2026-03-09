// 🔍 kuzu-experiment-reader
// Tries to open a Kuzu database in READ-ONLY mode while another process has it open.
// This is the big question: does it work?

#include <iostream>
#include <string>
#include <filesystem>

#include "main/kuzu.h"

using namespace kuzu::main;
namespace fs = std::filesystem;

int main(int argc, char* argv[]) {
    std::string dbPath = "experiment.kuzu";
    if (argc > 1) dbPath = argv[1];

    if (!fs::exists(dbPath)) {
        std::cerr << "💀 Database not found at: " << dbPath << std::endl;
        std::cerr << "   Run kuzu-experiment-writer first!" << std::endl;
        return 1;
    }

    // =========================================================================
    // Attempt 1: Open in read-only mode
    // =========================================================================
    std::cout << "🔍 Attempt 1: Opening database in READ-ONLY mode at: " << dbPath << std::endl;
    try {
        SystemConfig config;
        config.readOnly = true;
        auto database = std::make_unique<Database>(dbPath, config);
        auto connection = std::make_unique<Connection>(database.get());

        std::cout << "✅ READ-ONLY database opened successfully!" << std::endl;

        auto result = connection->query("MATCH (p:Person) RETURN p.name, p.age;");
        if (result->isSuccess()) {
            std::cout << "✅ Query succeeded! Results:" << std::endl;
            std::cout << result->toString() << std::endl;
        } else {
            std::cout << "❌ Query failed: " << result->getErrorMessage() << std::endl;
        }

        std::cout << "🎉 CONCURRENT READ-ONLY ACCESS WORKS!" << std::endl;
        return 0;

    } catch (const std::exception& e) {
        std::cout << "❌ READ-ONLY open FAILED: " << e.what() << std::endl;
    }

    // =========================================================================
    // Attempt 2: Open in default (read/write) mode — just to see what happens
    // =========================================================================
    std::cout << std::endl;
    std::cout << "🔍 Attempt 2: Opening database in READ/WRITE mode at: " << dbPath << std::endl;
    try {
        auto database = std::make_unique<Database>(dbPath);
        auto connection = std::make_unique<Connection>(database.get());

        std::cout << "✅ READ/WRITE database opened successfully!" << std::endl;

        auto result = connection->query("MATCH (p:Person) RETURN p.name, p.age;");
        if (result->isSuccess()) {
            std::cout << "✅ Query succeeded! Results:" << std::endl;
            std::cout << result->toString() << std::endl;
        } else {
            std::cout << "❌ Query failed: " << result->getErrorMessage() << std::endl;
        }
        return 0;

    } catch (const std::exception& e) {
        std::cout << "❌ READ/WRITE open ALSO FAILED: " << e.what() << std::endl;
    }

    std::cout << std::endl;
    std::cout << "💀 Neither read-only nor read/write access works while another process has the DB open." << std::endl;
    std::cout << "   Time to go spelunking in the Kuzu source... 🕵️" << std::endl;
    return 1;
}
