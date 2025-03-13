@echo on
set "CMAKE_GENERATOR=Ninja"

cmake -S cmake.deps -B .deps -G Ninja -D CMAKE_BUILD_TYPE=Release -DUSE_BUNDLED=OFF -DUSE_BUNDLED_UV=ON || goto :error
cmake --build .deps || goto :error
cmake -S . -B build ^
    -G %CMAKE_GENERATOR% ^
    -DCMAKE_BUILD_TYPE=Release ^
    -DCMAKE_INSTALL_PREFIX="%LIBRARY_PREFIX%" ^
    %CMAKE_ARGS% || goto :error
cmake --build build --config Release || goto :error

@REM cmake --install build fails with permission denied error
@REM we need to manually copy the files over
copy .\build\bin\nvim.exe %LIBRARY_PREFIX%\bin || goto :error
copy .\build\windows_runtime_deps\cat.exe %LIBRARY_PREFIX%\bin || goto :error
copy .\build\windows_runtime_deps\tee.exe %LIBRARY_PREFIX%\bin || goto :error
copy .\build\windows_runtime_deps\win32yank.exe %LIBRARY_PREFIX%\bin || goto :error
copy .\build\windows_runtime_deps\xxd.exe %LIBRARY_PREFIX%\bin || goto :error

goto :EOF

:error
echo Failed with error #%errorlevel%.
exit 1
