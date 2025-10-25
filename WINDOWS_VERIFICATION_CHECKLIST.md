# Windowsネイティブ向け機能充足検証チェックリスト

PowerShell 7 + Docker Desktop (Hyper-V backend) だけで todo-api サーバーと todo-api-client-sample クライアントを検証するためのタスク一覧です。各ステップは下記補助ドキュメントを参照しながら実施してください。

## 0. 参照ドキュメント
- [todo-api/README.windows.md](todo-api/README.windows.md)
- [todo-api-client-sample/README.windows.md](todo-api-client-sample/README.windows.md)
- [todo-api-skills/README.windows.md](todo-api-skills/README.windows.md)
- [docs/windows-skill-setup.md](docs/windows-skill-setup.md)
- [docs/windows-port-block-test.md](docs/windows-port-block-test.md)

---

## 1. 事前準備 (Windows ネイティブ)
- [ ] Windows Update 後に再起動し、`Turn Windows features on or off` で **Hyper-V** と **Containers** を ON (WSL 不要)
- [ ] Docker Desktop → `Settings > General` で **Use the WSL 2 based engine** を OFF、`Resources > Advanced` で 4 CPU / 8 GB RAM 以上を割り当て
- [ ] 管理者 PowerShell 7 を開き `Set-ExecutionPolicy -Scope Process RemoteSigned` を実行
- [ ] `python --version` / `pip --version` が 3.11 以上であることを確認し、必要なら Microsoft Store 版を更新
- [ ] `Set-Location D:\todo-manage; git status` で余計な変更が無いことを確認

## 2. Skill / Agent 配置 (AI が迷わないよう事前に同期)
- [ ] [docs/windows-skill-setup.md](docs/windows-skill-setup.md) のスクリプトを実行し、`todo-api` と `todo-api-client-sample` に `.claude\skills` を複製
- [ ] 同ドキュメントの手順で両プロジェクトに `AGENTS.md` を上書きコピー
- [ ] Claude Code で `Claude > Skills > Refresh` を行い、4 Skill が表示されているスクリーンショットを取得 (証跡保存)

## 3. サーバー (todo-api) 起動と検証
- [ ] `Set-Location D:\todo-manage\todo-api`
- [ ] `Copy-Item env.example .env -Force` を実行し、必要なら `.env` を編集
- [ ] `New-Item -ItemType Directory -Force ..\logs | Out-Null` でログ保存用ディレクトリを準備
- [ ] `docker compose up -d` → `docker compose ps` で `todo-api` が `running`
- [ ] `docker compose logs -f todo-api` を 60 秒追跡し、エラーが無いことを確認 (必要なら `logs/server-start.log` に保存)
- [ ] ヘルスチェック
  ```powershell
  Invoke-RestMethod http://localhost:8000/
  ```
- [ ] 要件作成と ID の保持
  ```powershell
  $Requirement = Invoke-RestMethod `
    -Uri http://localhost:8000/tasks/requirements/ `
    -Method Post `
    -ContentType 'application/json' `
    -Body (@{ title = 'Windows検証用要件'; description = 'Hyper-V backend' } | ConvertTo-Json)
  $Requirement.id | Tee-Object -FilePath ..\logs\requirement_id.txt
  ```
- [ ] タスク作成 (上記 `$Requirement.id` を使用)
  ```powershell
  $Task = Invoke-RestMethod `
    -Uri http://localhost:8000/tasks/ `
    -Method Post `
    -ContentType 'application/json' `
    -Body (@{ title = 'Windowsタスク'; type = 'task'; parent_id = $Requirement.id } | ConvertTo-Json)
  ```
- [ ] `docker compose exec todo-api python -m pytest tests -v` を実行し、成功ログを `..\logs\pytest.log` に保存

## 4. クライアント (todo-api-client-sample) 操作
- [ ] `Set-Location D:\todo-manage\todo-api-client-sample`
- [ ] 環境変数を設定し PowerShell だけで実行
  ```powershell
  $Env:API_URL = 'http://localhost:8000'
  python -m venv .venv
  .\.venv\Scripts\Activate.ps1
  pip install -r requirements.txt
  ```
- [ ] ヘルス＆一覧
  ```powershell
  python client.py health | Tee-Object ..\logs\client-health.log
  python client.py list --status in_progress --limit 5 | Tee-Object ..\logs\client-list.log
  ```
- [ ] クライアント経由で要件/タスクを追加し、ID を確認
  ```powershell
  $Req = python client.py req-create --title "Win要件" --desc "PowerShell"
  $Task = python client.py task-create --title "Win子タスク" --parent $($Requirement.id) --type task
  ```
  > `$Requirement.id` が手元に無い場合は `Get-Content ..\logs\requirement_id.txt` で参照
- [ ] `Invoke-RestMethod "$Env:API_URL/tasks/" -Method Get` でクライアント追加分がサーバーに反映されていることを確認

## 5. Claude Skill 確認
- [ ] Claude Code で `api.task-listing.minimal-v1` を呼び出し、最新タスク一覧が返るログを取得
- [ ] `architecture.id-allocation.counters-v1` に採番ルールを質問し、回答を `logs/review-notes.md` に記録
- [ ] `ops.review.evidence-v1` でレビュー観点を表示し、同じファイルに貼り付け
- [ ] `tdd.red-case.write-v1` から RED ケース例を生成し、生成ファイルまたはチャットログを保存

## 6. 証跡整理
- [ ] `New-Item -ItemType Directory -Force ..\logs | Out-Null` を実行済みか確認し、以下が揃っているか点検
  - server-start.log / pytest.log / requirement_id.txt / client-health.log / client-list.log / review-notes.md
- [ ] スクリーンショットとログを共有ドライブへアップロード

## 7. 異常系と後片付け
- [ ] [docs/windows-port-block-test.md](docs/windows-port-block-test.md) の手順で `netsh interface portproxy add ...` を実行し、ポート競合を再現 → ログ保存
- [ ] 同ドキュメントの削除手順で portproxy を解除
- [ ] `Set-Location D:\todo-manage\todo-api; docker compose down -v`
- [ ] `Set-Location ..\todo-api-client-sample; Remove-Item -Recurse -Force .\.venv`
- [ ] 不要な `.claude\skills` コピーを削除し、`git status` でクリーンであることを確認

---

### 記録欄
- 実施日:
- 実施者:
- 所見:
