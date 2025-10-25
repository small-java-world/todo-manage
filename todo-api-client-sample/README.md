# todo-api-client-sample — API + Skills 消費サンプル

このフォルダは、隣接する `todo-api`（FastAPI実装）と `todo-api-skills`（Claude Skills）を「クライアント側」から利用する最小サンプルです。

- API利用: `scripts/quick_test.sh`（curl）と `client.py`（Python）
- Skills利用: `.claude/skills/` に symlink で取り込み（Claude Code でこのフォルダを開くと自動認識）

---

## 1) 前提
- APIが起動していること（標準: http://localhost:8000）。起動は `../todo-api` の README を参照。
- macOS / Linux（Windowsの場合は WSL 推奨）

---

## 2) 使い方（最短）

### A. Bash ですぐ疎通確認
```bash
# APIのURLを指定（省略時は http://localhost:8000）
export API_URL="http://localhost:8000"

# ヘルスチェックとタスク一覧(minimal fields) を確認
bash scripts/quick_test.sh
```

### B. Python クライアントを試す
```bash
# 依存インストール（ローカル環境）
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt

# ヘルスチェック
python client.py health

# タスク一覧（最小フィールド）
python client.py list --status in_progress --limit 5
```

---

## 3) Skills の利用（Claude Code）
- このフォルダを Claude Code で開く → `/skills` で4つのSkillが表示されること。
- 例の質問
  - 「階層IDの形式を教えて」 → architecture.id-allocation.counters-v1
  - 「最小のタスク一覧取得をしたい」 → api.task-listing.minimal-v1
  - 「レビュー解決の証跡をどう残す？」 → ops.review.evidence-v1
  - 「TDDのREDケースだけ先に書きたい」 → tdd.red-case.write-v1

---

## 4) 構成
```
/Users/f.kawano/workspace/todo-manage/todo-api-client-sample
├── .claude/skills/                 # Skills（symlink）
├── scripts/quick_test.sh           # curl で疎通
├── client.py                       # Python最小クライアント
├── requirements.txt                # 依存（requests）
└── README.md
```

---

## 5) 注意
- Docker/Podman でボリュームマウントする際、symlink 先がコンテナから見えない場合があります。その場合はコピー運用に変更してください。
- `API_URL` は `http://localhost:8000` をデフォルト使用。別ホスト/ポートの場合は環境変数で上書きしてください。

最終更新: 2025-10-24
