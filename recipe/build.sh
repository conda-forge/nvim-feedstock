#!/usr/bin/env bash

set -o xtrace -o nounset -o pipefail -o errexit

if [[ ${CONDA_BUILD_CROSS_COMPILATION:-0} == 1 ]]; then
    BOOTSTRAP_CMAKE_ARGS=${CMAKE_ARGS//${PREFIX}/${BUILD_PREFIX}}
    BOOTSTRAP_CMAKE_ARGS=${BOOTSTRAP_CMAKE_ARGS//${CONDA_TOOLCHAIN_HOST}/${CONDA_TOOLCHAIN_BUILD}}
    # libintl is only used on macOS
    if [[ ${target_platform} =~ .*osx.* ]]; then
        BOOTSTRAP_CMAKE_ARGS="${BOOTSTRAP_CMAKE_ARGS} -DLIBINTL_LIBRARY=${BUILD_PREFIX}/lib/libintl${SHLIB_EXT}"
    fi

    CROSS_CFLAGS="${CFLAGS}"
    CROSS_LDFLAGS="${LDFLAGS}"
    CROSS_CC="${CC}"
    CROSS_LD="${LD}"

    LDFLAGS="${LDFLAGS//${PREFIX}/${BUILD_PREFIX}}"
    CFLAGS="${CFLAGS//-mcpu=power8 -mtune=power8/-mcpu=haswell -mtune=haswell}"
    CC="${CC//${CONDA_TOOLCHAIN_HOST}/${CONDA_TOOLCHAIN_BUILD}}"
    LD="${LD//${CONDA_TOOLCHAIN_HOST}/${CONDA_TOOLCHAIN_BUILD}}"

    cmake -S . -B build_host \
        -DCMAKE_BUILD_TYPE=Release \
        -DUSE_BUNDLED=OFF \
        -DICONV_LIBRARY="${BUILD_PREFIX}/lib/libiconv${SHLIB_EXT}" \
        -DLIBUV_LIBRARY="${BUILD_PREFIX}/lib/libuv${SHLIB_EXT}" \
        -DLPEG_LIBRARY="${BUILD_PREFIX}/lib/liblpeg${SHLIB_EXT}" \
        -DLUAJIT_LIBRARY="${BUILD_PREFIX}/lib/libluajit-5.1${SHLIB_EXT}" \
        -DLUV_LIBRARY="${BUILD_PREFIX}/lib/libluv${SHLIB_EXT}" \
        -DTREESITTER_LIBRARY="${BUILD_PREFIX}/lib/libtree-sitter${SHLIB_EXT}" \
        -DUNIBILIUM_LIBRARY="${BUILD_PREFIX}/lib/libunibilium${SHLIB_EXT}" \
        -DUTF8PROC_LIBRARY="${BUILD_PREFIX}/lib/libutf8proc${SHLIB_EXT}" \
        ${BOOTSTRAP_CMAKE_ARGS}
    cmake --build build_host --parallel "${CPU_COUNT}"
    cmake --install build_host --parallel "${CPU_COUNT}"

    CFLAGS="${CROSS_CFLAGS}"
    LDFLAGS="${CROSS_LDFLAGS}"
    CC="${CROSS_CC}"
    LD="${CROSS_LD}"

    export LUA_CPATH="${SRC_DIR}/build_host/lib/libnlua0.so"

    sed -i -e "s,\$<TARGET_FILE:nvim_bin>,${BUILD_PREFIX}/bin/nvim,g" src/nvim/po/CMakeLists.txt test/CMakeLists.txt runtime/CMakeLists.txt
fi

cmake -S cmake.deps -B .deps \
    -DCMAKE_BUILD_TYPE=Release \
    -DUSE_BUNDLED=OFF \
    -DUSE_BUNDLED_TS_PARSERS=ON

cmake --build .deps

cmake -S . -B build \
    -DCMAKE_BUILD_TYPE=Release \
    -DENABLE_TRANSLATIONS=ON \
    -DLIBUV_LIBRARY="${PREFIX}/lib/libuv${SHLIB_EXT}" \
    -DLPEG_LIBRARY="${PREFIX}/lib/liblpeg${SHLIB_EXT}" \
    ${CMAKE_ARGS}
cmake --build build --parallel "${CPU_COUNT}"
cmake --install build --parallel "${CPU_COUNT}"

# Tell `pixi global` to not set CONDA_PREFIX during activation
# https://pixi.sh/dev/global_tools/introduction/#opt-out-of-conda_prefix
mkdir -p "${PREFIX}/etc/pixi/nvim"
touch "${PREFIX}/etc/pixi/nvim/global-ignore-conda-prefix"

# Manually copy third-party licenses
mkdir ${SRC_DIR}/license-files
cp -r ${RECIPE_DIR}/license-files/* ${SRC_DIR}/license-files
