# TODOとして管理するファイルの設計

## 質問
「CASは証跡用の小さいファイル向け。じゃあTODOとして管理するファイル（仕様書、テストコード、設計書など）はどうするの？」

## 答え: 2層構造

### 第1層: Gitリポジトリ（作業中のファイル）

タスクごとに専用ディレクトリを自動生成:

```
git_repo/
  requirements/
    REQ-001/
      requirement.md           ← 要件の仕様書（編集可能）
      outline.json             ← メタデータ
      tasks/
        REQ-001.TSK-001/
          task.md              ← タスクの仕様書（編集可能）
          outline.json
          tests/               ← テストコード（編集可能）
            test_login.py
          subtasks/
            REQ-001.TSK-001.SUB-001/
              subtask.md
```

**特徴:**
- ✅ ファイルは **常に最新版**
- ✅ **編集可能** (vim, VSCode, API経由)
- ✅ Gitでバージョン管理
- ✅ パスは階層ID (REQ-001.TSK-001) から自動生成
- ✅ ファイル転送不要（サーバー側でローカルアクセス）

---

### 第2層: CAS（完了時の証跡）

タスク完了時にスナップショットを保存:

```
cas_root/
  sha256/
    ab/
      abc123...   ← レビュー修正パッチ（変更不可）
    xy/
      xyz789...   ← テスト実行ログ（変更不可）
```

**特徴:**
- ✅ **スナップショット** (その時点の状態を保存)
- ✅ **変更不可** (改ざん防止)
- ✅ **永久保存** (削除されない)
- ✅ SHA-256ハッシュで内容保証
- ⚠️ ファイル転送が必要（Base64エンコード）

---

## 実際のワークフロー

### シナリオ: 「ログイン機能を実装する」タスク

#### ステップ1: タスク作成
```bash
curl -X POST http://localhost:8000/tasks/ \
  -d '{"title": "ログイン機能を実装", "type": "task", "parent_id": 1}'

# 自動生成:
# hierarchical_id: REQ-001.TSK-001
# git_repo/requirements/REQ-001/tasks/REQ-001.TSK-001/
```

#### ステップ2: 仕様書を書く（Gitリポジトリ）
```bash
# サーバー側でファイル作成（ファイル転送なし）
vim git_repo/requirements/REQ-001/tasks/REQ-001.TSK-001/task.md

# または API 経由
curl -X POST http://localhost:8000/storage/REQ-001.TSK-001/spec \
  -d '{"content": "# ログイン機能\n\n..."}'

# 保存先: git_repo/requirements/REQ-001/tasks/REQ-001.TSK-001/task.md
```

#### ステップ3: テストコードを書く（Gitリポジトリ）
```bash
# サーバー側でファイル作成
vim git_repo/requirements/REQ-001/tasks/REQ-001.TSK-001/tests/test_login.py

# 保存先: git_repo/requirements/REQ-001/tasks/REQ-001.TSK-001/tests/
```

#### ステップ4: 実装完了後、証跡を保存（CAS）
```bash
# レビュー修正パッチを CAS に保存
git diff > fix.patch
curl -X POST http://localhost:8000/artifacts/ \
  -d "{\"content\": \"$(cat fix.patch | base64)\", ...}"

# テスト実行ログを CAS に保存
pytest > test.log
curl -X POST http://localhost:8000/artifacts/ \
  -d "{\"content\": \"$(cat test.log | base64)\", ...}"

# 保存先: cas_root/sha256/ab/abc123...
```

---

## 比較表

| 項目 | Gitリポジトリ | CAS |
|------|-------------|-----|
| **用途** | 作業中のファイル | 完了時の証跡 |
| **ファイル例** | 仕様書、テストコード、設計書 | パッチ、ログ、スナップショット |
| **編集** | ✅ 可能 | ❌ 不可（変更不可） |
| **バージョン** | 常に最新 | スナップショット |
| **転送** | ❌ 不要（サーバー側でアクセス） | ✅ 必要（Base64アップロード） |
| **サイズ** | 制限なし | 小さいファイル推奨（数KB～数百KB） |
| **管理** | Git | SHA-256ハッシュ |

---

## まとめ

### TODOとして管理するファイル → Gitリポジトリ

**メリット:**
- ファイル転送不要（重くない！）
- 常に最新版を編集できる
- Gitでバージョン管理
- 階層IDから自動でパス生成

**具体例:**
```
git_repo/requirements/REQ-001/tasks/REQ-001.TSK-001/task.md
git_repo/requirements/REQ-001/tasks/REQ-001.TSK-001/tests/test_login.py
```

### 完了時の証跡 → CAS

**メリット:**
- スナップショットとして永久保存
- 改ざん防止
- 内容保証（SHA-256）

**具体例:**
```
cas://sha256/ab/abc123...  (レビュー修正パッチ)
cas://sha256/xy/xyz789...  (テスト実行ログ)
```

---

## 結論

**「TODOとして管理するファイルはどうするの？」**

**答え: Gitリポジトリで管理します！**

- タスクごとに専用ディレクトリを自動生成
- サーバー側でローカルアクセス
- **ファイル転送不要なので重くない**
- CASは完了時の証跡用

これで、大きなファイルもアップロード不要で効率的に管理できます。
