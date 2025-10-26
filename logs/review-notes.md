# Todo-API レビューノート

## 階層的ID採番ルール (counters 方式)

### 概要
todo-apiでは階層的なID (例: REQ-001, REQ-001.TSK-001, REQ-001.TSK-001.SUB-001) を採番する仕組みが必要です。
複数のリクエストが同時に来た場合の競合を安全に処理するため、counters テーブルを使った採番方式が推奨されます。

### 1. scope の設定方法

scopeは、どのレベルでIDを採番するかを示す識別子です:

- `REQ`: 要件レベル (REQ-001, REQ-002, ...)
- `REQ-001.TSK`: 特定の要件 (REQ-001) の下のタスクレベル (REQ-001.TSK-001, REQ-001.TSK-002, ...)
- `REQ-001.TSK-001.SUB`: 特定のタスク (REQ-001.TSK-001) の下のサブタスクレベル

各scopeごとに独立したカウンタを持つことで、親が異なれば同じ番号を使えます。

### 2. トランザクションでの SELECT FOR UPDATE の役割

```sql
BEGIN;
SELECT last FROM counters WHERE scope=:scope FOR UPDATE;
UPDATE counters SET last=last+1 WHERE scope=:scope;
COMMIT;
```

**SELECT FOR UPDATE の重要性:**
- 行レベルロックを取得し、他のトランザクションが同じ行を読み取る・更新することを防ぐ
- 2つのリクエストが同時に来ても、片方がロックを取得している間、もう片方は待機する
- これにより、同じIDが2回採番されることを防ぐ

**動作例:**
1. トランザクションA: `SELECT last FROM counters WHERE scope='REQ' FOR UPDATE` → 5 を取得、ロック
2. トランザクションB: `SELECT last FROM counters WHERE scope='REQ' FOR UPDATE` → Aのロックが解除されるまで待機
3. トランザクションA: `UPDATE counters SET last=6` → COMMIT → ロック解放
4. トランザクションB: `SELECT` が実行され、6 を取得、ロック → `UPDATE counters SET last=7` → COMMIT

### 3. ユニーク制約違反時のリトライ戦略

階層的IDには UNIQUE制約 がかかっています。万が一、同じIDが生成された場合は `IntegrityError` が発生します。

**指数バックオフによるリトライ:**
```python
max_retries = 5
for attempt in range(max_retries):
    try:
        hierarchical_id = generate_id(parent, task_type)
        return hierarchical_id
    except IntegrityError:
        if attempt == max_retries - 1:
            raise ValueError("Failed to generate unique ID")
        time.sleep(0.1 * (2**attempt))  # 0.1s, 0.2s, 0.4s, 0.8s, 1.6s
```

**指数バックオフの利点:**
- 最初は短い待機時間で素早くリトライ
- リトライを重ねるごとに待機時間を倍増させ、システムへの負荷を軽減
- 一時的な競合は解消される可能性が高い

### 現在の実装状況

現在の `hierarchical_id_service.py` では、countersテーブルを使わず `COUNT()` クエリで採番しています:

```python
count = self.db.query(Task).filter(Task.type == TaskType.requirement).count() + 1
return f"REQ-{count:03d}"
```

この方式は以下の問題があります:
- 複数のトランザクションが同時に実行されると、同じcountが返される可能性
- ただし、hierarchical_idのUNIQUE制約により、最終的には片方が失敗してリトライされる

**推奨される改善:**
countersテーブルを使った実装に変更することで:
- SELECT FOR UPDATEによる行レベルロックで競合を事前に防止
- リトライの頻度を減らし、パフォーマンスを向上
- より明示的で理解しやすいコード

---

## レビュー証跡管理 (CAS + タスクリンク)

### 概要
コードレビューで指摘された修正内容を、CAS (Content-Addressable Storage) に保存し、タスクにリンクすることで、変更履歴と証跡を追跡可能にします。

### レビュー証跡管理の手順

#### 1. 差分パッチをCASに保存

コードレビューで指摘された修正に対して、差分パッチを生成しCASに保存します:

