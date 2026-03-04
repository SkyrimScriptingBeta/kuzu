// Test Kuzu WASM with Node/Bun
// Run with: bun run test.mjs

import createKuzu from '../../build/wasm/wasm32/release/kuzu-node.js';

async function main() {
    console.log("Initializing Kuzu WASM...");
    const kuzu = await createKuzu();

    console.log("Kuzu version:", kuzu.KuzuWasm.version());
    console.log("Storage version:", kuzu.KuzuWasm.storageVersion());

    // Create an in-memory database (empty string = in-memory)
    console.log("\nCreating in-memory database...");
    const db = new kuzu.KuzuDatabase("", 256 * 1024 * 1024); // 256MB buffer pool

    console.log("Creating connection...");
    const conn = new kuzu.KuzuConnection(db);

    // Create a simple schema
    console.log("\n--- Creating Schema ---");
    console.log(conn.query("CREATE NODE TABLE Person(name STRING, age INT64, PRIMARY KEY (name))"));
    console.log(conn.query("CREATE REL TABLE Knows(FROM Person TO Person, since INT64)"));

    // Insert data
    console.log("\n--- Inserting Data ---");
    console.log(conn.query("CREATE (p:Person {name: 'Alice', age: 30})"));
    console.log(conn.query("CREATE (p:Person {name: 'Bob', age: 25})"));
    console.log(conn.query("CREATE (p:Person {name: 'Charlie', age: 35})"));
    console.log(conn.query("MATCH (a:Person {name: 'Alice'}), (b:Person {name: 'Bob'}) CREATE (a)-[:Knows {since: 2020}]->(b)"));
    console.log(conn.query("MATCH (a:Person {name: 'Bob'}), (b:Person {name: 'Charlie'}) CREATE (a)-[:Knows {since: 2021}]->(b)"));

    // Query data
    console.log("\n--- Querying Data ---");
    console.log("All people:");
    console.log(conn.query("MATCH (p:Person) RETURN p.name, p.age ORDER BY p.name"));

    console.log("Relationships:");
    console.log(conn.query("MATCH (a:Person)-[k:Knows]->(b:Person) RETURN a.name, b.name, k.since"));

    // Graph traversal
    console.log("2-hop path from Alice:");
    console.log(conn.query("MATCH (a:Person {name: 'Alice'})-[:Knows*1..2]->(b:Person) RETURN b.name"));

    // Use queryResult for structured output
    console.log("\n--- Structured Result ---");
    const result = conn.queryResult("MATCH (p:Person) RETURN p.name AS name, p.age AS age ORDER BY p.age");
    console.log("Success:", result.success);
    console.log("Columns:", JSON.stringify(result.columnNames));
    console.log("Num tuples:", result.numTuples);
    console.log("Data:\n" + result.data);

    // Clean up
    conn.delete();
    db.delete();

    console.log("\nDone! Kuzu WASM works!");
}

main().catch(console.error);
