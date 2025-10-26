# AGENTS.md — Claude Skills 準拠の運用

## 基本構造
- 各 Skill は **フォルダ直下に `SKILL.md`** を置く（YAML frontmatter の `name` / `description` 必須）
- 関連ファイルは `examples/` サブディレクトリに配置
- スキル名は `category.functionality.version` 形式で命名

## 段階的開示（Progressive Disclosure）
1. **インデックス段階**: Claudeは最初にスキル名と説明文のみを読み込み
2. **起動段階**: 関連性が高いと判断した場合のみ `SKILL.md` 本体を読み込み
3. **深掘り段階**: 必要に応じて `examples/` 内のファイルやスクリプトを実行

## 実行環境別の使い分け
- **API環境**: セキュリティ重視、外部通信不可、プリインストールライブラリのみ
- **Web環境**: 実験・プロトタイピング、外部API利用可能、動的パッケージインストール可能
- **ローカル環境**: 開発者環境、最大限の柔軟性、制約なし

## 配布方法
- **Claude Code**: プロジェクト直下の `.claude/skills/` に配置
- **Claude Web**: フォルダをZIP化して Settings > Capabilities > Skills でアップロード
- **Codex CLI**: プロジェクト直下に `AGENTS.md` を配置

## スキル作成ガイドライン
- `description` は具体的なキーワードを含めて関連性を明確化
- 手順は段階的に、実行可能なコード例を必ず含める
- 大きなファイルはURI参照に留め、必要時のみ取得
- 再現性を重視し、属人化を避ける
