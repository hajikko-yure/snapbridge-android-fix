@echo off
setlocal
cd /d "%~dp0"

echo [SnapBridge Patched Installer]

where adb >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo Error: adb not found in PATH.
    pause
    exit /b 1
)

set TARGET_OPT=
if not "%~1"=="" (
    set TARGET_OPT=-s %~1
)

echo Checking connected devices...
adb devices -l
echo.

echo Installing split APKs...
if not "%TARGET_OPT%"=="" (
    adb %TARGET_OPT% install-multiple -r base-aligned-debugSigned.apk split_config.arm64_v8a-aligned-debugSigned.apk split_config.ja-aligned-debugSigned.apk split_config.xxhdpi-aligned-debugSigned.apk split_shooting_tips-aligned-debugSigned.apk
) else (
    adb install-multiple -r base-aligned-debugSigned.apk split_config.arm64_v8a-aligned-debugSigned.apk split_config.ja-aligned-debugSigned.apk split_config.xxhdpi-aligned-debugSigned.apk split_shooting_tips-aligned-debugSigned.apk
)

if %ERRORLEVEL% EQU 0 (
    echo.
    echo Success.
) else (
    echo.
    echo Failed.
    echo If multiple devices are attached, specify serial:
    echo   install.bat ^<serial^>
    echo If official build exists, uninstall first:
    echo   adb uninstall com.nikon.snapbridge.cmru
)

pause
