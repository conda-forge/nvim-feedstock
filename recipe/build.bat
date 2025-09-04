@echo on

REM Set flags to handle UTF-8 properly
setlocal enabledelayedexpansion

set LANG=en_US.UTF-8
set LC_ALL=en_US.UTF-8
set LC_CTYPE=en_US.UTF-8
set VSLANG=1033
set PYTHONUTF8=1
chcp 65001 > nul 2>&1
set CL=/utf-8
set CFLAGS=-D_CRT_SECURE_NO_WARNINGS /utf-8
set CXXFLAGS=-D_CRT_SECURE_NO_WARNINGS /utf-8

cmake -S cmake.deps -B .deps -G Ninja ^
    -DUSE_BUNDLED_UV=ON ^
    -DUSE_BUNDLED=OFF ^
    -DCMAKE_C_FLAGS="/utf-8 /D_CRT_SECURE_NO_WARNINGS" ^
    -DCMAKE_CXX_FLAGS="/utf-8 /D_CRT_SECURE_NO_WARNINGS" ^
    %CMAKE_ARGS% ^
    || goto :error

cmake --build .deps --parallel %CPU_COUNT% || goto :error

cmake -S . -B build -G Ninja ^
    -DENABLE_TRANSLATIONS=ON ^
    -DUSE_BUNDLED=OFF ^
    -DCMAKE_C_FLAGS="/utf-8 /D_CRT_SECURE_NO_WARNINGS" ^
    -DCMAKE_CXX_FLAGS="/utf-8 /D_CRT_SECURE_NO_WARNINGS" ^
    %CMAKE_ARGS% ^
    || goto :error

cmake --build build --parallel %CPU_COUNT% || goto :error
cmake --install build || goto :error

goto :EOF

:error
echo Failed with error #%errorlevel%.
exit 1
