set_project("kuzu")
set_version("0.11.2.2")
set_languages("c99", "cxx20")
add_rules("mode.debug", "mode.release")

-- ============================================================================
-- Third-party static libraries
-- ============================================================================

target("antlr4_runtime")
    set_kind("static")
    set_group("third_party")
    add_files("third_party/antlr4_runtime/src/**.cpp")
    add_includedirs("third_party/antlr4_runtime/src", {public = true})
    add_defines("ANTLR4CPP_STATIC", {public = true})
    if is_plat("windows") then
        add_cxxflags("/w")
    else
        add_cxxflags("-w")
    end
target_end()

target("antlr4_cypher")
    set_kind("static")
    set_group("third_party")
    add_files("third_party/antlr4_cypher/cypher_lexer.cpp")
    add_files("third_party/antlr4_cypher/cypher_parser.cpp")
    add_includedirs("third_party/antlr4_cypher/include", {public = true})
    add_includedirs("third_party/antlr4_runtime/src")
    add_deps("antlr4_runtime")
    if is_plat("windows") then
        add_cxxflags("/w")
    else
        add_cxxflags("-w")
    end
target_end()

target("brotlicommon")
    set_kind("static")
    set_group("third_party")
    add_files("third_party/brotli/c/common/*.c")
    add_includedirs("third_party/brotli/c/include", {public = true})
    if is_plat("windows") then add_cflags("/w") else add_cflags("-w") end
target_end()

target("brotlidec")
    set_kind("static")
    set_group("third_party")
    add_files("third_party/brotli/c/dec/*.c")
    add_includedirs("third_party/brotli/c/include")
    add_deps("brotlicommon")
    if is_plat("windows") then add_cflags("/w") else add_cflags("-w") end
target_end()

target("fastpfor")
    set_kind("static")
    set_group("third_party")
    add_files("third_party/fastpfor/fastpfor/bitpacking.cpp")
    add_includedirs("third_party/fastpfor", {public = true})
    if is_plat("windows") then add_cxxflags("/w") else add_cxxflags("-w") end
target_end()

target("lz4")
    set_kind("static")
    set_group("third_party")
    add_files("third_party/lz4/lz4.cpp")
    add_includedirs("third_party/lz4", {public = true})
    if is_plat("windows") then add_cxxflags("/w") else add_cxxflags("-w") end
target_end()

target("mbedtls")
    set_kind("static")
    set_group("third_party")
    add_files("third_party/mbedtls/library/*.cpp")
    add_includedirs("third_party/mbedtls/include", {public = true})
    if is_plat("windows") then add_cxxflags("/w") else add_cxxflags("-w") end
target_end()

target("miniz")
    set_kind("static")
    set_group("third_party")
    add_files("third_party/miniz/miniz.cpp")
    add_includedirs("third_party/miniz", {public = true})
    if is_plat("windows") then add_cxxflags("/w") else add_cxxflags("-w") end
target_end()

target("parquet")
    set_kind("static")
    set_group("third_party")
    add_files("third_party/parquet/parquet_constants.cpp")
    add_files("third_party/parquet/parquet_types.cpp")
    add_includedirs("third_party/parquet", {public = true})
    add_includedirs("third_party/thrift")
    add_defines("HAVE_STDINT_H")
    if is_plat("windows") then add_cxxflags("/w") else add_cxxflags("-w") end
target_end()

target("re2")
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
target_end()

target("roaring_bitmap")
    set_kind("static")
    set_group("third_party")
    set_languages("clatest")
    add_files("third_party/roaring_bitmap/roaring.c")
    add_includedirs("third_party/roaring_bitmap", {public = true})
    if is_plat("windows") then add_cflags("/w") else add_cflags("-w") end
target_end()

target("simsimd")
    set_kind("static")
    set_group("third_party")
    add_files("third_party/simsimd/lib.c")
    add_includedirs("third_party/simsimd/include", {public = true})
    if is_plat("windows") then add_cflags("/w") else add_cflags("-w") end
