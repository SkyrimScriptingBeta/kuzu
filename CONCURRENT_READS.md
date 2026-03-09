# 🔓 Concurrent Read-Only Access

Kuzu 0.11.3 (upstream) does not allow any process to open a database while another process has it open — even for reading. This fork fixes that.

## What Changed

A read-only `Database` instance can now open a `.kuzu` database while a read-write instance holds it open. This works both within the same process and across separate processes.

**The problem:** Upstream Kuzu acquires an exclusive byte-range lock directly on the data file via `LockFileEx` (Windows) / `fcntl` (POSIX). On Windows, these are mandatory locks — they block `ReadFile` calls from other handles, not just other lock attempts. On POSIX they're advisory, but still block other `fcntl` lock acquisitions. Either way, a second `Database` instance (even with `readOnly = true`) cannot open the same path.

**The fix:** Writer exclusivity is now enforced via a separate `.lock` file (`<dbpath>.lock`), following the same pattern SQLite uses. Read-only mode skips locking entirely. The data file itself is never locked, so readers can always open and read it.

```
Before:  Writer locks data file exclusively → readers blocked 💀
After:   Writer locks .lock file exclusively → data file stays open for everyone ✅
```

Four source files changed. Thirteen lines of diff.

## For C++ Consumers

The API is unchanged. Existing code works as-is. The only observable difference:

- **`SystemConfig{.readOnly = true}`** now actually works while another instance has the database open for writing. Previously this would throw `IO exception: Could not set lock on file`.
- A new `.lock` file appears next to the database when a read-write instance is running. This is an implementation detail — don't delete it while the database is open.
- **Two read-write instances on the same path are still blocked**, as they should be.

```cpp
// Writer (process A)
auto writerDb = std::make_unique<Database>("my.kuzu");
auto writerConn = std::make_unique<Connection>(writerDb.get());
writerConn->query("CREATE NODE TABLE ...");
writerConn->query("CHECKPOINT;");
// writerDb stays open...

// Reader (process B, or same process)
SystemConfig cfg;
cfg.readOnly = true;
auto readerDb = std::make_unique<Database>("my.kuzu", cfg);  // ✅ works now
auto readerConn = std::make_unique<Connection>(readerDb.get());
auto result = readerConn->query("MATCH (n) RETURN n;");       // ✅ reads fine
```

## Caveats

This gives you **snapshot reads**, not live reads. The reader sees data as of the last checkpoint. If the writer inserts rows but hasn't checkpointed, the reader won't see them. Call `CHECKPOINT;` on the writer to flush.

This is not WAL-mode MVCC like SQLite offers. There is no isolation between in-flight write transactions and concurrent readers. If the writer is mid-checkpoint while a reader is scanning, the reader may see inconsistent state. For safety, checkpoint before opening readers.

## Files Changed

| File | Change |
|------|--------|
| `src/include/common/constants.h` | Added `LOCK_FILE_SUFFIX` |
| `src/include/storage/storage_utils.h` | Added `getLockFilePath()` |
| `src/main/database.cpp` | Writer acquires exclusive lock on `.lock` file instead of data file |
| `src/storage/storage_manager.cpp` | Removed `O_LOCKED_PERSISTENT_FILE` from data file handle |
| `src/common/file_system/local_file_system.cpp` | Registered `.lock` file in database file set |
