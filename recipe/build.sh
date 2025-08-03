#!/usr/bin/env bash

set -o xtrace -o nounset -o pipefail -o errexit

if [[ ${CONDA_BUILD_CROSS_COMPILATION:-0} == 1 ]]; then
    BOOTSTRAP_CMAKE_ARGS=${CMAKE_ARGS//${PREFIX}/${BUILD_PREFIX}}
    BOOTSTRAP_CMAKE_ARGS=${BOOTSTRAP_CMAKE_ARGS//${CONDA_TOOLCHAIN_HOST}/${CONDA_TOOLCHAIN_BUILD}}

    CROSS_LDFLAGS=${LDFLAGS}
    CROSS_CC="${CC}"
    CROSS_LD="${LD}"

    LDFLAGS=${LDFLAGS//${PREFIX}/${BUILD_PREFIX}}
    CC=${CC//${CONDA_TOOLCHAIN_HOST}/${CONDA_TOOLCHAIN_BUILD}}
    LD="${LD//${CONDA_TOOLCHAIN_HOST}/${CONDA_TOOLCHAIN_BUILD}}"

    cmake -S . -B build_host \
        -DCMAKE_BUILD_TYPE=Release \
        -DENABLE_TRANSLATIONS=ON \
        -DUSE_BUNDLED=OFF \
        -DICONV_LIBRARY="${BUILD_PREFIX}/lib/libiconv${SHLIB_EXT}" \
        -DLIBINTL_LIBRARY="${BUILD_PREFIX}/lib/libintl${SHLIB_EXT}" \
        -DLIBUV_LIBRARY="${BUILD_PREFIX}/lib/libuv${SHLIB_EXT}" \
        -DLIBVTERM_LIBRARY="${BUILD_PREFIX}/lib/libvterm${SHLIB_EXT}" \
        -DLPEG_LIBRARY="${BUILD_PREFIX}/lib/liblpeg${SHLIB_EXT}" \
        -DLUAJIT_LIBRARY="${BUILD_PREFIX}/lib/libluajit-5.1${SHLIB_EXT}" \
        -DLUV_LIBRARY="${BUILD_PREFIX}/lib/libluv${SHLIB_EXT}" \
        -DMSGPACK_LIBRARY="${BUILD_PREFIX}/lib/libmsgpack-c${SHLIB_EXT}" \
        -DTREESITTER_LIBRARY="${BUILD_PREFIX}/lib/libtree-sitter${SHLIB_EXT}" \
        -DUNIBILIUM_LIBRARY="${BUILD_PREFIX}/lib/libunibilium${SHLIB_EXT}" \
        -DUTF8PROC_LIBRARY="${BUILD_PREFIX}/lib/libutf8proc${SHLIB_EXT}" \
        ${BOOTSTRAP_CMAKE_ARGS}
    cmake --build build_host
    cmake --install build_host

    LDFLAGS="${CROSS_LDFLAGS}"
    CC=${CROSS_CC}
    LD=${CROSS_LD}

    export LUA_CPATH="${SRC_DIR}/build_host/lib/libnlua0.so"

    sed -i -e "s,\$<TARGET_FILE:nvim_bin>,${BUILD_PREFIX}/bin/nvim,g" src/nvim/po/CMakeLists.txt test/CMakeLists.txt runtime/CMakeLists.txt
fi

cmake -S . -B build \
    -DCMAKE_BUILD_TYPE=Release \
    -DUSE_BUNDLED=OFF \
    -DLIBUV_LIBRARY="${PREFIX}/lib/libuv${SHLIB_EXT}" \
    -DLPEG_LIBRARY="${PREFIX}/lib/liblpeg${SHLIB_EXT}" \
    ${CMAKE_ARGS}
cmake --build build
cmake --install build
