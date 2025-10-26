# macOS 向け Skill / Agent 複製手順

`todo-api-skills` に含まれる 4 つの Skill と `AGENTS.md` を macOS 環境で `todo-api` / `todo-api-client-sample` にコピーするための手順です。`~/workspace/todo-manage` に本リポジトリを置いている想定ですが、別のパスでも変数を書き換えれば利用できます。

## 1. コピー対象
- `api.task-listing.minimal-v1`
- `architecture.id-allocation.counters-v1`
- `ops.review.evidence-v1`
- `tdd.red-case.write-v1`
- `AGENTS.md`

## 2. todo-api への配置
```bash
ROOT="$HOME/workspace/todo-manage"
API="$ROOT/todo-api"
SKILLS="$ROOT/todo-api-skills"
TARGET="$API/.claude/skills"

mkdir -p "$TARGET"

for SKILL in \
  api.task-listing.minimal-v1 \
  architecture.id-allocation.counters-v1 \
  ops.review.evidence-v1 \
  tdd.red-case.write-v1; do
  rsync -a "$SKILLS/$SKILL/" "$TARGET/$SKILL/"
done

cp "$SKILLS/AGENTS.md" "$API/AGENTS.md"
```

## 3. todo-api-client-sample への配置
```bash
CLIENT="$ROOT/todo-api-client-sample"
TARGET="$CLIENT/.claude/skills"

mkdir -p "$TARGET"

for SKILL in \
  api.task-listing.minimal-v1 \
  architecture.id-allocation.counters-v1 \
  ops.review.evidence-v1 \
  tdd.red-case.write-v1; do
  rsync -a "$SKILLS/$SKILL/" "$TARGET/$SKILL/"
done

cp "$SKILLS/AGENTS.md" "$CLIENT/AGENTS.md"
```

## 4. Claude Code / Codex CLI での確認
1. VS Code + Claude Code を対象プロジェクトで開き、`Claude: Refresh Skills` を実行。
2. `Claude > Skills` タブで 4 Skill が表示されることを確認。
3. Codex CLI では各プロジェクト直下にコピーした `AGENTS.md` が参照されるため、必要に応じて内容を編集してエージェントに指示を追加する。

## 5. トラブルシューティング
- `rsync` が未インストールの場合は `cp -R` でも代用可能（例: `cp -R "$SKILLS/$SKILL" "$TARGET/"`）。
- `AGENTS.md` を独自に調整している場合はコピー前にバックアップし、必要に応じてマージを実施。
- Skill を更新したいときは `.claude/skills` 配下の該当ディレクトリを削除してから再度コピーする。
