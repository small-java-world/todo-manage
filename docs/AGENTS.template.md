# codex cli / MCP AGENTS Registry

## 0. このドキュメントについて

このファイルは Codex CLI / MCP が利用するエージェント群の仕様です。共通ルールと各エージェントの入出力・責務境界・安全ポリシーをまとめ、作業前後の参照元とします。

- 目的: 「どのエージェントに何を頼めばいいか」を人間と自動エージェント両方に明示する
- 運用: 新規エージェントを作ったら本ファイルに追記すること
- 禁止（共通）:
  - 無許可の破壊的コマンド実行（例: `git reset --hard`, `rm -rf /`, DB 初期化）
  - OS コマンド実行や本番系リソース（クラウド/インフラ）へのアクセス指示は worktree_planner が提案したワークツリー/ブランチ内でのみ実施し、勝手に別ブランチを作らない
  - worktree/ブランチは必ず worktree_planner が提案したものを使い、独自に作らない
  - 未承認ネットワーク/外部 API へのアクセス
  - 機密ファイル（秘密鍵、認証情報）への読み書き
  - ログ未保存のまま作業完了
- DB マイグレーションを自動実行するパッチの生成（手動レビューと承認が前提）
- 成果物フォーマット: レポート系は Markdown、パッチ系は git diff --no-prefix 形式の差分のみ（説明文禁止で git apply しやすいようにする）、テスト生成（例: 	dd_writer）は「ファイルパス + ファイル全量」を必ず提示するなど、各エージェント仕様通りに固定する。責務の分離（例: spec_analyzer は要件抽出のみ、	dd_writer はテスト雛形のみ、patch_author は差分のみ）を徹底する
- `main` / `develop` ブランチに直接コミットする前提のパッチを出さない（feature branch / worktree で作業）
- 最終コミットは必ず人間レビューを通すこと（AI 単独で merge しない）

---

## 1. エージェント一覧 (Registry)

| agent_id             | 役割概要                                                   | 主な入力トリガー例                                                                 | 出力物                        | status     |
|----------------------|------------------------------------------------------------|------------------------------------------------------------------------------------|-------------------------------|------------|
| `spec_analyzer`      | 要件/仕様の洗い出しと整理                                  | 「このTODOのTDD要件とテストケース洗い出して」                                      | 要件リスト, テスト観点        | active     |
| `tdd_writer`         | 振る舞い仕様→テストコード雛形の生成 (Kotlin, Vitestなど)  | 「この仕様をKotlin側のテストに落として」                                          | テストコードのドラフト        | active     |
| `patch_author`       | 差分パッチ作成。既存コードに対する変更案のみを返す          | 「このTODOを満たすための修正パッチを出して」                                      | `git diff` 形式のpatchだけ     | active     |
| `todo_manager`       | TODO.mdの３階層(親/子/孫)構造を解析・同期用に整える         | 「TODO.mdをDB同期用の構造に正規化して」                                           | 正規化済みJSON/Markdown表     | active     |
| `worktree_planner`   | worktreeディレクトリの切り方とブランチ戦略を提案            | 「このタスク専用の作業ブランチ/ワークツリー案出して」                              | 作業手順（gitコマンド列）      | active     |
| `arch_guard`         | 責務の越境や肥大化を警告するレビュー係                      | 「この案ボトルネックになる？fatになってない？」                                   | リスク指摘と修正方針           | active     |
| `deprecated_sample`  | 旧エージェント。現在は使用禁止                              | なし                                                                               | なし                           | deprecated |

---

## 2. agent: `spec_analyzer`

**役割 / Purpose**
- TODO項目や要求（自然言語）から、TDDに必要な観点・前提条件・完了条件(AC)を抽出する。
- 「何を満たせばOKなのか」を人間と`tdd_writer`に渡せる粒度に分解する。

**期待される入力 / Input schema**
- タスクの概要テキスト
- 関連する仕様書や設計資料への相対パス
  - 例: `./docs/specs/feature_x.md`
  - 例: `./worktrees/feature-x/TODO.md`

