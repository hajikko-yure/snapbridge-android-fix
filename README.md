# snapbridge-android-fix

Android 17などの新しいAndroid環境で、Nikon SnapBridgeが起動直後に強制終了する問題を修正するパッチとインストール手順です。

## 発生する問題と原因

### エラー内容
Android 17（Preview / Beta等）の端末でSnapBridgeを起動すると、Wi-Fi接続時や通信発生時に以下のスタックトレースを出力して強制終了します。

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

### 原因
アプリ起動時にサーバーへファームウェア情報を問い合わせる際、ログ用の文字列生成処理（`toDumpString`）が内部オブジェクトをリフレクションで再帰的に解析しています。
新しいAndroid環境ではランタイム内部の構造変化により終了条件が満たされず、無限再帰となってスタック領域（1036KB）を使い果たしていました。

## 修正内容

`com.nikon.snapbridge.cmru.webclient.commons.WebApiParameter` の `toDumpString()` を書き換え、リフレクション解析を行わずに空文字列を返すように変更しました。

```smali
.method public toDumpString()Ljava/lang/String;
    .locals 1

    const-string v0, ""

    return-object v0
.end method
```

実際の通信処理（`toMap()`）やリクエスト送信には影響せず、ログ生成時のクラッシュだけを防ぎます。

## インストール手順

### 1. 配布ファイルのダウンロード
Releasesページから `snapbridge-v2.14.3-patched.zip` をダウンロードし、展開します。

### 2. 既存アプリのアンインストール
再署名したAPKを使用するため、公式版への上書きはできません。先にアンインストールします。

```bash
adb uninstall com.nikon.snapbridge.cmru
```

### 3. パッチ版のインストール
展開したフォルダ内にある `install.bat`（Windows）または `install.ps1` を実行するか、以下のコマンドを実行します。

```bash
adb install-multiple base-aligned-debugSigned.apk split_config.arm64_v8a-aligned-debugSigned.apk split_config.ja-aligned-debugSigned.apk split_config.xxhdpi-aligned-debugSigned.apk split_shooting_tips-aligned-debugSigned.apk
```

## 動作確認

COOLPIX W100などの対応カメラにおいて、端末のWi-Fiを常時オンにしたままでも以下の機能が正常に動作することを確認しています。

* **Bluetooth常時接続**: スマートフォンのGPS位置情報をカメラへ同期
* **リモート撮影**: カメラのWi-Fiへ切り替えてのライブビュー表示およびシャッター操作

## ファイル構成

* `README.md`: 本ドキュメント
* `scripts/apply_patch.py`: smaliファイルを修正するスクリプト
* `scripts/install.bat`: Windows用インストールスクリプト
* `scripts/install.ps1`: PowerShell用インストールスクリプト
