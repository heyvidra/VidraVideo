@echo off
setlocal

echo [1/3] Enabling Windows fonts...
call dart tool/fonts_manager.dart enable
if %errorlevel% neq 0 (
    echo Error: Failed to enable fonts.
    exit /b %errorlevel%
)

echo [2/3] Building Windows release...
call flutter build windows --release
set BUILD_ERROR=%errorlevel%

echo [3/3] Disabling fonts (cleanup)...
call dart tool/fonts_manager.dart disable

if %BUILD_ERROR% neq 0 (
    echo Build failed with error code %BUILD_ERROR%.
    exit /b %BUILD_ERROR%
)

echo Build success!
endlocal
