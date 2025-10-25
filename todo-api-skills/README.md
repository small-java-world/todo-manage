# API 利用プロジェクト向け配布物 — Claude Skills + Codex CLI AGENTS

このリポジトリは「APIを利用するプロジェクト」向けに、以下の“取り込み用ファイル”を提供します。

- Claude Code用の Skills フォルダ群（`SKILL.md` を含む）
- Codex CLI 向けの `AGENTS.md`（運用ルールの雛形）

利用側プロジェクトは、本リポのファイルを取り込むだけで、Claude Skills と Codex CLI の運用ルールをすぐ適用できます。

---

## 📦 同梱物（取り込み対象）

- `AGENTS.md`（本リポ直下）
  - Codex CLI 向けの運用ルール。各 Skill はフォルダ直下に `SKILL.md`、YAML frontmatter の `name` / `description` 必須、配布はフォルダZIPアップロード or プロジェクト直下配置など。

- Claude Skills（各フォルダに `SKILL.md` と `examples/`）
  - `api.task-listing.minimal-v1/SKILL.md`
  - `architecture.id-allocation.counters-v1/SKILL.md`
  - `ops.review.evidence-v1/SKILL.md`
  - `tdd.red-case.write-v1/SKILL.md`

- セットアップ補助
  - `CLAUDE_SKILLS_SETUP.md`（Claude Code での読み込み・確認・トラブルシュート手順）

本リポ自体は API サーバ実装を含みません。APIを“利用する側”のプロジェクトが、上記ファイルを取り込んで使う前提です。

---

## 🚀 取り込み方法（利用側プロジェクト）

### 1) Claude Code（プロジェクトスコープ）
- 利用側プロジェクトのルートに Skills を配置：
  - `mkdir -p <your-repo>/.claude/skills/`
  - 本リポの任意の Skill フォルダ（例: `api.task-listing.minimal-v1/`）を `<your-repo>/.claude/skills/` 配下へコピーし、必要に応じてフォルダ名をスキル名に調整（例: `<your-repo>/.claude/skills/api.task-listing.minimal-v1/`）。
- Claude Code を再起動し、`/skills` で読み込み確認。

【ローカル例（この環境）】API リポが `~/workspace/todoapi/todo-api` の場合

```bash
# スキル配置先を作成
mkdir -p /Users/f.kawano/workspace/todoapi/todo-api/.claude/skills

# 本リポのSkillをコピー（必要なものだけでもOK）
cp -R api.task-listing.minimal-v1               /Users/f.kawano/workspace/todoapi/todo-api/.claude/skills/
cp -R architecture.id-allocation.counters-v1    /Users/f.kawano/workspace/todoapi/todo-api/.claude/skills/
cp -R ops.review.evidence-v1                    /Users/f.kawano/workspace/todoapi/todo-api/.claude/skills/
cp -R tdd.red-case.write-v1                     /Users/f.kawano/workspace/todoapi/todo-api/.claude/skills/

# Codex CLI の運用規約をAPIリポにも適用したい場合
cp AGENTS.md /Users/f.kawano/workspace/todoapi/todo-api/AGENTS.md

# Claude Code を再起動 → /skills で確認
```

### 2) Claude Web（ZIP アップロード）
- 取り込みたい Skill フォルダを ZIP 化し、Claude（Web）の Settings > Capabilities > Skills で Upload。
- 複数のプロジェクトで共通利用したい場合に便利。

### 3) Codex CLI（AGENTS.md）
- 利用側プロジェクト直下に本リポの `AGENTS.md` を配置（既存の AGENTS.md がある場合は内容を統合）。
- `AGENTS.md` のスコープはファイルを置いたディレクトリ配下一式です。より細かい運用をしたい場合は、必要なサブディレクトリに別の `AGENTS.md` を配置してください（深い階層が優先）。

---

## 🧭 使い分けの指針

- Claude Skills
  - 技術知識・API仕様・運用パターンなど“長文知識”を `SKILL.md` に集約し、関連する時だけ遅延ロードさせます。
  - どの質問で使われるかを明確にするため、`SKILL.md` の `description` を具体的に（キーワード含む）。

- Codex CLI の `AGENTS.md`
  - Skills の配置ルール、段階的読解、ZIP配布といった“運用規約”を明文化。リポに置くと、CLIエージェントがその方針に従います。

---

## 🔗 主要ファイル（リンク）

- `AGENTS.md`
- `CLAUDE_SKILLS_SETUP.md`
- `api.task-listing.minimal-v1/SKILL.md`
- `architecture.id-allocation.counters-v1/SKILL.md`
- `ops.review.evidence-v1/SKILL.md`
- `tdd.red-case.write-v1/SKILL.md`

---

## 🧪 動作確認（Claude Code）

- `/skills` でスキル一覧に取り込んだ Skill が出るか確認。
- 例の質問
  - 「階層IDの形式を教えて」→ `architecture.id-allocation.counters-v1` が参照される想定
  - 「最小のタスク一覧取得をしたい」→ `api.task-listing.minimal-v1`
  - 「レビュー解決の証跡をどう残す？」→ `ops.review.evidence-v1`
  - 「TDDのREDケースだけ先に書きたい」→ `tdd.red-case.write-v1`

詳細手順は `CLAUDE_SKILLS_SETUP.md` を参照してください。

---

## 📁 本リポの実際の構成（抜粋）

```
.
├── AGENTS.md
├── CLAUDE_SKILLS_SETUP.md
├── README.md
├── .claude/
│   └── settings.local.json
├── api.task-listing.minimal-v1/
│   ├── SKILL.md
│   └── examples/
├── architecture.id-allocation.counters-v1/
│   ├── SKILL.md
│   └── examples/
├── ops.review.evidence-v1/
│   ├── SKILL.md
│   └── examples/
└── tdd.red-case.write-v1/
    ├── SKILL.md
    └── examples/
```

---

## ❓FAQ / 注意事項

- 本リポは「提供側」です。APIサーバ実装・テストスクリプトは含みません（利用側のAPIプロジェクトに取り込んで活用）。
- `SKILL.md` は UTF-8、先頭に YAML frontmatter（`name` / `description` 必須）。
- Skills はプロジェクト配下に置くと、そのプロジェクト内でのみ有効（`~/.claude/skills/` に置くと全プロジェクトで有効）。

---

## 🗓 バージョン

- 現在版: 2025-10-24（README 改訂: 配布物リポとしての目的を明記）
