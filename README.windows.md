# todo-manage – TODO API + Claude Skills (Windows向け)

このドキュメントは Windows (PowerShell) 上で todo-manage をセットアップ・稼働させるための手順です。macOS 向け手順は既存の `README.md` を参照してください。

---

## セットアップ手順 (PowerShell 推奨)

### 0. 事前準備

- Docker Desktop for Windows (WSL 2 backend を有効化)
- Python 3.11 以上と `pip`
- PowerShell 7 以上
- Claude Code / Codex CLI が利用できる状態

### 1. Skills を API プロジェクトに配置

```powershell
$ROOT = "D:\todo-manage"
$API = Join-Path $ROOT "todo-api"
$SKILLS = Join-Path $ROOT "todo-api-skills"
$TARGET = Join-Path $API ".claude\skills"

New-Item -ItemType Directory -Force $TARGET | Out-Null

Copy-Item -Recurse -Force (Join-Path $SKILLS "api.task-listing.minimal-v1")            $TARGET
Copy-Item -Recurse -Force (Join-Path $SKILLS "architecture.id-allocation.counters-v1") $TARGET
Copy-Item -Recurse -Force (Join-Path $SKILLS "ops.review.evidence-v1")                 $TARGET
Copy-Item -Recurse -Force (Join-Path $SKILLS "tdd.red-case.write-v1")                  $TARGET

Copy-Item -Force (Join-Path $SKILLS "AGENTS.md") (Join-Path $API "AGENTS.md")
```

### 2. API を起動

```powershell
Set-Location D:\todo-manage\todo-api

# Docker Compose で依存サービスごと起動
# (初回は数分かかる場合があります)
docker compose up -d

# もしくはローカル環境で直接起動
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### 3. Claude Code での確認

- `todo-api` プロジェクトを Claude Code で開き、`/.claude/skills` に Skills が並んでいることを確認
- 確認観点
  - `architecture.id-allocation.counters-v1`: ID 採番に関するドキュメントを提示できること
  - `api.task-listing.minimal-v1`: 最新のタスク一覧 API を呼び出せること
  - `ops.review.evidence-v1`: レビューのエビデンスを参照・共有できること
  - `tdd.red-case.write-v1`: RED ケースのテストファイルを作成できること

---

## ディレクトリ構成

```
D:\todo-manage
├─ todo-api\            # FastAPI プロジェクト (app/, tests/, docker-compose.yml など)
├─ todo-api-client-sample\
└─ todo-api-skills\     # Claude Skills + Codex CLI 用ファイル (AGENTS.md / CLAUDE_SKILLS_SETUP.md)
```

---

## メモ

- Skills をプロジェクト専用で利用する場合は `todo-api\.claude\skills` に置いてください。グローバルで共有したい場合は `%UserProfile%\.claude\skills` を利用できます。
- Skill の詳細なセットアップ手順は `todo-api-skills\CLAUDE_SKILLS_SETUP.md` を参照してください。
- Codex CLI でエージェント定義を上書きしたい場合は、`todo-api\AGENTS.md` を `todo-api-skills` 側からコピーしてください。
- Docker Desktop のリソース設定 (CPU / メモリ) を見直すとコンテナ起動が安定します。

---

最終更新: 2025-10-24
