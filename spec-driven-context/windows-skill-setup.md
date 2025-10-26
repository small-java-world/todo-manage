# Windows向け Skill / Agent 配置手順

`todo-api-skills` に含まれる 4 つの Skill と `AGENTS.md` を Windows ネイティブ環境で複製するための具体的な PowerShell コマンドです。`D:\todo-manage` をルートとした構成を前提にしています。

## 1. コピー対象
- `api.task-listing.minimal-v1`
- `architecture.id-allocation.counters-v1`
- `ops.review.evidence-v1`
- `tdd.red-case.write-v1`
- `AGENTS.md`

## 2. todo-api への配置
```powershell
$ROOT   = "D:\todo-manage"
$API    = Join-Path $ROOT "todo-api"
$SKILLS = Join-Path $ROOT "todo-api-skills"
$TARGET = Join-Path $API  ".claude\skills"

New-Item -ItemType Directory -Force $TARGET | Out-Null

"api.task-listing.minimal-v1",
"architecture.id-allocation.counters-v1",
"ops.review.evidence-v1",
"tdd.red-case.write-v1" | ForEach-Object {
    Copy-Item -Recurse -Force (Join-Path $SKILLS $_) $TARGET
}

Copy-Item -Force (Join-Path $SKILLS "AGENTS.md") (Join-Path $API "AGENTS.md")
```

## 3. todo-api-client-sample への配置
```powershell
$CLIENT = Join-Path $ROOT "todo-api-client-sample"
$TARGET = Join-Path $CLIENT ".claude\skills"

New-Item -ItemType Directory -Force $TARGET | Out-Null

"api.task-listing.minimal-v1",
"architecture.id-allocation.counters-v1",
"ops.review.evidence-v1",
"tdd.red-case.write-v1" | ForEach-Object {
    Copy-Item -Recurse -Force (Join-Path $SKILLS $_) $TARGET
}

Copy-Item -Force (Join-Path $SKILLS "AGENTS.md") (Join-Path $CLIENT "AGENTS.md")
```

## 4. Claude Code での確認
1. VS Code + Claude Code 拡張で対象プロジェクトを開く
2. コマンドパレットで `Claude: Refresh Skills` を実行
3. `Claude` パネル → `Skills` タブで 4 Skill が Listed 状態であることを確認 (スクリーンショットを取得)

## 5. トラブルシューティング
- `Copy-Item` でアクセス拒否が出た場合は PowerShell を管理者で実行
- Skill を更新したい場合は `.claude\skills` ごと削除してから再コピー
- プロジェクト固有の `AGENTS.md` を保護したい場合はコミット前に差分を確認
