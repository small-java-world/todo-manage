# todo-api-client-sample (Windows向けクイックスタート)

`todo-api` の API を Windows から簡単に叩くためのサンプルです。macOS/Linux 手順は既存の `README.md` を参照してください。

---

## 0. 前提
- Windows 11 + PowerShell 7 以上
- Python 3.11 以上と `pip`
- Git for Windows（Git Bash 同梱）または WSL (bash) ※`scripts/quick_test.sh` を使う場合
- API エンドポイント (既定: `http://localhost:8000`) が起動済み
- 任意: Claude Code / Codex CLI を利用する場合は `.claude/skills` を配置

## 1. `.claude/skills` と `AGENTS.md` のコピー
```powershell
$ROOT   = "D:\\todo-manage"
$CLIENT = Join-Path $ROOT "todo-api-client-sample"
$SKILLS = Join-Path $ROOT "todo-api-skills"
$TARGET = Join-Path $CLIENT ".claude\\skills"

New-Item -ItemType Directory -Force $TARGET | Out-Null

"api.task-listing.minimal-v1",
"architecture.id-allocation.counters-v1",
"ops.review.evidence-v1",
"tdd.red-case.write-v1" | ForEach-Object {
    Copy-Item -Recurse -Force (Join-Path $SKILLS $_) $TARGET
}

Copy-Item -Force (Join-Path $SKILLS "AGENTS.md") (Join-Path $CLIENT "AGENTS.md")
```
Claude Code で本ディレクトリを開き、`/.claude/skills` に Skill が表示されれば準備完了です。

## 2. Bash スクリプトでスモークテスト
```powershell
Set-Location $CLIENT
$Env:API_URL = "http://localhost:8000"   # 任意のエンドポイントに書き換え
bash scripts/quick_test.sh                # Git Bash or WSL (bash)
```
- Git Bash で `bash` を実行する場合は Docker Desktop が WSL 2 backend を指していることを確認してください。
- 追加の依存: `curl`, `jq`（どちらも Git Bash には同梱されています）。

## 3. Python クライアントの利用
```powershell
Set-Location $CLIENT
python -m venv .venv
.\\.venv\\Scripts\\Activate.ps1
pip install -r requirements.txt

python client.py health
python client.py list --status in_progress --limit 5
python client.py req-create --title "要件" --desc "説明"
python client.py task-create --title "タスク" --parent 1 --type task
```
環境変数 `API_URL` を設定すると `client.py` から自動で参照されます。

## 4. PowerShell だけで呼び出す例
```powershell
$ApiUrl = $Env:API_URL
if (-not $ApiUrl) { $ApiUrl = "http://localhost:8000" }

Invoke-RestMethod -Uri "$ApiUrl/tasks/" -Method Get | Format-Table id,title,type -AutoSize
```
PowerShell の `curl` エイリアスと衝突しないように、ネイティブコマンドを使う場合は `curl.exe` を明示してください。

## 5. ディレクトリ構成
```
todo-api-client-sample
├─ .claude/skills/             # Claude Skills (Windows ではコピーを推奨)
├─ scripts/quick_test.sh       # curl + jq によるスモークテスト
├─ client.py                   # requests ベースの簡易クライアント
├─ requirements.txt
├─ README.md (mac / Linux 向け)
└─ README.windows.md (本書)
```

## 6. ヒント / 注意
- Windows で symlink が作れない環境では `mklink /D` の代わりに上記コピー手順を利用してください。
- `bash scripts/quick_test.sh` 実行時に証明書エラーが出る場合は PowerShell から `setx SSL_CERT_FILE ...` で証明書を共有するか、WSL Ubuntu 上で実行してください。
- 連続リクエストを行う場合は `$Env:API_URL` を固定し、`python client.py` に `--limit` や `--status` オプションを渡して絞り込みます。

最終更新: 2025-10-24
