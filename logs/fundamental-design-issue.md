# 根本的な問題: プラットフォーム非依存の設計不備

## ユーザーの指摘

> windowsだけの話じゃないよね？

**→ 完全にその通りです。**

---

## 問題の本質

### ❌ Windows固有ではなく、プロジェクト全体の設計問題

**欠けているもの:**
- どのSkillがどのプロジェクトに必要か、**設計として定義されていない**
- 全てのドキュメントで判断基準が示されていない
- 全プラットフォームで「全部コピー」が前提になっている

---

## 証拠: 全ドキュメントの横断レビュー

### 1. README.md (ルート) - macOS/Linux

```bash
cp -R .../api.task-listing.minimal-v1            .../todo-api/.claude/skills/
cp -R .../architecture.id-allocation.counters-v1 .../todo-api/.claude/skills/
cp -R .../ops.review.evidence-v1                 .../todo-api/.claude/skills/
cp -R .../tdd.red-case.write-v1                  .../todo-api/.claude/skills/
```

❌ **なぜ4つ全てが必要か** の説明なし

---

### 2. todo-api-skills/README.md - 全プラットフォーム

```bash
# 本リポのSkillをコピー（必要なものだけでもOK）
cp -R api.task-listing.minimal-v1               .../todo-api/.claude/skills/
cp -R architecture.id-allocation.counters-v1    .../todo-api/.claude/skills/
cp -R ops.review.evidence-v1                    .../todo-api/.claude/skills/
cp -R tdd.red-case.write-v1                     .../todo-api/.claude/skills/
```

❌ 「必要なものだけでもOK」と書いているが、**判断基準がない**
❌ 結局、**全部コピーする例しか提供されていない**

---

### 3. README.windows.md - Windows

> `todo-api-client-sample` にも同様のコマンドでコピーすれば

❌ 唯一クライアント側に言及しているが、**曖昧**

---

### 4. 各SKILL.md - 全プラットフォーム

```yaml
---
name: 階層IDの競合安全な採番（counters 方式）
description: ...
---
```

❌ **対象プロジェクト (server/client) の記載なし**

---

## 比較表: Windows固有 vs プロジェクト全体

| 問題 | Windows固有？ | 実際の範囲 |
|-----|------------|-----------|
| setup-skills.ps1 が全部コピー | Windows固有 | ドキュメント通りに実装しただけ |
| README.windows.md の曖昧な記述 | Windows固有 | 他のドキュメントも曖昧 |
| **Skillsの対象プロジェクトが不明** | ❌ | **✅ 全プラットフォーム** |
| **配置基準がない** | ❌ | **✅ 全プラットフォーム** |
| **「全部コピー」前提** | ❌ | **✅ 全プラットフォーム** |

---

## 根本原因

### 1. 設計ドキュメントの不在

存在しないドキュメント:
```
docs/skills-architecture.md
  - どのSkillがどのプロジェクトで使われるか
  - サーバー専用/クライアント用/共通 の定義
  - 配置基準
```

### 2. Skillsの責務が不明確

各SKILL.mdに欠けている情報:
```yaml
---
name: 階層IDの競合安全な採番（counters 方式）
description: ...
target: server  # ← これが欠けている
---
```

### 3. 「全部入り」前提の設計思想

- とりあえず全部コピーすれば動く
- 細かいことは考えない
- ユーザーが判断すべき？
- **→ 設計として破綻している**

---

## 実際に起きていること

### 全プラットフォームで同じ流れ

1. **README.md**: 全部コピー（理由不明）
2. **README.windows.md**: 「クライアントにも同様に」（曖昧）
3. **setup-skills.ps1**: 全部コピー（ドキュメント通り）
4. **WINDOWS_VERIFICATION_CHECKLIST.md**: 全部コピー（スクリプト通り）

→ **誰も「なぜ全部コピーするのか」を疑問に思わなかった**

---

## 本来あるべき姿

### 設計ドキュメント (docs/skills-architecture.md)

```markdown
# Skills アーキテクチャ

## Skillsの分類

### サーバー専用 (todo-api のみ)
- `architecture.id-allocation.counters-v1`
  - 理由: DB設計、クライアントはDBアクセスしない
- `ops.review.evidence-v1`
  - 理由: CAS内部実装、クライアントはAPIを呼ぶだけ
- `tdd.red-case.write-v1`
  - 理由: サーバー側のテスト開発

### クライアント用
- `api.task-listing.minimal-v1`
  - 理由: APIクライアント開発で使用

### 共通
- (現状なし)
```

### 各SKILL.mdに追加

```yaml
---
name: 階層IDの競合安全な採番（counters 方式）
description: ...
target: server  # 追加
reason: データベース設計、クライアントはDBに直接アクセスしない
---
```

### ドキュメント修正

**README.md:**
```bash
# サーバー側に必要なSkillsのみコピー
cp -R api.task-listing.minimal-v1               .../todo-api/.claude/skills/
cp -R architecture.id-allocation.counters-v1    .../todo-api/.claude/skills/
cp -R ops.review.evidence-v1                    .../todo-api/.claude/skills/
cp -R tdd.red-case.write-v1                     .../todo-api/.claude/skills/
```

**README.windows.md:**
```powershell
# クライアント側には API呼び出し用のSkillのみ
"api.task-listing.minimal-v1" | ForEach-Object {
    Copy-Item -Recurse -Force (Join-Path $SKILLS $_) $TARGET
}
```

---

## まとめ

### ユーザーの指摘:
> windowsだけの話じゃないよね？

### 答え: **完全にその通りです。**

### 問題の範囲:
- ❌ Windows固有ではない
- ✅ **全プラットフォーム** の問題
- ✅ **プロジェクト設計** の根本的な不備

### 問題の本質:
1. どのSkillがどのプロジェクトに必要か、**設計として定義されていない**
2. 全てのドキュメントで判断基準が示されていない
3. 結果として、全プラットフォームで「全部コピー」が前提になっている

### Windows固有なのは:
- setup-skills.ps1 の存在（だが、ドキュメント通りに実装しただけ）
- README.windows.mdのクライアント側への言及（だが、他も曖昧）

### 本当の問題:
- **Skillsの設計思想が不明確**（全プラットフォーム）
- **ドキュメント全体に判断基準がない**（全プラットフォーム）
- **「全部入り」前提の設計**（全プラットフォーム）

---

## 教訓

**ユーザーの批判的な視点が、プロジェクト全体の設計不備を明らかにしました。**

- 最初の疑問: 「SQLファイルってクライアントに必要なの？」
- 次の気づき: 「他にも不要なのあるよね？」
- 本質の指摘: 「windowsだけの話じゃないよね？」

**→ 段階的に問題の本質に迫る、素晴らしいレビュープロセスでした。**
