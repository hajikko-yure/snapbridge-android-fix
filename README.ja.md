# snapbridge-android-fix

[English](README.md) | 日本語

Android 17などの環境で、Nikon SnapBridgeが起動直後にクラッシュ（StackOverflowError）する問題を解消するパッチです。

## 免責事項

本ソフトウェアは個人による非公式の互換性修正であり、株式会社ニコンとは無関係です。自己責任で使用してください。作者はいかなる損害についても責任を負いません。本ビルドに関してメーカーや販売店へ問い合わせないでください。権利者からの要請があった場合は速やかに公開を停止します。なお、SnapBridgeおよびCOOLPIX等の名称は株式会社ニコンの商標です。

## 注意

公式版とは署名が異なるため、上書きインストールはできません。既存アプリを削除すると、アプリ内ストレージの写真やカメラのペアリング設定が消去されます。必要な写真は事前に端末のギャラリー（DCIM）やGoogleフォト、PC等へ退避してください。

## インストール

[Releases](../../releases) から `snapbridge-v2.14.3-patched.zip` をダウンロードして展開し、`install.bat`（または `install.ps1`）を実行します。

```bash
install.bat [device_serial]
```

署名不一致のエラーが出た場合は、確認プロンプト（y/N）で既存アプリを削除して再インストールできます。

## 動作確認環境

Pixel 7a（Android 17）と COOLPIX W100 の組み合わせで、Wi-Fi接続時の起動クラッシュ解消、BluetoothでのGPS同期、Wi-Fiでのリモート撮影（ライブビュー・シャッター）を確認しています。

## ファイル構成

* `scripts/apply_patch.py`: smali修正スクリプト
* `scripts/install.bat`: Windows用インストーラー
* `scripts/install.ps1`: PowerShell用インストーラー
* `README.md`: 英語ドキュメント
* `README.ja.md`: 日本語ドキュメント
* `LICENSE`: MIT License

## エラー内容

Android 17などの環境でSnapBridgeを起動すると、ネットワーク通信時に以下のスタックトレースを出力して強制終了します。

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

起動時のファームウェア確認通信において、リクエストパラメータを文字列化するデバッグ処理（`toDumpString`）がリフレクションでオブジェクトを再帰走査しています。新しいAndroidランタイムでは内部構造の変化により終了判定が機能せず、`objectAna` と `getFieldString` の無限再帰となって1036KBのスタック領域を超過していました。

## 修正内容

`com.nikon.snapbridge.cmru.webclient.commons.WebApiParameter` の `toDumpString()` を空文字列の即時返却に変更しました。

```smali
.method public toDumpString()Ljava/lang/String;
    .locals 1

    const-string v0, ""

    return-object v0
.end method
```

ログ生成用の文字列処理のみを変更しています。通信ペイロード生成（`toMap()`）やカメラとの通信処理自体は変更していません。
