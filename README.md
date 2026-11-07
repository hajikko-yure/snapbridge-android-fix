# snapbridge-android-fix

English | [日本語](README.ja.md)

Compatibility patch resolving startup crashes (StackOverflowError) of Nikon SnapBridge on modern Android runtimes (Android 17+).

## Disclaimer

This project is an unofficial, independent compatibility fix and is not affiliated with Nikon Corporation. Use at your own risk. The author assumes no liability for device malfunction, data loss, or other damages. Do not contact Nikon support or retailers regarding this build. This repository will be removed upon request from copyright owners. SnapBridge, COOLPIX, and related names are trademarks of Nikon Corporation.

## Notice

This build is signed with a debug certificate and cannot be installed over the official build. Uninstalling the official app removes all in-app storage, including unexported photos and camera pairing history. Back up your photos to your device gallery (DCIM), cloud storage, or PC before proceeding.

## Installation

Download `snapbridge-v2.14.3-patched.zip` from [Releases](../../releases), extract the archive, and run `install.bat` (or `install.ps1`).

```bash
install.bat [device_serial]
```

If an existing signature mismatch is detected, a confirmation prompt (y/N) will ask before uninstalling the conflicting package.

## Verified Environment

Tested on Pixel 7a (Android 17) with COOLPIX W100. Confirmed crash resolution on Wi-Fi, background Bluetooth GPS synchronization, and Wi-Fi remote photography (live view and shutter release).

## Repository Structure

* `scripts/apply_patch.py`: Smali patch script
* `scripts/install.bat`: Windows installer
* `scripts/install.ps1`: PowerShell installer
* `README.md`: English documentation
* `README.ja.md`: Japanese documentation
* `LICENSE`: MIT License

## Error Details

On Android 17 and newer runtimes, SnapBridge crashes immediately upon network activity:

```text
FATAL EXCEPTION: Thread-xxx
Process: com.nikon.snapbridge.cmru
java.lang.StackOverflowError: stack size 1036KB
	at com.nikon.snapbridge.cmru.webclient.commons.WebApiParameter.getAllFields(...)
	at com.nikon.snapbridge.cmru.webclient.commons.WebApiParameter.getFieldString(...)
	at com.nikon.snapbridge.cmru.webclient.commons.WebApiParameter.objectAna(...)
	...
	at com.nikon.snapbridge.cmru.webclient.commons.WebApiParameter.toDumpString(...)
	at com.nikon.snapbridge.cmru.webclient.commons.WebApiRequest.toDumpString(...)
	at com.nikon.snapbridge.cmru.webclient.nms.apis.NmsFirmwareInformationApi.getLatestFirmwareInformation(...)
```

During initial firmware verification requests, `toDumpString()` recursively inspects request parameters via reflection. In newer Android runtimes, structural changes prevent traversal termination, resulting in infinite recursion between `objectAna()` and `getFieldString()` that exhausts the 1036KB call stack.

## Patch Details

`com.nikon.snapbridge.cmru.webclient.commons.WebApiParameter.toDumpString()` is modified to return an empty string immediately:

```smali
.method public toDumpString()Ljava/lang/String;
    .locals 1

    const-string v0, ""

    return-object v0
.end method
```

Only debug log string generation is modified. Payload generation (`toMap()`) and camera communication routines are untouched.
