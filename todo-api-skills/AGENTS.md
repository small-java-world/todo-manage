# AGENTS.md — Claude Skills 準拠の運用

- 各 Skill は **フォルダ直下に `SKILL.md`** を置く（YAML frontmatter の `name` / `description` 必須）。
- モデルは関連時のみ本文や同梱ファイルを段階的に読む。大きいファイルは URI のみを示し必要時に取得。
- 配布はフォルダを ZIP 化し、Claude Settings > Capabilities > Skills でアップロード（または Claude Code のプロジェクト直下に配置）。