target_end()

target("snappy")
    set_kind("static")
    set_group("third_party")
    add_files("third_party/snappy/snappy.cc")
    add_files("third_party/snappy/snappy-sinksource.cc")
    add_includedirs("third_party/snappy", {public = true})
    if is_plat("windows") then add_cxxflags("/w") else add_cxxflags("-w") end
target_end()

target("thrift")
    set_kind("static")
    set_group("third_party")
    add_files("third_party/thrift/protocol/TProtocol.cpp")
    add_files("third_party/thrift/transport/TTransportException.cpp")
    add_files("third_party/thrift/transport/TBufferTransports.cpp")
    add_includedirs("third_party/thrift", {public = true})
    if is_plat("windows") then add_cxxflags("/w") else add_cxxflags("-w") end
target_end()

target("utf8proc")
    set_kind("static")
    set_group("third_party")
    add_files("third_party/utf8proc/utf8proc.cpp")
    add_files("third_party/utf8proc/utf8proc_wrapper.cpp")
    add_includedirs("third_party/utf8proc/include", {public = true})
    if is_plat("windows") then add_cxxflags("/w") else add_cxxflags("-w") end
target_end()

target("yyjson")
    set_kind("static")
    set_group("third_party")
    add_files("third_party/yyjson/src/yyjson.c")
    add_includedirs("third_party/yyjson", {public = true})
    if is_plat("windows") then add_cflags("/w") else add_cflags("-w") end
target_end()

target("zstd")
    set_kind("static")
    set_group("third_party")
    add_files("third_party/zstd/common/*.cpp")
    add_files("third_party/zstd/compress/*.cpp")
    add_files("third_party/zstd/decompress/*.cpp")
    add_includedirs("third_party/zstd/include", {public = true})
    add_defines("ZSTDLIB_VISIBILITY=", "ZSTDERRORLIB_VISIBILITY=")
    if is_plat("windows") then add_cxxflags("/w") else add_cxxflags("-w") end
target_end()

-- ============================================================================
-- Kuzu static library
-- ============================================================================

target("kuzu")
    set_kind("static")

    -- All source files from src/
    add_files("src/**.cpp")

    -- Main include directories
    add_includedirs("src/include", {public = true})
    add_includedirs("src/include/c_api", {public = true})

    -- Third-party include directories (mirrors CMake global include_directories)
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

    -- Compile definitions
    add_defines("KUZU_EXPORTS", "ANTLR4CPP_STATIC")
    add_defines('KUZU_ROOT_DIRECTORY="."')
    add_defines('KUZU_CMAKE_VERSION="0.11.2.2"')
    add_defines('KUZU_EXTENSION_VERSION="0.11.1"')

    -- Architecture defines
    if is_arch("x86_64", "x64") then
        add_defines("__64BIT__")
    elseif is_arch("x86", "i386") then
        add_defines("__32BIT__")
    end

    -- Windows / MSVC specifics
    if is_plat("windows") then
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

    -- Third-party library dependencies
    add_deps(
        "antlr4_runtime", "antlr4_cypher",
        "brotlicommon", "brotlidec",
        "fastpfor", "lz4", "mbedtls", "miniz",
        "parquet", "re2", "roaring_bitmap", "simsimd",
        "snappy", "thrift", "utf8proc", "yyjson", "zstd"
    )

    -- Generate required build files (system_config.h and extension loader stubs)
    on_load(function(target)
        local gendir = path.join(os.projectdir(), "build", "xmake_generated")

        -- system_config.h
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

        -- generated_extension_loader.h (empty stub - no static extensions)
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

        -- generated_extension_loader.cpp (empty stub - no static extensions)
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

        -- Add generated files to the target
        target:add("files", path.join(gendir, "codegen", "generated_extension_loader.cpp"))
        target:add("includedirs", gendir)
        target:add("includedirs", path.join(gendir, "codegen", "include"))
    end)
target_end()
