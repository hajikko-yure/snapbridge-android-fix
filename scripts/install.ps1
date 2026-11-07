param (
    [string]$Serial
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location $scriptDir

$target = if ($Serial) { "-s $Serial" } else { "" }
$apks = @(
    "base-aligned-debugSigned.apk",
    "split_config.arm64_v8a-aligned-debugSigned.apk",
    "split_config.ja-aligned-debugSigned.apk",
    "split_config.xxhdpi-aligned-debugSigned.apk",
    "split_shooting_tips-aligned-debugSigned.apk"
) -join " "

Write-Host "Installing split APKs..."
Invoke-Expression "adb $target install-multiple -r $apks"

if ($LASTEXITCODE -ne 0) {
    Write-Host "`nSignature mismatch detected. Existing build must be removed."
    Write-Host "Notice: Uninstalling will delete in-app photos and pairing history.`n"

    $confirm = Read-Host "Uninstall existing build and proceed? [y/N]"
    if ($confirm -ne "y" -and $confirm -ne "Y") {
        Write-Host "Cancelled."
        exit 1
    }

    Write-Host "Uninstalling com.nikon.snapbridge.cmru..."
    Invoke-Expression "adb $target uninstall com.nikon.snapbridge.cmru"
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error: Uninstall failed."
        exit 1
    }

    Write-Host "Retrying installation..."
    Invoke-Expression "adb $target install-multiple $apks"
}

if ($LASTEXITCODE -eq 0) {
    Write-Host "Success."
} else {
    Write-Host "Error: Installation failed."
    exit 1
}
