set_project("kuzu")
set_version("0.11.2.2")
set_languages("c99", "cxx20")
add_rules("mode.debug", "mode.release")

-- ============================================================================
-- Helper: define all third-party + kuzu targets with an optional suffix.
-- When suffix="_mt", all targets get -pthread for WASM shared-memory support.
-- ============================================================================

local function define_kuzu_targets(suffix)
    suffix = suffix or ""
    local is_mt = (suffix == "_mt")

    -- ========================================================================
    -- Third-party static libraries
    -- ========================================================================

    target("antlr4_runtime" .. suffix)
        set_kind("static")
        set_group("third_party")
        add_files("third_party/antlr4_runtime/src/**.cpp")
        add_includedirs("third_party/antlr4_runtime/src", {public = true})
        add_defines("ANTLR4CPP_STATIC", {public = true})
        if is_plat("windows") then add_cxxflags("/w")
        else add_cxxflags("-w") end
        if is_mt and is_plat("wasm") then add_cxxflags("-pthread", {force = true}) end
    target_end()

    target("antlr4_cypher" .. suffix)
        set_kind("static")
        set_group("third_party")
        add_files("third_party/antlr4_cypher/cypher_lexer.cpp")
        add_files("third_party/antlr4_cypher/cypher_parser.cpp")
        add_includedirs("third_party/antlr4_cypher/include", {public = true})
        add_includedirs("third_party/antlr4_runtime/src")
        add_deps("antlr4_runtime" .. suffix)
        if is_plat("windows") then add_cxxflags("/w")
        else add_cxxflags("-w") end
        if is_mt and is_plat("wasm") then add_cxxflags("-pthread", {force = true}) end
    target_end()

    target("brotlicommon" .. suffix)
        set_kind("static")
        set_group("third_party")
        add_files("third_party/brotli/c/common/*.c")
        add_includedirs("third_party/brotli/c/include", {public = true})
        if is_plat("windows") then add_cflags("/w") else add_cflags("-w") end
        if is_mt and is_plat("wasm") then add_cflags("-pthread", {force = true}) end
    target_end()

    target("brotlidec" .. suffix)
        set_kind("static")
        set_group("third_party")
        add_files("third_party/brotli/c/dec/*.c")
        add_includedirs("third_party/brotli/c/include")
        add_deps("brotlicommon" .. suffix)
        if is_plat("windows") then add_cflags("/w") else add_cflags("-w") end
        if is_mt and is_plat("wasm") then add_cflags("-pthread", {force = true}) end
    target_end()

    target("fastpfor" .. suffix)
        set_kind("static")
        set_group("third_party")
        add_files("third_party/fastpfor/fastpfor/bitpacking.cpp")
        add_includedirs("third_party/fastpfor", {public = true})
        if is_plat("windows") then add_cxxflags("/w") else add_cxxflags("-w") end
        if is_mt and is_plat("wasm") then add_cxxflags("-pthread", {force = true}) end
    target_end()

    target("lz4" .. suffix)
        set_kind("static")
        set_group("third_party")
        add_files("third_party/lz4/lz4.cpp")
        add_includedirs("third_party/lz4", {public = true})
        if is_plat("windows") then add_cxxflags("/w") else add_cxxflags("-w") end
        if is_mt and is_plat("wasm") then add_cxxflags("-pthread", {force = true}) end
    target_end()

    target("mbedtls" .. suffix)
        set_kind("static")
        set_group("third_party")
        add_files("third_party/mbedtls/library/*.cpp")
        add_includedirs("third_party/mbedtls/include", {public = true})
        if is_plat("windows") then add_cxxflags("/w") else add_cxxflags("-w") end
        if is_mt and is_plat("wasm") then add_cxxflags("-pthread", {force = true}) end
    target_end()

    target("miniz" .. suffix)
        set_kind("static")
        set_group("third_party")
        add_files("third_party/miniz/miniz.cpp")
        add_includedirs("third_party/miniz", {public = true})
        if is_plat("windows") then add_cxxflags("/w") else add_cxxflags("-w") end
        if is_mt and is_plat("wasm") then add_cxxflags("-pthread", {force = true}) end
    target_end()

    target("parquet" .. suffix)
        set_kind("static")
        set_group("third_party")
        add_files("third_party/parquet/parquet_constants.cpp")
        add_files("third_party/parquet/parquet_types.cpp")
        add_includedirs("third_party/parquet", {public = true})
        add_includedirs("third_party/thrift")
        add_defines("HAVE_STDINT_H")
        if is_plat("windows") then add_cxxflags("/w") else add_cxxflags("-w") end
        if is_mt and is_plat("wasm") then add_cxxflags("-pthread", {force = true}) end
    target_end()

    target("re2" .. suffix)
        set_kind("static")
        set_group("third_party")
        set_languages("cxx17")
        add_files("third_party/re2/*.cpp")
        add_includedirs("third_party/re2", {public = true})
        add_includedirs("third_party/re2/include", {public = true})
        if is_plat("windows") then
            add_defines("UNICODE", "_UNICODE", "STRICT", "NOMINMAX",
                        "_CRT_SECURE_NO_WARNINGS", "_SCL_SECURE_NO_WARNINGS")
            add_cxxflags("/w")
        else
            add_cxxflags("-w")
        end
        if is_mt and is_plat("wasm") then add_cxxflags("-pthread", {force = true}) end
    target_end()

    target("roaring_bitmap" .. suffix)
        set_kind("static")
        set_group("third_party")
        set_languages("clatest")
        add_files("third_party/roaring_bitmap/roaring.c")
        add_includedirs("third_party/roaring_bitmap", {public = true})
        if is_plat("windows") then add_cflags("/w") else add_cflags("-w") end
        if is_mt and is_plat("wasm") then add_cflags("-pthread", {force = true}) end
    target_end()

    target("simsimd" .. suffix)
        set_kind("static")
        set_group("third_party")
        add_files("third_party/simsimd/lib.c")
        add_includedirs("third_party/simsimd/include", {public = true})
        if is_plat("windows") then add_cflags("/w") else add_cflags("-w") end
        if is_mt and is_plat("wasm") then add_cflags("-pthread", {force = true}) end
    target_end()

    target("snappy" .. suffix)
        set_kind("static")
        set_group("third_party")
        add_files("third_party/snappy/snappy.cc")
        add_files("third_party/snappy/snappy-sinksource.cc")
        add_includedirs("third_party/snappy", {public = true})
        if is_plat("windows") then add_cxxflags("/w") else add_cxxflags("-w") end
        if is_mt and is_plat("wasm") then add_cxxflags("-pthread", {force = true}) end
    target_end()

    target("thrift" .. suffix)
        set_kind("static")
        set_group("third_party")
        add_files("third_party/thrift/protocol/TProtocol.cpp")
        add_files("third_party/thrift/transport/TTransportException.cpp")
        add_files("third_party/thrift/transport/TBufferTransports.cpp")
        add_includedirs("third_party/thrift", {public = true})
        if is_plat("windows") then add_cxxflags("/w") else add_cxxflags("-w") end
        if is_mt and is_plat("wasm") then add_cxxflags("-pthread", {force = true}) end
    target_end()

    target("utf8proc" .. suffix)
        set_kind("static")
        set_group("third_party")
        add_files("third_party/utf8proc/utf8proc.cpp")
        add_files("third_party/utf8proc/utf8proc_wrapper.cpp")
        add_includedirs("third_party/utf8proc/include", {public = true})
        if is_plat("windows") then add_cxxflags("/w") else add_cxxflags("-w") end
        if is_mt and is_plat("wasm") then add_cxxflags("-pthread", {force = true}) end
    target_end()

    target("yyjson" .. suffix)
        set_kind("static")
        set_group("third_party")
        add_files("third_party/yyjson/src/yyjson.c")
        add_includedirs("third_party/yyjson", {public = true})
        if is_plat("windows") then add_cflags("/w") else add_cflags("-w") end
        if is_mt and is_plat("wasm") then add_cflags("-pthread", {force = true}) end
    target_end()

    target("zstd" .. suffix)
        set_kind("static")
        set_group("third_party")
        add_files("third_party/zstd/common/*.cpp")
        add_files("third_party/zstd/compress/*.cpp")
        add_files("third_party/zstd/decompress/*.cpp")
        add_includedirs("third_party/zstd/include", {public = true})
        add_defines("ZSTDLIB_VISIBILITY=", "ZSTDERRORLIB_VISIBILITY=")
        if is_plat("windows") then add_cxxflags("/w") else add_cxxflags("-w") end
        if is_mt and is_plat("wasm") then add_cxxflags("-pthread", {force = true}) end
    target_end()

    -- ========================================================================
    -- Kuzu static library
    -- ========================================================================

    target("kuzu" .. suffix)
        set_kind("static")

        add_files("src/**.cpp")

        add_includedirs("src/include", {public = true})
        add_includedirs("src/include/c_api", {public = true})

        add_includedirs(
            "third_party/antlr4_cypher/include",
            "third_party/antlr4_runtime/src",
            "third_party/brotli/c/include",
            "third_party/fast_float/include",
            "third_party/mbedtls/include",
            "third_party/parquet",
            "third_party/snappy",
            "third_party/thrift",
            "third_party/miniz",
            "third_party/nlohmann_json",
            "third_party/pyparse",
            "third_party/re2/include",
            "third_party/re2",
            "third_party/alp/include",
            "third_party/utf8proc/include",
            "third_party/zstd/include",
            "third_party/httplib",
            "third_party/pcg",
            "third_party/lz4",
            "third_party/roaring_bitmap",
            "third_party/simsimd/include",
            "third_party/fastpfor",
            "third_party/yyjson",
            "third_party/glob"
        )

        add_defines("KUZU_EXPORTS", "ANTLR4CPP_STATIC")
        add_defines('KUZU_ROOT_DIRECTORY="."')
        add_defines('KUZU_CMAKE_VERSION="0.11.2.2"')
        add_defines('KUZU_EXTENSION_VERSION="0.11.1"')

        if is_arch("x86_64", "x64") then
            add_defines("__64BIT__")
        elseif is_arch("x86", "i386") then
            add_defines("__32BIT__")
        end

        if is_plat("wasm") then
            add_defines("__WASM__", "__SINGLE_THREADED__", "BM_MALLOC", {public = true})
            add_cxxflags("-fexceptions", "-w", {force = true})
            add_cflags("-fexceptions", "-w", {force = true})
            if is_mt then
                add_cxxflags("-pthread", {force = true})
                add_cflags("-pthread", {force = true})
            end
        elseif is_plat("windows") then
            add_defines(
                "_USE_MATH_DEFINES", "NOMINMAX", "SERD_STATIC",
                "_REGEX_MAX_STACK_COUNT=0", "_REGEX_MAX_COMPLEXITY_COUNT=0",
                "_DISABLE_CONSTEXPR_MUTEX_CONSTRUCTOR", "_AMD64_"
            )
            add_defines("KUZU_STATIC_DEFINE", {public = true})
            add_cxxflags("/utf-8", "/EHa", "/Zc:inline", "/wd4244", "/wd4267", {force = true})
            set_warnings("none")
        else
            add_cxxflags("-Wall", "-Wextra", "-Wno-unknown-pragmas")
            add_syslinks("dl", "pthread")
        end

        add_deps(
            "antlr4_runtime" .. suffix, "antlr4_cypher" .. suffix,
            "brotlicommon" .. suffix, "brotlidec" .. suffix,
            "fastpfor" .. suffix, "lz4" .. suffix, "mbedtls" .. suffix, "miniz" .. suffix,
            "parquet" .. suffix, "re2" .. suffix, "roaring_bitmap" .. suffix, "simsimd" .. suffix,
            "snappy" .. suffix, "thrift" .. suffix, "utf8proc" .. suffix, "yyjson" .. suffix, "zstd" .. suffix
        )

        on_load(function(target)
            local gendir = path.join(os.projectdir(), "build", "xmake_generated")

            os.mkdir(path.join(gendir, "common"))
            io.writefile(path.join(gendir, "common", "system_config.h"), [=[
/*
 * Generated by xmake - equivalent to CMake's configure_file(system_config.h.in)
 */
#pragma once

#include <algorithm>
#include <cstdint>

#include "common/enums/extend_direction.h"

#define BOTH_REL_STORAGE 0
#define FWD_REL_STORAGE 1
#define BWD_REL_STORAGE 2

namespace kuzu {
namespace common {

#define VECTOR_CAPACITY_LOG_2 11
#if VECTOR_CAPACITY_LOG_2 > 12
#error "Vector capacity log2 should be less than or equal to 12"
#endif
constexpr uint64_t DEFAULT_VECTOR_CAPACITY = static_cast<uint64_t>(1) << VECTOR_CAPACITY_LOG_2;

static constexpr uint64_t PAGE_SIZE_LOG2 = 12;
static constexpr uint64_t KUZU_PAGE_SIZE = static_cast<uint64_t>(1) << PAGE_SIZE_LOG2;
static constexpr uint64_t TEMP_PAGE_SIZE_LOG2 = 18;
static const uint64_t TEMP_PAGE_SIZE = static_cast<uint64_t>(1) << TEMP_PAGE_SIZE_LOG2;

#define DEFAULT_REL_STORAGE_DIRECTION BOTH_REL_STORAGE
#if DEFAULT_REL_STORAGE_DIRECTION == FWD_REL_STORAGE
static constexpr ExtendDirection DEFAULT_EXTEND_DIRECTION = ExtendDirection::FWD;
#elif DEFAULT_REL_STORAGE_DIRECTION == BWD_REL_STORAGE
static constexpr ExtendDirection DEFAULT_EXTEND_DIRECTION = ExtendDirection::BWD;
#else
static constexpr ExtendDirection DEFAULT_EXTEND_DIRECTION = ExtendDirection::BOTH;
#endif

struct StorageConfig {
    static constexpr uint64_t NODE_GROUP_SIZE_LOG2 = 17;
    static constexpr uint64_t NODE_GROUP_SIZE = static_cast<uint64_t>(1) << NODE_GROUP_SIZE_LOG2;
    static constexpr uint64_t CSR_LEAF_REGION_SIZE_LOG2 =
        std::min(static_cast<uint64_t>(10), NODE_GROUP_SIZE_LOG2 - 1);
    static constexpr uint64_t CSR_LEAF_REGION_SIZE = static_cast<uint64_t>(1)
                                                     << CSR_LEAF_REGION_SIZE_LOG2;
    static constexpr uint64_t CHUNKED_NODE_GROUP_CAPACITY =
        std::min(static_cast<uint64_t>(2048), NODE_GROUP_SIZE);

    static constexpr uint64_t MAX_SEGMENT_SIZE_LOG2 = 18;
    static constexpr uint64_t MAX_SEGMENT_SIZE = 1 << MAX_SEGMENT_SIZE_LOG2;
};

struct OrderByConfig {
    static constexpr uint64_t MIN_SIZE_TO_REDUCE = common::DEFAULT_VECTOR_CAPACITY * 5;
};

struct CopyConfig {
    static constexpr uint64_t PANDAS_PARTITION_COUNT = 50 * DEFAULT_VECTOR_CAPACITY;
};

} // namespace common
} // namespace kuzu

#undef BOTH_REL_STORAGE
#undef FWD_REL_STORAGE
#undef BWD_REL_STORAGE
]=])

            os.mkdir(path.join(gendir, "codegen", "include"))
            io.writefile(path.join(gendir, "codegen", "include", "generated_extension_loader.h"), [=[
#pragma once

#include "main/client_context.h"

namespace kuzu {
namespace extension {

void loadLinkedExtensions(main::ClientContext* context,
    std::vector<LoadedExtension>& loadedExtensions);

} // namespace extension
} // namespace kuzu
]=])

            io.writefile(path.join(gendir, "codegen", "generated_extension_loader.cpp"), [=[
#include "extension/loaded_extension.h"
#include "generated_extension_loader.h"

namespace kuzu {
namespace extension {

void loadLinkedExtensions(main::ClientContext* context,
    std::vector<LoadedExtension>& loadedExtensions) {
    (void)context;
    (void)loadedExtensions;
}

} // namespace extension
} // namespace kuzu
]=])

            target:add("files", path.join(gendir, "codegen", "generated_extension_loader.cpp"))
            target:add("includedirs", gendir)
            target:add("includedirs", path.join(gendir, "codegen", "include"))
        end)
    target_end()
