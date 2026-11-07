# snapbridge-android-fix

Nikon SnapBridge アプリが **Android 17 (Preview / Beta) や最新の Android ランタイム環境で起動直後に強制終了する不具合** を修正したパッチおよびインストールツールキットです。

---

## 📌 背景と問題の原因

### 発生する症状
* Android 17 / 最新OS搭載端末（Pixel 7a 等）で Nikon SnapBridge を起動すると、数秒後（特にWi-Fi接続時や通信発生時）にアプリがクラッシュ・強制終了する。

### 原因解析 (logcat)
```text
FATAL EXCEPTION: Thread-xxx
Process: com.nikon.snapbridge.cmru
java.lang.StackOverflowError: stack size 1036KB
	at com.nikon.snapbridge.cmru.webclient.commons.WebApiParameter.getAllFields(...)
	at com.nikon.snapbridge.cmru.webclient.commons.WebApiParameter.getFieldString(...)
	at com.nikon.snapbridge.cmru.webclient.commons.WebApiParameter.objectAna(...)
	at com.nikon.snapbridge.cmru.webclient.commons.WebApiParameter.getFieldString(...)
	at com.nikon.snapbridge.cmru.webclient.commons.WebApiParameter.objectAna(...)
	... (上記2行が数百回再帰呼び出しされてスタックオーバーフロー)
	at com.nikon.snapbridge.cmru.webclient.commons.WebApiParameter.toDumpString(...)
	at com.nikon.snapbridge.cmru.webclient.commons.WebApiRequest.toDumpString(...)
	at com.nikon.snapbridge.cmru.webclient.nms.apis.NmsFirmwareInformationApi.getLatestFirmwareInformation(...)
```

* **根本原因**:
  * アプリ起動時にファームウェア確認通信（`NmsFirmwareInformationApi.getLatestFirmwareInformation`）を行う際、リクエスト内容のデバッグ用文字列化（`toDumpString`）でリフレクションを用いてパラメータオブジェクトを走査（`objectAna` ↔ `getFieldString`）しています。
  * 最新の Android ランタイムや内部クラス構造の変化により、走査の終了判定を満たせず無限再帰が発生し、Android のコールスタック上限（1036KB）を食いつぶして `StackOverflowError` で即死していました。

---

## 🛠️ パッチ内容

デバッグダンプ用メソッド `com.nikon.snapbridge.cmru.webclient.commons.WebApiParameter.toDumpString()` を修正し、リフレクション走査を行わずに即座に空文字（`""`）を返却するように変更しました。

```smali
# 修正後: smali
.method public toDumpString()Ljava/lang/String;
    .locals 1

    const-string v0, ""

    return-object v0
.end method
```

通信リクエスト自体のペイロード生成（`toMap()`）や通信処理本体には一切影響を与えず、デバッグログ生成時の無限再帰のみを完全に防ぎます。

---

## 🚀 インストール手順

### 1. リリースからダウンロード
1. [Releases](../../releases) から最新の `snapbridge-v2.14.3-patched.zip` をダウンロードして解凍します。

### 2. 既存公式アプリのアンインストール
再署名済みAPKとなるため、公式版の上書きインストールはできません。事前にアンインストールしてください。
```bash
adb uninstall com.nikon.snapbridge.cmru
```

### 3. パッチ版のインストール
同梱されている `install.bat`（Windows）または `install.ps1` を実行するか、adbコマンドでインストールします。
```bash
adb install-multiple base-aligned-debugSigned.apk split_config.arm64_v8a-aligned-debugSigned.apk split_config.ja-aligned-debugSigned.apk split_config.xxhdpi-aligned-debugSigned.apk split_shooting_tips-aligned-debugSigned.apk
```

---

## 📷 カメラ（COOLPIX W100 等）での利用

パッチ適用後は、Wi-Fi常時接続環境でもクラッシュすることなく通常通り動作します。
* **Bluetooth常時接続**: スマホの位置情報（GPS）が自動でカメラ内の写真Exifに付与されます。
* **Wi-Fiリモート撮影**: アプリから「リモート撮影」をタップすると、カメラの専用Wi-Fiに自動接続されてライブビュー撮影が行えます。

---

## 📂 リポジトリ構成

```text
├── README.md               # ドキュメント
├── .gitignore              # Git除外設定
└── scripts/
    ├── apply_patch.py      # smaliパッチ適用スクリプト
    ├── install.bat         # Windows用 adb一括インストールバッチ
    └── install.ps1         # PowerShell用 adb一括インストールスクリプト
```
