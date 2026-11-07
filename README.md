# snapbridge-android-fix

English | [日本語](README.ja.md)

A compatibility patch and installation guide to resolve startup crashes (`StackOverflowError`) of Nikon SnapBridge on newer Android versions, including Android 17 (Preview / Beta).

## Disclaimer

Please review the following terms before using this repository or any associated files:

1. **Unofficial Project**: This project is an independent compatibility fix and is not affiliated with, endorsed by, or associated with Nikon Corporation.
2. **Trademarks and Copyrights**: "SnapBridge", "COOLPIX", and related names and logos are trademarks or registered trademarks of Nikon Corporation or their respective owners.
3. **No Warranty / Use at Your Own Risk**: This software is provided "as is", without warranty of any kind. The author is not responsible for any damage, data loss, camera malfunction, or device issues resulting from the use of this software.
4. **No Official Support Requests**: Do not contact official Nikon support or retailers regarding issues arising from using this patched application.
5. **Takedown Requests**: This repository and its distributions will be removed or made private upon request from the copyright owner.

## Installation Instructions

### 1. Download
Download `snapbridge-v2.14.3-patched.zip` from the [Releases](../../releases) page and extract the archive.

### 2. Uninstall Official App
Because the patched APK is resigned with a debug key, it cannot be installed over the official build. Uninstall the existing package first:

```bash
adb uninstall com.nikon.snapbridge.cmru
```

### 3. Install Patched Splits
Run `install.bat` (Windows) or `install.ps1` from the extracted directory, or execute:

```bash
adb install-multiple base-aligned-debugSigned.apk split_config.arm64_v8a-aligned-debugSigned.apk split_config.ja-aligned-debugSigned.apk split_config.xxhdpi-aligned-debugSigned.apk split_shooting_tips-aligned-debugSigned.apk
```

## Verified Environment

* **Smartphone**: Pixel 7a (Android 17 Preview / Beta build)
* **Camera**: COOLPIX W100 (Latest firmware)
* **Verified Features**:
  * Continuous application runtime while connected to home Wi-Fi (crash resolved)
  * Continuous Bluetooth synchronization of smartphone GPS location data to camera Exif
  * Remote photography (live view display and shutter trigger) via camera Wi-Fi switching

## Repository Structure

* `README.md`: English documentation (default)
* `README.ja.md`: Japanese documentation
* `LICENSE`: License information (MIT License)
* `scripts/apply_patch.py`: Smali patch script
* `scripts/install.bat`: Windows batch installer
* `scripts/install.ps1`: PowerShell installer

## Error Details

On Android 17 (or newer runtime environments), SnapBridge crashes shortly after launch (especially upon network connectivity or Wi-Fi enabling) with the following error:

```text
FATAL EXCEPTION: Thread-xxx
Process: com.nikon.snapbridge.cmru
java.lang.StackOverflowError: stack size 1036KB
	at com.nikon.snapbridge.cmru.webclient.commons.WebApiParameter.getAllFields(...)
	at com.nikon.snapbridge.cmru.webclient.commons.WebApiParameter.getFieldString(...)
	at com.nikon.snapbridge.cmru.webclient.commons.WebApiParameter.objectAna(...)
	at com.nikon.snapbridge.cmru.webclient.commons.WebApiParameter.getFieldString(...)
	at com.nikon.snapbridge.cmru.webclient.commons.WebApiParameter.objectAna(...)
	...
	at com.nikon.snapbridge.cmru.webclient.commons.WebApiParameter.toDumpString(...)
	at com.nikon.snapbridge.cmru.webclient.commons.WebApiRequest.toDumpString(...)
	at com.nikon.snapbridge.cmru.webclient.nms.apis.NmsFirmwareInformationApi.getLatestFirmwareInformation(...)
```

### Cause
When querying the firmware server on startup, the application calls `toDumpString()` to format request parameters for debug logging.
In newer Android runtimes, structural changes in reflection and system classes cause `objectAna()` and `getFieldString()` to enter an infinite recursion loop, exhausting the 1036KB stack limit.

## Patch Details

The `toDumpString()` method in `com.nikon.snapbridge.cmru.webclient.commons.WebApiParameter` has been modified to return an empty string immediately:

```smali
.method public toDumpString()Ljava/lang/String;
    .locals 1

    const-string v0, ""

    return-object v0
.end method
```

This prevents the recursive reflection traversal without interfering with the actual payload generation (`toMap()`) or network requests.