end

-- ============================================================================
-- Build default targets (single-threaded for WASM, normal for other platforms)
-- ============================================================================

define_kuzu_targets("")

-- ============================================================================
-- Build pthreaded targets for WASM OPFS (all .o files need -pthread)
-- ============================================================================

if is_plat("wasm") then
    define_kuzu_targets("_mt")
end

-- ============================================================================
-- WASM binaries (only built when targeting wasm platform)
-- ============================================================================

if is_plat("wasm") then

-- Browser WASM binary (in-memory / MEMFS)
target("kuzu_wasm")
    set_kind("binary")
    set_basename("kuzu")
    set_extension(".js")

    add_files("wasm/kuzu_wasm.cpp")
    add_deps("kuzu")

    add_ldflags(
        "-lembind",
        "-sALLOW_MEMORY_GROWTH=1",
        "-sMAXIMUM_MEMORY=4GB",
        "-sMODULARIZE=1",
        "-sEXPORT_NAME=createKuzu",
        "-sEXPORTED_RUNTIME_METHODS=['FS','wasmMemory']",
        "-sSTACK_SIZE=4MB",
        "-sWASM_BIGINT",
        "-fexceptions",
        "-sDISABLE_EXCEPTION_CATCHING=0",
        "-sENVIRONMENT=web,worker",
        "-sASSERTIONS=1",
        {force = true}
    )
    add_cxxflags("-fexceptions", {force = true})
