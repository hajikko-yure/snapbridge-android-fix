# SnapBridge Patched Installer for PowerShell
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location $scriptDir

Write-Host "=== SnapBridge Patched Installer ===" -ForegroundColor Cyan
Write-Host "Checking connected adb devices..."
adb devices -l

$apks = @(
    "base-aligned-debugSigned.apk",
    "split_config.arm64_v8a-aligned-debugSigned.apk",
    "split_config.ja-aligned-debugSigned.apk",
    "split_config.xxhdpi-aligned-debugSigned.apk",
    "split_shooting_tips-aligned-debugSigned.apk"
)

$missing = $apks | Where-Object { -not (Test-Path (Join-Path $scriptDir $_)) }
if ($missing) {
    Write-Host "Error: The following APK files were not found:" -ForegroundColor Red
    $missing | ForEach-Object { Write-Host " - $_" -ForegroundColor Red }
    exit 1
}

Write-Host "Installing split APKs via adb install-multiple..." -ForegroundColor Yellow
$apkArgs = $apks | ForEach-Object { "`"$($_)`"" }
$cmd = "adb install-multiple " + ($apkArgs -join " ")
Invoke-Expression $cmd

if ($LASTEXITCODE -eq 0) {
    Write-Host "`nInstallation successful!" -ForegroundColor Green
} else {
    Write-Host "`nInstallation failed. If official SnapBridge is already installed, uninstall it first:`n  adb uninstall com.nikon.snapbridge.cmru" -ForegroundColor Red
}