```bash
# 修正コミットの差分を取得
git diff HEAD~1 HEAD > review-fix.patch

# Base64エンコード
base64 -w 0 review-fix.patch > review-fix.patch.b64
```

```bash
# CASへ保存
curl -X POST http://localhost:8000/artifacts/ \
  -H "Content-Type: application/json" \
  -d '{
    "content": "'"$(cat review-fix.patch.b64)"'",
    "media_type": "text/x-diff",
    "source_task_hid": "REQ-001.TSK-001",
    "purpose": "review-fix"
  }'
```

レスポンス例:
```json
{
  "sha256": "abc123def456...",
  "media_type": "text/x-diff",
  "bytes_size": 1234,
  "cas_uri": "cas://sha256/ab/abc123def456...",
  "created_at": "2025-10-26T07:00:00"
}
```

#### 2. タスクに `role:"patch"` でリンク

取得したSHA-256ハッシュを使って、タスクにリンクを作成します:

```bash
# アーティファクトをタスクにリンク
curl -X POST http://localhost:8000/artifacts/abc123def456.../link \
  -H "Content-Type: application/json" \
  -d '{
    "sha256_hash": "REQ-001.TSK-001",
    "role": "patch"
  }'
```

#### 3. テスト実行ログをCASに保存

修正後のテスト実行ログも同様にCASに保存します:

```bash
# テスト実行
pytest tests -v > test-results.log

# Base64エンコード
base64 -w 0 test-results.log > test-results.log.b64

# CASへ保存
curl -X POST http://localhost:8000/artifacts/ \
  -H "Content-Type: application/json" \
  -d '{
    "content": "'"$(cat test-results.log.b64)"'",
    "media_type": "text/plain",
    "source_task_hid": "REQ-001.TSK-001",
    "purpose": "test-results"
  }'
```

#### 4. タスクに `role:"log"` でリンク

テストログのSHA-256ハッシュを取得し、タスクにリンクします:

```bash
curl -X POST http://localhost:8000/artifacts/xyz789abc123.../link \
  -H "Content-Type: application/json" \
  -d '{
    "sha256_hash": "REQ-001.TSK-001",
    "role": "log"
  }'
```

### 具体例: REQ-001.TSK-001 のレビュー対応

**シナリオ:**
- タスク REQ-001.TSK-001 に対するコードレビューで、エラーハンドリングの改善が指摘された
- 修正を行い、パッチとテストログをCASに保存してリンクする

**手順:**

1. **修正パッチを生成・保存**
   ```bash
   git diff HEAD~1 HEAD > req-001-tsk-001-fix.patch
   SHA256=$(curl -s -X POST http://localhost:8000/artifacts/ \
     -H "Content-Type: application/json" \
     -d "$(cat req-001-tsk-001-fix.patch | base64 -w 0 | jq -R '{content: ., media_type: "text/x-diff", source_task_hid: "REQ-001.TSK-001", purpose: "review-fix"}')" \
     | jq -r '.sha256')
   echo "Patch SHA256: $SHA256"
   ```

2. **タスクにパッチをリンク**
   ```bash
   curl -X POST http://localhost:8000/artifacts/$SHA256/link \
     -H "Content-Type: application/json" \
     -d '{
       "sha256_hash": "REQ-001.TSK-001",
       "role": "patch"
     }'
   ```

3. **テストを実行してログを保存**
   ```bash
   pytest tests/test_error_handling.py -v > test-results.log
   LOG_SHA256=$(curl -s -X POST http://localhost:8000/artifacts/ \
     -H "Content-Type: application/json" \
     -d "$(cat test-results.log | base64 -w 0 | jq -R '{content: ., media_type: "text/plain", source_task_hid: "REQ-001.TSK-001", purpose: "test-results"}')" \
     | jq -r '.sha256')
   echo "Log SHA256: $LOG_SHA256"
   ```

4. **タスクにテストログをリンク**
   ```bash
   curl -X POST http://localhost:8000/artifacts/$LOG_SHA256/link \
     -H "Content-Type: application/json" \
     -d '{
       "sha256_hash": "REQ-001.TSK-001",
       "role": "log"
     }'
   ```

