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

:: Tell `pixi global` to not set CONDA_PREFIX during activation
:: https://pixi.sh/dev/global_tools/introduction/#opt-out-of-conda_prefix
if not exist "%PREFIX%\\etc\\pixi" mkdir "%PREFIX%\\etc\\pixi\\nvim"
type nul > "%PREFIX%\\etc\\pixi\\nvim\\global-ignore-conda-prefix"

goto :EOF

:error
echo Failed with error #%errorlevel%.
exit 1