**期待される出力 / Output schema**
- Markdownで以下を返す:
  - `Context:` 背景・前提
  - `Acceptance Criteria:` 箇条書き (条件が満たされたと判断する要件)
  - `Open Questions:` 決まっていないこと
  - `Test View:` テスト観点のざっくり分類 (機能/エラーパス/境界値/並行実行/パフォーマンス 等)

**ワークフロー / How to call (codex cli)**
1. 人間が `TODO.md` または issue テキストを渡す
2. `spec_analyzer` に「このタスクをTDDでやれるように要件化して」と依頼
3. 出力は `./spec-kit/` 配下に追記候補として保存する（自動コミット禁止）

**関連ファイル / Related files**
- [./spec-kit/README.md](./spec-kit/README.md)
- [./docs/architecture/overview.md](./docs/architecture/overview.md)
- [./worktrees/feature-x/TODO.md](./worktrees/feature-x/TODO.md)

**制限 / Safety**
- 実装コードを直接いじるパッチは出さない（それは `patch_author` の責務）

---

## 3. agent: `tdd_writer`

**役割 / Purpose**
- `spec_analyzer` の出力(ACとテスト観点)を、実際のテストコード雛形に落とす。
- Kotlin(Spring Boot, Kotest BehaviorSpec) / Next.js(Vitest) 両方に対応。

**期待される入力 / Input schema**
- `spec_analyzer` の出力全文
- 対象レイヤ（`backend` or `frontend`）
- 対象モジュールの相対パス
  - 例: `./backend/app/orders/`
  - 例: `./frontend/src/features/orders/`

**期待される出力 / Output schema**
- ファイル単位の提案:
  - 生成/修正したいファイルのパス
  - そのファイルの中身(全量)。可能なら `BehaviorSpec` の describe/context/it 構造、もしくは Vitest の `describe` / `it` 構造を含める。

**ワークフロー**
1. `spec_analyzer` のACを渡す
2. 「backend向けのKotest雛形をください」「frontend向けのVitest雛形をください」と依頼
3. 出力はまだコミットしない。レビュー後に `patch_author` に依頼して差分化する。

**関連ファイル / Related files**
- [./backend/README.md](./backend/README.md)
- [./frontend/README.md](./frontend/README.md)
- [./testing/conventions.md](./testing/conventions.md)

**制限 / Safety**
- 依存ライブラリの追加・gradle編集など、ビルド定義変更は提案はしてもよいが「patchとしては出さない」。その場合は`patch_author`に委譲する、と明記する。

---

## 4. agent: `patch_author`

**役割 / Purpose**
- 既存のコードベースに対して、必要な差分だけを `git diff` 形式で生成する。
- 「テスト追加」や「小さい修正」を安全に適用する。

**期待される入力**
- 「対象ブランチ/ワークツリーのルートパス」
  - 例: `./worktrees/feature-x/`
- 適用したい変更内容の説明
- (あれば) 既存ファイルの抜粋

**期待される出力 / Output schema**
- `diff --git a/... b/...` から始まるパッチのみ
- それ以外の説明テキストは返さない（機械適用しやすくする）

**ワークフロー**
1. 人間が `tdd_writer` のドラフトをレビュー
2. 「じゃあこれをpatchにして」と `patch_author` に渡す
3. `patch_author` の出力を human が `git apply` してレビュー
4. 問題なければcommit

**関連ファイル**
- [./CONTRIBUTING.md](./CONTRIBUTING.md)
- [./worktrees/README.md](./worktrees/README.md)

**制限 / Safety**
- インフラ破壊・DB本番データ変更・シークレット漏えいなどの変更は絶対に含めない
- 影響範囲が大きい場合は `arch_guard` を必須レビューにする

---

## 5. agent: `todo_manager`

**役割**
- `TODO.md` を3階層（親/子/孫）で正規化し、DB同期用の安定した構造に落とす。
- アーカイブ済み項目は同期対象から除外する、などのルールを守らせる。

**関連ファイル**
- [./TODO.md](./TODO.md)
- [./docs/todo-spec.md](./docs/todo-spec.md)
- [./db/schema/todo_tables.sql](./db/schema/todo_tables.sql)
- DBに書き戻す処理やアーカイブ処理の仕様に関わるので、履歴管理・タイムスタンプ更新のポリシーもここで明文化する。

---

## 6. agent: `worktree_planner`