5. **リンクされたアーティファクトを確認**
   ```bash
   curl http://localhost:8000/artifacts/tasks/REQ-001.TSK-001/artifacts
   ```

### レビュー証跡管理のメリット

#### 1. 再現性
- 過去の修正内容をSHA-256ハッシュで一意に特定できる
- 同じコンテンツは重複して保存されない (Content-Addressable)
- いつでも過去の差分やテストログを取り出せる

#### 2. 追跡可能性
- タスクにリンクされているため、どのタスクにどの修正が適用されたか明確
- `role` フィールドで用途を区別 (patch, log, spec, test など)
- レビュープロセス全体の透明性が向上

#### 3. 監査証跡
- コードレビューの指摘に対する対応が記録として残る
- コンプライアンスや品質監査に対応しやすい
- チーム間での知識共有が促進される

### CASの実装詳細

**CASディレクトリ構造:**
```
cas_root/
  sha256/
    ab/
      abc123def456...  # 実際のファイル
    xy/
      xyz789abc123...
```

**データベーススキーマ:**
```sql
-- アーティファクト
CREATE TABLE artifacts (
  id INTEGER PRIMARY KEY,
  sha256 TEXT UNIQUE NOT NULL,
  media_type TEXT NOT NULL,
  bytes_size INTEGER NOT NULL,
  source_task_hid TEXT,
  purpose TEXT,
  created_at TIMESTAMP
);

-- タスク-アーティファクトリンク
CREATE TABLE task_artifact_links (
  id INTEGER PRIMARY KEY,
  task_hid TEXT NOT NULL,
  artifact_id INTEGER NOT NULL,
  role TEXT NOT NULL,  -- "patch", "log", "spec", "test", etc.
  created_at TIMESTAMP,
  FOREIGN KEY (artifact_id) REFERENCES artifacts(id)
);
```

**CAS URIフォーマット:**
```
cas://sha256/{prefix}/{full_hash}
例: cas://sha256/ab/abc123def456...
```

---

## TDD — 最小 RED テストの作成

### 概要
TDD (Test-Driven Development) では、「RED → GREEN → REFACTOR」のサイクルを繰り返して開発を進めます。
最初に失敗するテストを1つだけ作成し、そのテストだけを通す最小実装を行い、その後にリファクタリングを行います。

### TDD の 3 つのフェーズ

#### 1. RED: 失敗する最小テストを1つだけ追加

**重要な原則:**
- **1つの受入条件に対して1つのテスト**を作成する
- 複数の失敗要因を同時に作らない
- テストは明確に失敗する必要がある

**例: 存在しない parent_id でタスク作成時の 404 エラー**

```python
def test_task_creation_with_invalid_parent_id():
    """存在しない parent_id を指定した場合、404 を返すこと"""
    response = client.post("/tasks/", json={
        "title": "Invalid Parent Task",
        "type": "task",
        "parent_id": 99999  # 存在しない
    })
    assert response.status_code == 404
```

このテストは現在失敗する（または 500 エラーを返す）はずです。
それが「RED」フェーズです。

#### 2. GREEN: そのテストだけを通す最小実装

テストを通すための**最小限のコード**だけを追加します。
他の機能や汎用性は考えず、このテストだけを通すことに集中します。

**最小実装の例:**

```python
@router.post("/tasks/")
def create_task(task_data: TaskCreate, db: Session = Depends(get_db)):
    # RED テストを GREEN にするための最小実装
    if task_data.parent_id is not None:
        parent_task = db.query(Task).filter(Task.id == task_data.parent_id).first()
        if parent_task is None:
            raise HTTPException(status_code=404, detail="Parent task not found")

    # 既存のタスク作成ロジック
    ...
```

この実装で、テストがパスする（GREEN）ようになります。

#### 3. REFACTOR: 重複排除/命名/設計整合を実施

テストがパスした状態で、コードの品質を改善します:

