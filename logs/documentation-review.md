# ドキュメントレビュー: Skills配置の問題

## 確認したドキュメント

1. `D:\todo-manage\README.md`
2. `D:\todo-manage\todo-api-skills\README.md`
3. `D:\todo-manage\todo-api-skills\README.windows.md`
4. `D:\todo-manage\todo-api-skills\CLAUDE_SKILLS_SETUP.md`
5. 各Skillの `SKILL.md`

---

## 問題点の分析

### 1. README.md (ルート)

**記載内容:**
```bash
# Skills のプロジェクトスコープ配置
mkdir -p /Users/f.kawano/workspace/todo-manage/todo-api/.claude/skills
cp -R /Users/f.kawano/workspace/todo-manage/todo-api-skills/api.task-listing.minimal-v1            /Users/f.kawano/workspace/todo-manage/todo-api/.claude/skills/
cp -R /Users/f.kawano/workspace/todo-manage/todo-api-skills/architecture.id-allocation.counters-v1 /Users/f.kawano/workspace/todo-manage/todo-api/.claude/skills/
cp -R /Users/f.kawano/workspace/todo-manage/todo-api-skills/ops.review.evidence-v1                 /Users/f.kawano/workspace/todo-manage/todo-api/.claude/skills/
cp -R /Users/f.kawano/workspace/todo-manage/todo-api-skills/tdd.red-case.write-v1                  /Users/f.kawano/workspace/todo-manage/todo-api/.claude/skills/
```

**判定:** ✅ **todo-api のみ** への配置を指示（正しい）

**問題:** クライアント側への言及が一切ない

---

### 2. todo-api-skills/README.md

**記載内容:**
```bash
# スキル配置先を作成
mkdir -p /Users/f.kawano/workspace/todoapi/todo-api/.claude/skills

# 本リポのSkillをコピー（必要なものだけでもOK）
cp -R api.task-listing.minimal-v1               /Users/f.kawano/workspace/todoapi/todo-api/.claude/skills/
cp -R architecture.id-allocation.counters-v1    /Users/f.kawano/workspace/todoapi/todo-api/.claude/skills/
cp -R ops.review.evidence-v1                    /Users/f.kawano/workspace/todoapi/todo-api/.claude/skills/
cp -R tdd.red-case.write-v1                     /Users/f.kawano/workspace/todoapi/todo-api/.claude/skills/
```

**判定:** ✅ **todo-api のみ** への配置を指示（正しい）

**補足:** 「必要なものだけでもOK」と書かれているが、どれが必要かの説明なし

---

### 3. todo-api-skills/README.windows.md ⚠️ **問題の元凶**

**31行目の記載:**
> `todo-api-client-sample` にも同様のコマンドでコピーすれば、Claude Code から両方のプロジェクトで Skill が利用できます。

**問題点:**
1. ❌ **曖昧な書き方**
   - 「同様のコマンド」= 全てコピーすると誤解される
   - どのSkillが必要かの説明が一切ない

2. ❌ **理由の説明なし**
   - なぜクライアント側にもコピーするのか
   - どのSkillがクライアント側で使われるのか
   - 全て不明

3. ❌ **判断基準の欠如**
   - サーバー専用Skillとクライアント用Skillの区別なし

**この1行が、setup-skills.ps1で「全部コピー」する原因になった**

---

### 4. CLAUDE_SKILLS_SETUP.md

**クライアントへの言及:** なし

---

### 5. 各SkillのSKILL.md

**対象プロジェクトの記載:**
```bash
$ grep -r "server\|client\|サーバー\|クライアント" *.md
該当なし
```

**問題:**
- どのSkillがどのプロジェクト向けか一切書かれていない
- 利用者は全てコピーするしかない

---

## ドキュメント不備の整理

### ❌ 記載されていないこと

1. **どのSkillがどのプロジェクトに必要か**
   - サーバー専用: architecture.id-allocation.counters-v1, ops.review.evidence-v1, tdd.red-case.write-v1
   - クライアント用: api.task-listing.minimal-v1
   - 共通: なし

