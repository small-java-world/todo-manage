# todo-api-skills (Windows向け活用ガイド)

Claude Skills と Codex CLI 用 `AGENTS.md` を Windows で扱う際の手順をまとめています。macOS/Linux 向けは既存の `README.md` / `CLAUDE_SKILLS_SETUP.md` を参照してください。

---

## 0. 前提
- Windows 11 + PowerShell 7 以上
- Claude Code, Claude Web, Codex CLI のいずれかを利用できる環境
- `todo-api` / `todo-api-client-sample` リポジトリと同じドライブ (例: `D:\\todo-manage`)
- Git / 7-Zip (任意: ZIP 作成が必要な場合)

## 1. プロジェクト単位で Skill をコピー
```powershell
$ROOT   = "D:\\todo-manage"
$SKILLS = Join-Path $ROOT "todo-api-skills"
$API    = Join-Path $ROOT "todo-api"
$TARGET = Join-Path $API ".claude\\skills"

New-Item -ItemType Directory -Force $TARGET | Out-Null

"api.task-listing.minimal-v1",
"architecture.id-allocation.counters-v1",
"ops.review.evidence-v1",
"tdd.red-case.write-v1" | ForEach-Object {
    Copy-Item -Recurse -Force (Join-Path $SKILLS $_) $TARGET
}

Copy-Item -Force (Join-Path $SKILLS "AGENTS.md") (Join-Path $API "AGENTS.md")
```
`todo-api-client-sample` にも同様のコマンドでコピーすれば、Claude Code から両方のプロジェクトで Skill が利用できます。

## 2. グローバル Skill キャッシュ `%UserProfile%\\.claude\\skills`
```powershell
$GlobalSkills = Join-Path $Env:USERPROFILE ".claude\\skills"
New-Item -ItemType Directory -Force $GlobalSkills | Out-Null

Get-ChildItem -Directory $SKILLS -Filter "*.*-v1" | ForEach-Object {
    Copy-Item -Recurse -Force $_.FullName $GlobalSkills
}
```
グローバルに配置すると新規リポジトリでも同じ Skill を即座に再利用できます。プロジェクト固有で上書きしたい場合は `.claude/skills` 側が優先されます。

## 3. Codex CLI 用 `AGENTS.md`
- `todo-api` や `todo-api-client-sample` に `AGENTS.md` をコピーすると、Codex CLI から Skill と連動したエージェント定義を利用できます。
- プロジェクトごとに調整したい場合はコピー後に `name`, `description`, `skills` セクションを編集してください。
- 既存の `AGENTS.md` を残したい場合はファイル名を変更するか、Git で差分を確認したうえでマージします。

## 4. Claude Code / Claude Web での確認
### 4.1 Claude Code (VS Code 拡張)
1. プロジェクトを開く
2. `Claude > Skills` パネルで 4 つの Skill が読み込まれていることを確認
3. 必要に応じて Skill ごとの `examples/` を参照

### 4.2 Claude Web (ZIP アップロード)
```powershell
Compress-Archive -Path (Join-Path $SKILLS "api.task-listing.minimal-v1") \
    -DestinationPath (Join-Path $SKILLS "api.task-listing.minimal-v1.zip") -Force
```
生成した ZIP を Claude Web の Settings > Capabilities > Skills から Upload すると、ブラウザ版でも同じ Skill を利用できます。

## 5. ディレクトリ概要
```
todo-api-skills
├─ api.task-listing.minimal-v1/
├─ architecture.id-allocation.counters-v1/
├─ ops.review.evidence-v1/
├─ tdd.red-case.write-v1/
├─ AGENTS.md
├─ CLAUDE_SKILLS_SETUP.md
├─ README.md (mac / Linux 向け)
└─ README.windows.md (本書)
```

## 6. よくある質問 / Tips
- Windows で symlink が作れない場合でも、上記 `Copy-Item` でフォルダーごと複製すれば問題ありません。
- PowerShell の実行ポリシーで `Copy-Item` が止まる場合は `Set-ExecutionPolicy -Scope Process RemoteSigned` を一時的に実行してください。
- Skill のバージョンを更新したら、コピー先を削除 (`Remove-Item -Recurse`) してから再コピーするとキャッシュが残りません。
- `CLAUDE_SKILLS_SETUP.md` には Skill の詳細説明や検証コマンドがまとまっています。Windows でもコマンド自体は同じなので、必要に応じて `bash` ではなく PowerShell に読み替えてください。

最終更新: 2025-10-24
