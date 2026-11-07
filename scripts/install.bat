@echo off
setlocal
cd /d "%~dp0"

echo [SnapBridge Patched Installer]
echo Checking connected devices...
adb devices -l
echo.

echo Installing patched SnapBridge split APKs...
adb install-multiple base-aligned-debugSigned.apk split_config.arm64_v8a-aligned-debugSigned.apk split_config.ja-aligned-debugSigned.apk split_config.xxhdpi-aligned-debugSigned.apk split_shooting_tips-aligned-debugSigned.apk

if %ERRORLEVEL% EQU 0 (
    echo.
    echo Installation Successful!
) else (
    echo.
    echo Installation Failed. If you have official SnapBridge installed, please uninstall it first:
    echo   adb uninstall com.nikon.snapbridge.cmru
)

pause

