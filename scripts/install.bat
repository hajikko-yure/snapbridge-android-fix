@echo off
setlocal
cd /d "%~dp0"

where adb >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo Error: adb not found. Ensure Android platform-tools is in PATH.
    pause
    exit /b 1
)

set TARGET=
if not "%~1"=="" set TARGET=-s %~1

set APKS=base-aligned-debugSigned.apk split_config.arm64_v8a-aligned-debugSigned.apk split_config.ja-aligned-debugSigned.apk split_config.xxhdpi-aligned-debugSigned.apk split_shooting_tips-aligned-debugSigned.apk

echo Installing split APKs...
adb %TARGET% install-multiple -r %APKS%
if %ERRORLEVEL% EQU 0 goto success

echo.
echo Signature mismatch detected. Existing build must be removed.
echo Notice: Uninstalling will delete in-app photos and pairing history.
set /p CONFIRM="Uninstall existing build and proceed? [y/N]: "
if /i not "%CONFIRM%"=="y" (
    echo Cancelled.
    pause
    exit /b 1
)

echo Uninstalling com.nikon.snapbridge.cmru...
adb %TARGET% uninstall com.nikon.snapbridge.cmru
if %ERRORLEVEL% NEQ 0 (
    echo Error: Uninstall failed.
    pause
    exit /b 1
)

echo Retrying installation...
adb %TARGET% install-multiple %APKS%
if %ERRORLEVEL% EQU 0 goto success

echo Error: Installation failed.
pause
exit /b 1

:success
echo Success.
