# Windowsネイティブ向け機能充足検証チェックリスト

PowerShell 7 + Docker Desktop (Hyper-V backend / WSL 2 backend) だけで todo-api サーバーと todo-api-client-sample クライアントを検証するためのタスク一覧です。各ステップは下記補助ドキュメントを参照しながら実施してください。

## 0. 参照ドキュメント
- [todo-api/README.windows.md](todo-api/README.windows.md)
- [todo-api-client-sample/README.windows.md](todo-api-client-sample/README.windows.md)
- [todo-api-skills/README.windows.md](todo-api-skills/README.windows.md)
- [docs/windows-skill-setup.md](docs/windows-skill-setup.md)
- [docs/windows-port-block-test.md](docs/windows-port-block-test.md)

---

## 1. 事前準備 (Windows ネイティブ)
- [ ] Windows Update 後に再起動し、`Turn Windows features on or off` で **Hyper-V** と **Containers** を ON (WSL 不要)
- [ ] Docker Desktop → `Settings > General` の **Use the WSL 2 based engine** は ON / OFF どちらでも可（Hyper-V backend / WSL 2 backend の双方で todo-api が動作することを確認済み）。いずれの場合も `Resources > Advanced` で 4 CPU / 8 GB RAM 以上を割り当て
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

### 重要: 新しい Claude Code セッションで実行してください

**前提条件:**
- [ ] サーバー (todo-api) が起動中であること (`docker compose ps` で確認)
- [ ] todo-api-client-sample ディレクトリで新しい Claude Code セッションを開始すること

```powershell
# 新しいターミナルで実行
Set-Location D:\todo-manage\todo-api-client-sample
# ここで Claude Code を起動
```

---

### 5.1 Skill の表示確認
- [ ] Claude Code の UI で `Claude > Skills > Refresh` を実行
- [ ] 以下の4つの Skill が表示されることを確認:
  - api.task-listing.minimal-v1
  - architecture.id-allocation.counters-v1
  - ops.review.evidence-v1
  - tdd.red-case.write-v1
- [ ] スクリーンショットを `logs/skills-list.png` として保存

---

### 5.2 api.task-listing.minimal-v1 の動作確認

**Claude Code への依頼プロンプト:**
```
/skill api.task-listing.minimal-v1

API_URL=http://localhost:8000 で、現在登録されているタスクの一覧を
hid, title, status, updated_at のフィールドに絞って取得してください。
結果をログファイルに保存してください。
```

**期待する結果:**
- [ ] Skill が正常に呼び出される
- [ ] `GET http://localhost:8000/tasks?fields=hid,title,status,updated_at` が実行される
- [ ] 4件のタスク (REQ-001, REQ-001.TSK-001, REQ-002, REQ-001.TSK-002) が軽量フォーマットで返される
- [ ] 結果が `logs/skill-task-listing.log` などに保存される

---

### 5.3 architecture.id-allocation.counters-v1 の動作確認

**Claude Code への依頼プロンプト:**
```
/skill architecture.id-allocation.counters-v1

todo-api の階層的ID採番ルール (REQ-001, REQ-001.TSK-001 など) について、
counters テーブルを使った競合安全な採番方式を説明してください。
特に以下の点を明確にしてください:
1. scope の設定方法
2. トランザクションでの SELECT FOR UPDATE の役割
3. ユニーク制約違反時のリトライ戦略

回答を logs/review-notes.md に追記してください。
```

**期待する結果:**
- [ ] Skill が正常に呼び出される
- [ ] 階層的ID採番の仕組みが説明される:
  - scope 例: `REQ`, `REQ-001.TSK`, `REQ-001.TSK-001.SUB`
  - `SELECT last FROM counters WHERE scope=:scope FOR UPDATE`
  - `UPDATE counters SET last=last+1`
  - 指数バックオフによるリトライ
- [ ] 説明が `logs/review-notes.md` に追記される

---

### 5.4 ops.review.evidence-v1 の動作確認

**Claude Code への依頼プロンプト:**
```
/skill ops.review.evidence-v1

コードレビューで指摘された修正内容を、CAS (Content-Addressable Storage) に
保存してタスクにリンクする手順を説明してください。

以下のシナリオで具体例を示してください:
- REQ-001.TSK-001 のレビュー指摘に対する修正パッチ
- 修正後のテスト実行ログ

回答を logs/review-notes.md に追記してください。
```

**期待する結果:**
- [ ] Skill が正常に呼び出される
- [ ] レビュー証跡管理の手順が説明される:
  1. 差分パッチを CAS に保存
  2. `POST /tasks/{hid}/links` で `role:"patch"` を付与してリンク
  3. テストログを CAS に保存
  4. `role:"log"` でリンク
- [ ] 再現性と追跡可能性のメリットが説明される
- [ ] 説明が `logs/review-notes.md` に追記される

---

### 5.5 tdd.red-case.write-v1 の動作確認

**Claude Code への依頼プロンプト:**
```
/skill tdd.red-case.write-v1

todo-api で「タスク作成時に parent_id が存在しない場合は 404 エラーを返す」
という受入条件に対する、最小の RED テストケースを作成してください。

以下の制約を守ってください:
- 失敗するテストを1つだけ作成 (複数の失敗要因を同時に作らない)
- pytest 形式で記述
- ファイル名は test_task_invalid_parent.py

作成したテストファイルを logs/ ディレクトリに保存してください。
```

**期待する結果:**
- [ ] Skill が正常に呼び出される
- [ ] RED テストケースが生成される:
  ```python
  def test_task_creation_with_invalid_parent_id():
      """存在しない parent_id を指定した場合、404 を返すこと"""
      response = client.post("/tasks/", json={
          "title": "Invalid Parent Task",
          "type": "task",
          "parent_id": 99999  # 存在しない
      })
      assert response.status_code == 404
  ```
- [ ] TDD の RED→GREEN→REFACTOR サイクルが説明される
- [ ] テストファイルが `logs/test_task_invalid_parent.py` として保存される

---

### 5.6 Skill 検証の証跡保存
- [ ] 各 Skill 実行時のチャットログをスクリーンショットまたはテキストで保存
- [ ] `logs/review-notes.md` に全 Skill の動作確認結果が記録されていることを確認
- [ ] `logs/` ディレクトリに以下のファイルが揃っていることを確認:
  - skills-list.png (または .jpg)
  - skill-task-listing.log
  - review-notes.md (5.3, 5.4 の追記を含む)
  - test_task_invalid_parent.py (5.5 の生成ファイル)

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
