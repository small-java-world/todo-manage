# Windows ネイティブでのポート占有テスト手順

このドキュメントは、Hyper-V backend の Docker Desktop 環境で `todo-api` (port 8000) の起動異常を再現し、後片付けまで自動化するための手順です。

## 1. 事前条件
- PowerShell 7 を管理者で実行
- 既に `todo-api` コンテナを停止しておく (`docker compose down`)

## 2. ポート占有の模擬 (netsh portproxy)
```powershell
$ListenAddress = "0.0.0.0"
$ListenPort    = 8000
$ConnectAddr   = "127.0.0.1"
$ConnectPort   = 65535

netsh interface portproxy add v4tov4 `
    listenaddress=$ListenAddress listenport=$ListenPort `
    connectaddress=$ConnectAddr connectport=$ConnectPort
```
> `connectport` には未使用ポートを指定してください。これで 8000 番が占有され、`docker compose up` 時にポート競合エラーが発生します。

## 3. 競合ログの取得
```powershell
Set-Location D:\todo-manage\todo-api
docker compose up -d
New-Item -ItemType Directory -Force ..\logs | Out-Null
docker compose logs todo-api --tail 100 > ..\logs\port-conflict.log
```
- 失敗後は必ず `docker compose down` を実行しておきます。

## 4. 後片付け
```powershell
netsh interface portproxy delete v4tov4 `
    listenaddress=$ListenAddress listenport=$ListenPort
```
- 上記コマンドが成功したら `netsh interface portproxy show all` で entries が消えていることを確認
- `logs/port-conflict.log` をチーム共有ドライブへアップロード

## 5. 注意
- portproxy が残ったままだと以後の起動も失敗するため、必ず削除する
- 管理者 PowerShell 以外では `netsh` の追加/削除に失敗します
