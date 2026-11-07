# snapbridge-android-fix

[English](README.en.md) | 日本語

Android 17などの新しいAndroid環境で、Nikon SnapBridgeが起動直後に強制終了する問題を修正するパッチおよびインストール手順です。

## 免責事項

本リポジトリおよび公開ファイルを利用する前に、以下の事項をご確認ください。

1. **非公式プロジェクト**: 本プロジェクトは個人による非公式の検証・互換性修正であり、株式会社ニコン（Nikon Corporation）とは一切関係ありません。
2. **商標および著作権の帰属**: 「SnapBridge」「COOLPIX」および関連する名称・ロゴは、株式会社ニコンまたは各権利者の商標または登録商標です。
3. **無保証・自己責任**: 本パッチおよびインストーラーの使用は、利用者の自己責任で行ってください。本ソフトウェアの使用によって生じたカメラ・端末の故障、データの消失、その他の損害について、作者は一切の責任を負いません。
4. **公式サポートへの問い合わせ禁止**: 本パッチを適用した状態のアプリや動作について、株式会社ニコンのサポート窓口や販売店へ問い合わせないでください。
5. **権利者からの要請への対応**: 権利者からの申し立てや要請があった場合、予告なく公開を停止または削除します。

## インストール手順

### 1. 配布ファイルのダウンロード
Releasesページから最新の `snapbridge-v2.14.3-patched.zip` をダウンロードし、展開します。

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

## 動作確認済み環境

* **スマートフォン**: Pixel 7a（Android 17 Preview / Betaビルド）
* **カメラ**: COOLPIX W100（ファームウェア最新）
* **確認済み機能**:
  * 自宅Wi-Fiに接続した状態でのアプリ常時起動（クラッシュの解消）
  * Bluetooth常時接続によるスマートフォンGPS位置情報のカメラExif同期
  * アプリからのWi-Fi切り替えによるリモート撮影（ライブビュー表示およびシャッター操作）

## ファイル構成

* `README.md`: 英語ドキュメント（デフォルト）
* `README.ja.md`: 日本語ドキュメント
* `LICENSE`: ライセンス情報（MIT License）
* `scripts/apply_patch.py`: smaliファイルを修正するスクリプト
* `scripts/install.bat`: Windows用インストールスクリプト
* `scripts/install.ps1`: PowerShell用インストールスクリプト

## エラー内容

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
