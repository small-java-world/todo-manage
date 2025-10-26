# todo-manage — TODO API + Claude Skills ワークスペース

このディレクトリは、API実装と、そのAPIを活用するClaude Skillsをまとめた“運用用ワークスペース”です。

- `todo-api` — FastAPI ベースの TODO API 本体
- `todo-api-skills` — Claude Skills と Codex CLI 向け `AGENTS.md`

OS ごとの Skill / Agent 複製手順:
- macOS: [docs/macos-skill-setup.md](docs/macos-skill-setup.md)
- Windows: [docs/windows-skill-setup.md](docs/windows-skill-setup.md)

---

## セットアップ（最短）

1) Skills を API プロジェクトに反映

```bash
# Skills のプロジェクトスコープ配置
mkdir -p /Users/f.kawano/workspace/todo-manage/todo-api/.claude/skills
cp -R /Users/f.kawano/workspace/todo-manage/todo-api-skills/api.task-listing.minimal-v1            /Users/f.kawano/workspace/todo-manage/todo-api/.claude/skills/
cp -R /Users/f.kawano/workspace/todo-manage/todo-api-skills/architecture.id-allocation.counters-v1 /Users/f.kawano/workspace/todo-manage/todo-api/.claude/skills/
cp -R /Users/f.kawano/workspace/todo-manage/todo-api-skills/ops.review.evidence-v1                 /Users/f.kawano/workspace/todo-manage/todo-api/.claude/skills/
cp -R /Users/f.kawano/workspace/todo-manage/todo-api-skills/tdd.red-case.write-v1                  /Users/f.kawano/workspace/todo-manage/todo-api/.claude/skills/

# Codex CLI の運用規約も適用（任意）
cp /Users/f.kawano/workspace/todo-manage/todo-api-skills/AGENTS.md /Users/f.kawano/workspace/todo-manage/todo-api/AGENTS.md
```

2) API を起動

```bash
cd /Users/f.kawano/workspace/todo-manage/todo-api
# Docker Compose 例（README参照）
docker-compose up -d
# あるいはローカル実行
python -m uvicorn app.main:app --reload
```

3) Claude Code で確認

- プロジェクトを `todo-api` で開き直す → `/skills` でスキル一覧が出ることを確認
- 例の質問
  - 「階層IDの形式を教えて」 → `architecture.id-allocation.counters-v1`
  - 「最小のタスク一覧取得をしたい」 → `api.task-listing.minimal-v1`
  - 「レビュー解決の証跡をどう残す？」 → `ops.review.evidence-v1`
  - 「TDDのREDケースだけ先に書きたい」 → `tdd.red-case.write-v1`

---

## ディレクトリ構成

```
/Users/f.kawano/workspace/todo-manage
├── todo-api/          # FastAPI 実装（app/, tests/, docker-compose.yml など）
└── todo-api-skills/   # Claude Skills と Codex CLI 用 AGENTS.md（SKILL.md 含む）
```

---

## 補足

- Skills はプロジェクト配下（`.claude/skills/`）に置くと、そのプロジェクト内のみで有効です。グローバルに使う場合は `~/.claude/skills/` を使用してください。
- Skills の詳細なセットアップは `todo-api-skills/CLAUDE_SKILLS_SETUP.md` を参照してください。
- Codex CLI 運用ルールは `todo-api-skills/AGENTS.md` を参照し、必要に応じて `todo-api/AGENTS.md` にコピーして適用してください。

---

最終更新: 2025-10-24
