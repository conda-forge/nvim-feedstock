@echo on

cmake -S cmake.deps -B .deps -G Ninja ^
    -DUSE_BUNDLED_UV=ON ^
    -DUSE_BUNDLED=OFF ^
    %CMAKE_ARGS% ^
    || goto :error

cmake --build .deps --parallel %CPU_COUNT% || goto :error

cmake -S . -B build -G Ninja ^
    -DENABLE_TRANSLATIONS=ON ^
    -DUSE_BUNDLED=OFF ^
    %CMAKE_ARGS% ^
    || goto :error

cmake --build build --parallel %CPU_COUNT% || goto :error
cmake --install build --parallel %CPU_COUNT% || goto :error

goto :EOF

:error
echo Failed with error #%errorlevel%.
exit 1