**リファクタリングのポイント:**
- **重複コードの排除**: 同じようなバリデーションが複数箇所にある場合、共通化する
- **命名の改善**: 変数名や関数名を意図が明確になるように改善
- **設計の整合性**: 既存の設計パターンと整合性を取る
- **テストは変更しない**: テストは GREEN のまま維持する

**リファクタリング例:**

```python
# バリデーション処理を専用サービスに移動
class TaskValidationService:
    def validate_parent_exists(self, parent_id: int, db: Session) -> Task:
        """親タスクの存在を確認"""
        parent = db.query(Task).filter(Task.id == parent_id).first()
        if parent is None:
            raise HTTPException(
                status_code=404,
                detail=f"Parent task with id {parent_id} not found"
            )
        return parent

# コントローラーから呼び出す
@router.post("/tasks/")
def create_task(task_data: TaskCreate, db: Session = Depends(get_db)):
    if task_data.parent_id is not None:
        validation_service = TaskValidationService()
        parent = validation_service.validate_parent_exists(task_data.parent_id, db)

    # タスク作成ロジック
    ...
```

### TDD サイクルの実践例

#### シナリオ: 存在しない parent_id でタスク作成

**1. RED フェーズ**
- テストファイル `test_task_invalid_parent.py` を作成
- 存在しない parent_id を指定してタスクを作成
- 404 エラーが返ることを期待
- **実行結果**: テストが失敗（500 エラーまたは成功してしまう）

**2. GREEN フェーズ**
- `app/api/tasks.py` の `create_task` 関数に最小実装を追加
- parent_id が指定されている場合、存在確認を行う
- 存在しない場合は HTTPException(404) を発生
- **実行結果**: テストがパス

**3. REFACTOR フェーズ**
- バリデーションロジックを `TaskValidationService` に移動
- 既存の `HierarchicalIdService` と統合を検討
- エラーメッセージを統一
- **実行結果**: テストは引き続きパス、コードが整理される

### TDD のメリット

#### 1. 仕様の明確化
- テストが受入条件を明確に表現
- 実装前に期待する動作を定義
- 仕様のドキュメントとしても機能

#### 2. 過剰実装の防止
- 必要最小限の機能だけを実装
- YAGNI (You Aren't Gonna Need It) 原則を自然に適用
- 開発効率の向上

#### 3. リファクタリングの安全性
- テストがあることで、リファクタリング時に既存機能が壊れていないことを確認できる
- 設計改善を恐れずに行える
- 技術的負債の蓄積を防止

#### 4. バグの早期発見
- テストを先に書くことで、エッジケースを事前に考慮
- 実装後のデバッグ時間を削減
- 品質の向上

### 最小 RED テストのチェックリスト

- [ ] 1つの受入条件だけをテストしている
- [ ] テストは明確に失敗する（現時点では）
- [ ] テストコードは読みやすく、意図が明確
- [ ] アサーションは具体的で、失敗時のメッセージが有用
- [ ] テストは独立しており、他のテストに依存しない
- [ ] テストの実行は高速（外部依存を最小限に）

### 作成した RED テストケース

ファイル: `logs/test_task_invalid_parent.py`

**受入条件:**
タスク作成時に parent_id が存在しない場合、404 エラーを返すこと

**テストコード:**
```python
def test_task_creation_with_invalid_parent_id():
    """存在しない parent_id を指定した場合、404 を返すこと"""
    response = client.post("/tasks/", json={
        "title": "Invalid Parent Task",
        "type": "task",
        "parent_id": 99999  # 存在しない
    })
    assert response.status_code == 404
```

**次のステップ (GREEN フェーズ):**
1. `app/api/tasks.py` の `create_task` 関数を修正
2. parent_id が指定されている場合の存在確認を追加
3. 存在しない場合は HTTPException(404) を発生
4. テストを実行して、パスすることを確認

**その後 (REFACTOR フェーズ):**
1. バリデーションロジックを適切な場所に移動
2. エラーメッセージの統一
3. 既存の親子関係バリデーションとの整合性確認
4. テストを再実行して、引き続きパスすることを確認
