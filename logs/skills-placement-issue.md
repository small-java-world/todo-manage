# Claude Code Skills 配置の問題点

## 発見した問題

**現状:** クライアント側 (todo-api-client-sample) に4つのSkillsを全てコピー
**問題:** 実際に必要なのは1つだけ！

---

## 詳細分析

### ✅ クライアント側に必要: 1個

#### 1. api.task-listing.minimal-v1
- **説明:** タスク一覧の軽量取得（段階取得の前段）
- **用途:** `GET /tasks?fields=hid,title,status,updated_at`
- **理由:** クライアントがAPIを呼び出す側なので必要

---

### ❌ クライアント側に不要: 3個

#### 2. architecture.id-allocation.counters-v1
- **説明:** 階層IDの競合安全な採番（counters 方式）
- **用途:** サーバー側のDB設計
  ```sql
  SELECT last FROM counters WHERE scope=:scope FOR UPDATE;
  UPDATE counters SET last=last+1 WHERE scope=:scope;
  ```
- **理由:** クライアントはDBに直接アクセスしない
- **判定:** ❌ **完全に不要**

#### 3. ops.review.evidence-v1
- **説明:** レビュー解決の証跡を CAS に保存してリンク
- **用途:** サーバー側のCAS管理
  ```
  POST /tasks/{hid}/links
  { "uri": "cas://sha256/ab/abcd...", "role": "patch" }
  ```
- **理由:** クライアントはCASの内部実装を知る必要がない
- **判定:** ❌ **不要**

#### 4. tdd.red-case.write-v1
- **説明:** TDD — 最小 RED テストの作成
- **用途:** サーバー側のテスト開発
  ```python
  def test_task_creation_with_invalid_parent_id():
      response = client.post("/tasks/", json={...})
      assert response.status_code == 404
  ```
- **理由:**
  - client.py は67行の単純なスクリプト
  - 依存関係は `requests` のみ
  - TDDでテストを書くような複雑な実装ではない
- **判定:** ❌ **不要**

---

## 現状の配置

### todo-api-client-sample/.claude/skills/
```
├── api.task-listing.minimal-v1/          ✅ 必要
├── architecture.id-allocation.counters-v1/ ❌ 不要
├── ops.review.evidence-v1/                 ❌ 不要
└── tdd.red-case.write-v1/                  ❌ 不要
```

**不要率: 75% (4個中3個が不要)**

---

## 正しい配置

### todo-api-client-sample/.claude/skills/
```
└── api.task-listing.minimal-v1/          ✅ 必要
```

### todo-api/.claude/skills/
```
├── api.task-listing.minimal-v1/
├── architecture.id-allocation.counters-v1/
├── ops.review.evidence-v1/
└── tdd.red-case.write-v1/
```

---

## なぜこうなっているのか？

### setup-skills.ps1 を見ると:

```powershell
# todo-api への配置
"api.task-listing.minimal-v1",
"architecture.id-allocation.counters-v1",
"ops.review.evidence-v1",
"tdd.red-case.write-v1" | ForEach-Object {
    Copy-Item -Path $SourcePath -Destination $DestPath -Recurse -Force
}

# todo-api-client-sample への配置
"api.task-listing.minimal-v1",
"architecture.id-allocation.counters-v1",
"ops.review.evidence-v1",
"tdd.red-case.write-v1" | ForEach-Object {
    Copy-Item -Path $SourcePath -Destination $DestPath -Recurse -Force
}
```

**→ 全く同じリストをコピーしている！**

### 理由の推測:

1. **手抜き:** 「全部コピーすれば楽」
2. **理解不足:** クライアント側とサーバー側の違いを理解していない
3. **検証不足:** 実際にどのSkillが必要かを検証していない

---

## 影響

### 混乱を招く
- クライアント開発者が「なぜDBのSQLがあるの？」と疑問に思う
- サーバー側の実装詳細がクライアント側に漏れる
- **関心の分離**が破られている

### ディスク容量の無駄
- 3つの不要なSkillディレクトリが存在
- examples/ ディレクトリにSQLファイルなど

### メンテナンスコスト
- Skillsを更新するとき、両方を更新する必要がある
- 本来は必要ないのに

---

## 推奨される修正

### 1. setup-skills.ps1 を修正

```powershell
# todo-api への配置
$SERVER_SKILLS = @(
    "api.task-listing.minimal-v1",
    "architecture.id-allocation.counters-v1",
    "ops.review.evidence-v1",
    "tdd.red-case.write-v1"
)

$SERVER_SKILLS | ForEach-Object {
    Copy-Item -Path (Join-Path $SKILLS $_) -Destination $API_TARGET -Recurse -Force
}

# todo-api-client-sample への配置
$CLIENT_SKILLS = @(
    "api.task-listing.minimal-v1"
)

$CLIENT_SKILLS | ForEach-Object {
    Copy-Item -Path (Join-Path $SKILLS $_) -Destination $CLIENT_TARGET -Recurse -Force
}
```

### 2. ドキュメント更新

- windows-skill-setup.md を修正
- WINDOWS_VERIFICATION_CHECKLIST.md に理由を追記

---

## まとめ

**ユーザーの指摘が完全に正しかった:**

> todo-api-client-sample\.claude\skills\architecture.id-allocation.counters-v1\examples\id_alloc.sql
> ってクライアントに必要なの？？

**答え:**
- ❌ 不要です
- ❌ しかも他に2つも不要なものがあります
- ✅ 必要なのは api.task-listing.minimal-v1 だけです

**問題の本質:**
- セットアップスクリプトが「全部コピー」している
- クライアント側とサーバー側の関心の分離ができていない
- 検証が不十分

**教訓:**
- ドキュメントやチェックリストを盲目的に信じない
- 実際に必要かどうかを批判的に検証する
- **ユーザーの疑問が設計の問題を明らかにする**