2. **なぜクライアント側にSkillsをコピーするのか**
   - 理由の説明なし
   - 「同様のコマンドでコピーすれば」としか書かれていない

3. **Skillsの選択基準**
   - 「必要なものだけでもOK」と書かれているが、判断基準なし

### ✅ 唯一明確なこと

- todo-api（サーバー側）には全てのSkillsをコピーする

---

## setup-skills.ps1 が生まれた経緯

**README.windows.md 31行目:**
> `todo-api-client-sample` にも同様のコマンドでコピーすれば

この曖昧な記述を見た誰かが:
```powershell
# サーバー側と同じリストをコピー
"api.task-listing.minimal-v1",
"architecture.id-allocation.counters-v1",
"ops.review.evidence-v1",
"tdd.red-case.write-v1" | ForEach-Object {
    Copy-Item ...
}
```

と解釈して、**全部コピーするスクリプトを作成した**

---

## 正しいドキュメントあるべき姿

### README.windows.md の修正案

**現状（31行目）:**
> `todo-api-client-sample` にも同様のコマンドでコピーすれば、Claude Code から両方のプロジェクトで Skill が利用できます。

**修正後:**
```markdown
## todo-api-client-sample への配置

クライアント側では、API呼び出しに関するSkillのみ必要です:

```powershell
$CLIENT = Join-Path $ROOT "todo-api-client-sample"
$TARGET = Join-Path $CLIENT ".claude\\skills"

New-Item -ItemType Directory -Force $TARGET | Out-Null

# クライアント側で必要なSkillのみコピー
"api.task-listing.minimal-v1" | ForEach-Object {
    Copy-Item -Recurse -Force (Join-Path $SKILLS $_) $TARGET
}
```

**なぜこれだけ？**
- `api.task-listing.minimal-v1`: クライアントがAPIを呼び出すために必要
- `architecture.id-allocation.counters-v1`: サーバー側のDB設計なので不要
- `ops.review.evidence-v1`: サーバー側のCAS管理なので不要
- `tdd.red-case.write-v1`: サーバー側のテスト開発なので不要
```

### 各SKILL.mdに追加すべき情報

**architecture.id-allocation.counters-v1/SKILL.md:**
```markdown
---
name: 階層IDの競合安全な採番（counters 方式）
description: ...
target: server  # 追加: サーバー専用
---
```

**api.task-listing.minimal-v1/SKILL.md:**
```markdown
---
name: タスク一覧の軽量取得（段階取得の前段）
description: ...
target: client, server  # 追加: クライアント・サーバー共通
---
```

---

## まとめ

### 問題の根本原因

1. **ドキュメント不備**
   - どのSkillがどのプロジェクトに必要か明記されていない
   - README.windows.mdの曖昧な記述（31行目）

2. **設計の不明確さ**
   - サーバー専用Skillとクライアント用Skillの区別がない
   - 判断基準が示されていない

3. **スクリプトの問題**
   - setup-skills.ps1が「全部コピー」している
   - ドキュメント不備を鵜呑みにした結果

### 修正が必要なファイル

1. ✅ `README.windows.md` - 31行目を具体的に書き直す
2. ✅ `setup-skills.ps1` - クライアント側は api.task-listing.minimal-v1 のみコピー
3. ✅ 各`SKILL.md` - `target: server` または `target: client` を追加
4. ✅ `WINDOWS_VERIFICATION_CHECKLIST.md` - Skills配置の理由を追記

---

## 結論

**ユーザーの疑問:**
> architecture.id-allocation.counters-v1\examples\id_alloc.sql ってクライアントに必要なの？？

**答え:**
- ❌ 完全に不要です
- ❌ 他に2つも不要なものがあります（ops.review.evidence-v1, tdd.red-case.write-v1）
- ✅ クライアント側に必要なのは api.task-listing.minimal-v1 のみです

**問題の原因:**
- **ドキュメント不備**（特にREADME.windows.md 31行目の曖昧な記述）
- それを鵜呑みにした setup-skills.ps1 の設計ミス

**ユーザーの鋭い指摘により、ドキュメント・スクリプト両方の問題が明らかになりました。**
