# Claude Skills セットアップガイド

Claude CodeにSkillを認識させる完全ガイド

## 📋 目次

1. [前提条件](#前提条件)
2. [ディレクトリ構造の確認](#ディレクトリ構造の確認)
3. [Claude Codeの再起動](#claude-codeの再起動)
4. [動作確認](#動作確認)
5. [トラブルシューティング](#トラブルシューティング)

---

## 前提条件

### 必要なもの

- ✅ Claude Code（最新版）
- ✅ Skillファイルが正しく配置されている
- ✅ SKILL.mdにYAMLフロントマターが含まれている

### Skillの配置場所

Claude Codeは以下の2つの場所からSkillを自動認識します：

#### 1. プロジェクトスコープSkill（推奨）

```
<プロジェクトルート>/.claude/skills/<skill-name>/SKILL.md
```

**このプロジェクトの場合**:
```
D:\todo_api_fastapi\.claude\skills\todo-api-knowledge\SKILL.md
```

**特徴**:
- ✅ プロジェクト固有のSkill
- ✅ プロジェクト内でのみ有効
- ✅ チームで共有可能（Gitにコミット）

#### 2. グローバルSkill

```
~/.claude/skills/<skill-name>/SKILL.md
```

**例**:
- Linux/macOS: `/home/username/.claude/skills/todo-api-knowledge/SKILL.md`
- Windows: `C:\Users\username\.claude\skills\todo-api-knowledge\SKILL.md`

**特徴**:
- ✅ すべてのプロジェクトで有効
- ✅ 個人的なSkill
- ✅ プロジェクト間で共有したいSkill

---

## ディレクトリ構造の確認

### ステップ1: .claudeディレクトリの確認

```bash
# Windowsの場合
dir D:\todo_api_fastapi\.claude

# Linux/macOSの場合
ls -la D:/todo_api_fastapi/.claude
```

**期待される出力**:
```
.claude/
└── skills/
```

### ステップ2: skillsディレクトリの確認

```bash
# Windowsの場合
dir D:\todo_api_fastapi\.claude\skills

# Linux/macOSの場合
ls -la D:/todo_api_fastapi/.claude/skills
```

**期待される出力**:
```
skills/
└── todo-api-knowledge/
```

### ステップ3: SKILL.mdの存在確認

```bash
# ファイルの存在確認
ls -la D:/todo_api_fastapi/.claude/skills/todo-api-knowledge/SKILL.md
```

**期待される出力**:
```
-rw-r--r-- 1 user group 17000 Oct 19 23:16 SKILL.md
```

### ステップ4: SKILL.mdの内容確認

YAMLフロントマターが正しく含まれているか確認：

```bash
# 最初の5行を確認
head -5 D:/todo_api_fastapi/.claude/skills/todo-api-knowledge/SKILL.md
```

**期待される出力**:
```yaml
---
name: todo-api-knowledge
description: TODO API FastAPIプロジェクトの知識ベース。階層構造API、レビュー管理、バックアップ、TDD実装パターンを提供。コンテキスト効率的にプロジェクト知識を利用可能
---

# TODO API Knowledge Skill
```

**重要**:
- `---` で囲まれたYAMLフロントマターが必須
- `name` フィールドが必須（ディレクトリ名と一致推奨）
- `description` フィールドが必須（Claudeが判断に使用）

---

## Claude Codeの再起動

### 方法1: Claude Codeを完全に終了して再起動（推奨）

#### Windows

1. **タスクマネージャーで確認**:
   ```
   Ctrl + Shift + Esc → プロセスタブ → "Claude Code"を探す
   ```

2. **Claude Codeを終了**:
   - すべてのClaude Codeウィンドウを閉じる
   - タスクマネージャーでプロセスが残っていないか確認

3. **Claude Codeを再起動**:
   - スタートメニューから「Claude Code」を起動
   - またはデスクトップショートカットをダブルクリック

#### Linux/macOS

1. **Claude Codeを終了**:
   ```bash
   # すべてのウィンドウを閉じる
   # またはターミナルから
   killall claude-code
   ```

2. **Claude Codeを再起動**:
   ```bash
   claude-code
   # または
   open -a "Claude Code"  # macOSの場合
   ```

### 方法2: プロジェクトを再度開く

1. Claude Code内で現在のプロジェクトを閉じる
2. `D:\todo_api_fastapi` を再度開く

### 方法3: Developer Toolsでリロード（開発者向け）

1. Claude Code内で `Ctrl + Shift + I`（Windows/Linux）または `Cmd + Option + I`（macOS）
2. Developer Toolsが開く
3. `Ctrl + R`（Windows/Linux）または `Cmd + R`（macOS）でリロード

---

## 動作確認

### 確認方法1: Skillリストの確認

Claude Code起動後、以下のコマンドで利用可能なSkillを確認できます：

```
/skills
```

**期待される出力**:
```
Available skills:
- todo-api-knowledge: TODO API FastAPIプロジェクトの知識ベース...
```

### 確認方法2: 質問で確認

Claude Codeに以下のような質問をしてみてください：

#### テスト質問1: 階層ID

```
質問: 「階層IDの形式を教えて」
```

**期待される応答**:
- REQ-001、REQ-001.TSK-001、REQ-001.TSK-001.SUB-001 の説明
- 階層ID生成ロジックの説明

#### テスト質問2: API仕様

```
質問: 「要件を作成するAPIエンドポイントは?」
```

**期待される応答**:
- `POST /tasks/requirements/` の説明
- リクエストボディの例
- レスポンスの例

#### テスト質問3: ベストプラクティス

```
質問: 「TDDのベストプラクティスを教えて」
```

**期待される応答**:
- テスト駆動開発のフロー説明
- このプロジェクトでのTDD実装パターン

### 確認方法3: Skillが読み込まれているか確認

Claude Codeの応答に以下のような記載があれば、Skillが正しく読み込まれています：

```
# 応答例
「SKILL.mdから情報を取得しました...」
「TODO API Knowledge Skillによると...」
```

---

## トラブルシューティング

### 問題1: Skillが認識されない

#### 症状
- `/skills` コマンドでSkillが表示されない
- 質問してもSkillの情報が使われない

#### 解決策

**1. ディレクトリ構造を確認**

```bash
# 正しい構造か確認
tree D:/todo_api_fastapi/.claude
```

**期待される構造**:
```
.claude/
└── skills/
    └── todo-api-knowledge/
        └── SKILL.md
```

**よくある間違い**:
```
❌ .claude/todo-api-knowledge/SKILL.md          # skillsディレクトリがない
❌ .claude/skills/SKILL.md                      # skill名のディレクトリがない
❌ .claude/skills/todo-api-knowledge/skill.md   # ファイル名が小文字
```

**2. YAMLフロントマターを確認**

```bash
head -5 D:/todo_api_fastapi/.claude/skills/todo-api-knowledge/SKILL.md
```

**正しい形式**:
```yaml
---
name: todo-api-knowledge
description: TODO API FastAPIプロジェクトの知識ベース...
---
```

**よくある間違い**:
```yaml
❌ name: "todo-api-knowledge"    # 引用符は不要（あっても可）
❌ Name: todo-api-knowledge      # 小文字の'name'が必須
❌ description:                  # descriptionが空
```

**3. ファイル権限を確認**

```bash
# 読み取り権限があるか確認
ls -l D:/todo_api_fastapi/.claude/skills/todo-api-knowledge/SKILL.md
```

権限がない場合:
```bash
chmod 644 D:/todo_api_fastapi/.claude/skills/todo-api-knowledge/SKILL.md
```

**4. Claude Codeを完全再起動**

- すべてのウィンドウを閉じる
- タスクマネージャー/Activity Monitorでプロセス確認
- 再起動

### 問題2: Skillは認識されるが、情報が古い

#### 症状
- SKILL.mdを更新したが、古い情報が表示される

#### 解決策

**1. Claude Codeを再起動**

```bash
# 完全に終了して再起動
```

**2. キャッシュクリア（開発者向け）**

```bash
# Claude Codeのキャッシュディレクトリを削除
# Windowsの場合
rmdir /s %APPDATA%\claude-code\Cache

# Linux/macOSの場合
rm -rf ~/.config/claude-code/Cache
```

**3. プロジェクトを再度開く**

- 現在のプロジェクトを閉じる
- `D:\todo_api_fastapi` を再度開く

### 問題3: 複数のプロジェクトで同じSkillを使いたい

#### 解決策: グローバルSkillとして配置

**1. ホームディレクトリに配置**

```bash
# Windowsの場合
mkdir -p C:\Users\<username>\.claude\skills\todo-api-knowledge
copy D:\todo_api_fastapi\.claude\skills\todo-api-knowledge\* C:\Users\<username>\.claude\skills\todo-api-knowledge\

# Linux/macOSの場合
mkdir -p ~/.claude/skills/todo-api-knowledge
cp -r D:/todo_api_fastapi/.claude/skills/todo-api-knowledge/* ~/.claude/skills/todo-api-knowledge/
```

**2. Claude Codeを再起動**

**3. どのプロジェクトでも利用可能になる**

### 問題4: Skillが部分的にしか読み込まれない

#### 症状
- Skillは認識されるが、一部の情報しか取得できない

#### 解決策

**1. SKILL.mdのサイズを確認**

```bash
ls -lh D:/todo_api_fastapi/.claude/skills/todo-api-knowledge/SKILL.md
```

**現在のサイズ**: 約17KB（問題なし）

**2. ファイルが破損していないか確認**

```bash
# ファイルの末尾を確認
tail -10 D:/todo_api_fastapi/.claude/skills/todo-api-knowledge/SKILL.md
```

**3. 文字コードを確認**

SKILL.mdは **UTF-8** である必要があります。

```bash
# 文字コード確認（Linuxの場合）
file -i D:/todo_api_fastapi/.claude/skills/todo-api-knowledge/SKILL.md
```

期待される出力:
```
charset=utf-8
```

---

## 高度な設定

### Skillの優先順位

Claude Codeは以下の順序でSkillを検索します：

1. **プロジェクトスコープSkill**: `.claude/skills/` （優先）
2. **グローバルSkill**: `~/.claude/skills/`

同じ名前のSkillがある場合、プロジェクトスコープが優先されます。

### 複数のSkillを使用

プロジェクトに複数のSkillを追加可能：

```
.claude/
└── skills/
    ├── todo-api-knowledge/
    │   └── SKILL.md
    ├── python-best-practices/
    │   └── SKILL.md
    └── testing-patterns/
        └── SKILL.md
```

Claude Codeは質問内容から適切なSkillを自動選択します。

### Skillのデバッグ

#### Developer Toolsで確認

1. `Ctrl + Shift + I` でDeveloper Toolsを開く
2. Consoleタブで以下を実行:

```javascript
// Skillの読み込み状況を確認
console.log("Skills loaded")
```

---

## チェックリスト

Skillが正しく認識されるための最終チェックリスト：

### ファイル構造
- [ ] `.claude/skills/todo-api-knowledge/SKILL.md` が存在する
- [ ] ディレクトリ名は `todo-api-knowledge`（ハイフン付き）
- [ ] ファイル名は `SKILL.md`（大文字）

### SKILL.mdの内容
- [ ] YAMLフロントマターが存在する（`---` で囲まれている）
- [ ] `name` フィールドが存在する
- [ ] `description` フィールドが存在する
- [ ] Markdownコンテンツが含まれている

### ファイル属性
- [ ] ファイルの文字コードはUTF-8
- [ ] ファイルに読み取り権限がある
- [ ] ファイルが破損していない

### Claude Code
- [ ] Claude Codeを再起動した
- [ ] プロジェクトディレクトリが正しい（`D:\todo_api_fastapi`）
- [ ] `/skills` コマンドでSkillが表示される

### 動作確認
- [ ] 「階層IDの形式を教えて」で正しい応答がある
- [ ] 「要件作成APIは?」で正しい応答がある
- [ ] Skillの情報が使われている

---

## まとめ

### 基本手順（3ステップ）

1. **ファイル配置確認**
   ```bash
   ls -la D:/todo_api_fastapi/.claude/skills/todo-api-knowledge/SKILL.md
   ```

2. **Claude Code再起動**
   - すべてのウィンドウを閉じる
   - 再起動

3. **動作確認**
   ```
   質問: 「階層IDの形式を教えて」
   ```

### トラブル時の対処

1. **ディレクトリ構造を再確認**
2. **YAMLフロントマターを確認**
3. **Claude Codeを完全再起動**
4. **チェックリストを確認**

---

**作成日**: 2025年10月19日
**対象プロジェクト**: D:\todo_api_fastapi
**Skill名**: todo-api-knowledge

Claude Skillsのセットアップ、お疲れ様でした！🎉
