@echo off
setlocal

echo [1/3] Enabling Windows fonts...
call dart tool/fonts_manager.dart enable
if %errorlevel% neq 0 (
    echo Error: Failed to enable fonts.
    exit /b %errorlevel%
)

echo [2/3] Building Windows release...
rem SENTRY_DSN comes from the release workflow. Without it the build has no
rem address to report to and diagnostics are off whatever the setting says --
rem which is how every Windows build shipped until 1.16.18. Empty is fine: a
rem local build simply stays silent.
call flutter build windows --release "--dart-define=SENTRY_DSN=%SENTRY_DSN%"
set BUILD_ERROR=%errorlevel%

echo [3/3] Disabling fonts (cleanup)...
call dart tool/fonts_manager.dart disable

if %BUILD_ERROR% neq 0 (
    echo Build failed with error code %BUILD_ERROR%.
    exit /b %BUILD_ERROR%
)

echo Build success!
endlocal