**役割**
- worktree戦略（どこにブランチを切るか、`worktrees/`配下のどこに作業ディレクトリを生やすか）を提案することで、複数端末・複数エージェントでも迷子にならないようにする。

**関連ファイル**
- [./worktrees/README.md](./worktrees/README.md)
- [./scripts/create_worktree.sh](./scripts/create_worktree.sh)

---

## 7. agent: `arch_guard`

**役割**
- 「MCPサーバに全部押し込みすぎてボトルネック化してない？」みたいなアーキテクチャ面のレッドカードを出す係。
- ボトルネックや肥大化を早期に検出して、人間に警告する。

**出力**
- Markdownで「懸念点」と「修正の方向性」を列挙するだけ。
- パッチや自動変更は出さない。

**関連**
- [./docs/architecture/vision.md](./docs/architecture/vision.md)

---

## 8. 廃止済み / Deprecated Agents

`deprecated_sample`
- 旧バージョンのPoCエージェント
- 今後は参照のみ。呼び出し禁止。（履歴参照のため残置）

---

## 9. 追加・更新フロー

1. **要件整理**: 追加/変更したいエージェントの役割・入力・出力・責務境界をメモや issue で明文化する。  
2. **ドラフト編集**: 本テンプレート（実運用では各プロジェクト直下の `AGENTS.md`）を更新し、Registry・詳細セクション・共通ルールを必要に応じて修正する。関連ドキュメントやセットアップ手順（例: `docs/macos-skill-setup.md`, `docs/windows-skill-setup.md`）も合わせて更新する。  
3. **ローカル検証**: Codex CLI / MCP 上で新しいエージェントを仮呼び出しし、入出力スキーマや安全ルールが守られているか確認する。必要なら `.claude/skills` の配置やログ出力を確認。  
4. **人間レビュー**: `owner / reviewer` に指定した担当者が差分と仕様をレビューし、安全ルールや権限範囲の変更が正しいかを承認する。  
5. **ロールアウト**: `todo-api-skills` から各プロジェクトへコピーするスクリプトや手順（`setup-skills.ps1`, `docs/macos-skill-setup.md` 等）を実行し、新しい AGENTS を展開する。  
6. **周知とログ**: 変更内容を `logs/review-notes.md` やリリースノートに記録し、関係者へ周知する。必要に応じて `Deprecated Agents` セクションも更新する。

### 新しいエージェントを追加するとき

1. **エージェント名 (`agent_id`) を決める**  
   - `snake_case` 推奨（例: `reviewer_ops`, `tdd_red_case`）。  
2. **`エージェント一覧 (Registry)` テーブルに 1 行追加する**  
   - `agent_id` / 役割概要 / トリガー例 / 出力物 / status を記入する。  
3. **個別セクションを本ファイル末尾に追記する**  
   - `役割`, `入力`, `出力`, `workflow`, `related files`, `制限` は必須。  
4. **設計ファイルや TODO を `./docs/...` へ置き、`related files` に相対リンクを書く**  
   - 例: `[./docs/specs/xyz.md](./docs/specs/xyz.md)`、 `[./worktrees/feature-x/TODO.md](./worktrees/feature-x/TODO.md)`  
   - Codex CLI / MCP エージェント間で参照を安定させるため、相対パスの Markdown リンクを必ず使用する。  
   - 既存ドキュメントを参照する場合も、ここに明示する。  
5. 共通ルール（命名規則、レスポンス形式、安全ポリシー等）に影響がある場合は、冒頭セクションも更新する。  
6. macOS / Windows 向けセットアップガイドやスクリプトで、新エージェントに必要なファイルコピー手順があれば追記する。  
7. 変更後は人間レビューを経て、`setup-skills` 手順で各プロジェクトに配布する。

### Deprecated にするとき

1. Registry の `status` を `deprecated` に変更し、呼び出し禁止の理由と代替エージェントを記載する（機械側が誤って呼ばないよう明示する）。  
2. 個別セクションに「参照のみ・呼び出し禁止」と履歴を残す目的を明記する。  
3. セットアップ手順やスクリプトからコピー対象を外し、誤って配布されないようにする。  
4. `Deprecated Agents` セクションに経緯と日時を追記し、必要ならリンクやチケット番号も残す。  
