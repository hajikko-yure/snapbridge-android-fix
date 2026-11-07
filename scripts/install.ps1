param (
    [string]$Serial
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location $scriptDir

Write-Host "Checking devices..."
adb devices -l

$apks = @(
    "base-aligned-debugSigned.apk",
    "split_config.arm64_v8a-aligned-debugSigned.apk",
    "split_config.ja-aligned-debugSigned.apk",
    "split_config.xxhdpi-aligned-debugSigned.apk",
    "split_shooting_tips-aligned-debugSigned.apk"
)

$target = if ($Serial) { "-s $Serial" } else { "" }
$apkArgs = ($apks | ForEach-Object { "`"$($_)`"" }) -join " "

Write-Host "Installing split APKs..."
Invoke-Expression "adb $target install-multiple -r $apkArgs"

if ($LASTEXITCODE -eq 0) {
    Write-Host "Success." -ForegroundColor Green
} else {
    Write-Host "Failed. If multiple devices are connected, specify: .\install.ps1 -Serial <serial>" -ForegroundColor Red
}
