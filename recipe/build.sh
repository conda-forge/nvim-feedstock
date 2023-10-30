#!/usr/bin/env bash

set -o xtrace -o nounset -o pipefail -o errexit

if [[ ${CONDA_BUILD_CROSS_COMPILATION:-0} == 1 ]]; then
    sed -i -e "s,\$<TARGET_FILE:nvim>,${BUILD_PREFIX}/bin/nvim,g" src/nvim/po/CMakeLists.txt test/CMakeLists.txt
    sed -i -e "s,\${PROJECT_BINARY_DIR}/bin/nvim,${BUILD_PREFIX}/bin/nvim,g" runtime/CMakeLists.txt
fi

cmake -S . -B build \
    -DCMAKE_BUILD_TYPE=Release \
    -DUSE_BUNDLED=OFF \
    -DLIBLUV_LIBRARY="${PREFIX}/lib/libluv${SHLIB_EXT}" \
    -DLIBUV_LIBRARY="${PREFIX}/lib/libuv${SHLIB_EXT}" \
    ${CMAKE_ARGS}
cmake --build build
cmake --install build