target_end()

-- Node-compatible WASM binary (for testing with bun/node)
target("kuzu_wasm_node")
    set_kind("binary")
    set_basename("kuzu-node")
    set_extension(".js")

    add_files("wasm/kuzu_wasm.cpp")
    add_deps("kuzu")

    add_ldflags(
        "-lembind",
        "-sALLOW_MEMORY_GROWTH=1",
        "-sMAXIMUM_MEMORY=4GB",
        "-sMODULARIZE=1",
        "-sEXPORT_NAME=createKuzu",
        "-sEXPORTED_RUNTIME_METHODS=['FS','wasmMemory']",
        "-sSTACK_SIZE=4MB",
        "-sWASM_BIGINT",
        "-fexceptions",
        "-sDISABLE_EXCEPTION_CATCHING=0",
        "-sENVIRONMENT=node",
        "-sNODERAWFS=1",
        "-sASSERTIONS=1",
        {force = true}
    )
    add_cxxflags("-fexceptions", {force = true})
target_end()

-- OPFS-backed WASM binary (persistent storage via WasmFS + pthreads)
-- Links against kuzu_mt (pthreaded build) so all .o files have atomics/bulk-memory.
-- __SINGLE_THREADED__ disables Kuzu's query parallelism only.
-- Emscripten pthreads here are for the WasmFS OPFS I/O layer.
target("kuzu_wasm_opfs")
    set_kind("binary")
    set_basename("kuzu-opfs")
    set_extension(".js")

    add_files("wasm/kuzu_wasm.cpp")
    add_deps("kuzu_mt")

    add_ldflags(
        "-lembind",
        "-sALLOW_MEMORY_GROWTH=1",
        "-sMAXIMUM_MEMORY=4GB",
        "-sMODULARIZE=1",
        "-sEXPORT_NAME=createKuzu",
        "-sEXPORTED_RUNTIME_METHODS=['FS','wasmMemory']",
        "-sSTACK_SIZE=4MB",
        "-sWASM_BIGINT",
        "-fexceptions",
        "-sDISABLE_EXCEPTION_CATCHING=0",
        "-sENVIRONMENT=web,worker",
        "-sASSERTIONS=1",
        -- WasmFS + pthreads for persistent OPFS storage
        "-sWASMFS",
        "-sFORCE_FILESYSTEM=1",
        "-pthread",
        "-sPTHREAD_POOL_SIZE=1",
        {force = true}
    )
    add_cxxflags("-fexceptions", "-pthread", {force = true})
target_end()

end
