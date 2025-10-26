# OpenSpec + ChatGPT 連携メモ

`spec-driven-context.zip` は、todo-manage で扱う仕様ドキュメントを最小限のセットにまとめ、ChatGPT / Claude へワンショットで共有するためのバンドルです。本メモでは zip の中身・再生成手順・質問テンプレートをまとめます。

---

## 1. 目的
- **仕様書駆動のコンテキスト共有**: OpenSpec や Codex CLI に渡したい基礎ドキュメントを 1 ファイルで共有する。
- **エージェント境界の可視化**: `docs/AGENTS.template.md` を必ず同梱し、どのエージェントに何を任せるかを AI に先に理解させる。
- **OS 別セットアップの差異を明示**: macOS / Windows の Skill 配置手順を同梱し、どちらの端末でも再現できる状態を保つ。

---

## 2. バンドル対象リスト

| パス | 用途 |
|------|------|
| `README.md` | ワークスペース全体像と依存関係の説明 |
| `README.windows.md` | Windows 固有手順。PowerShell で確認してもらう際に参照させる |
| `WINDOWS_VERIFICATION_CHECKLIST.md` | Windows 検証タスクリスト。AI に「この観点を満たしたか？」と問いかけやすい |
| `docs/AGENTS.template.md` | Codex CLI / MCP 向け AGENTS レジストリの仕様書 |
| `docs/macos-skill-setup.md` | macOS で Skill / AGENTS を複製するシェルスクリプト例 |
| `docs/windows-skill-setup.md` | Windows で Skill / AGENTS を複製する PowerShell 手順 |
| `docs/openspec-chatgpt-prompt.md` | このメモ自身。zip を受け取った人が意図を誤読しないようにする |
| `todo-api/README.md` | TODO API 本体の仕様書 |
| `todo-api/README.windows.md` | API を Windows で動かす際の補足 |
| `todo-api-client-sample/README.md` | クライアントサンプルで何が出来るか |
| `todo-api-client-sample/README.windows.md` | クライアントを Windows で起動する際の注意 |
| `todo-api-skills/README.md` | Claude Skills / Codex CLI 用アセットの中身 |
| `todo-api-skills/README.windows.md` | 上記の Windows 手順（PowerShell 版） |

必要に応じて他の仕様書（例: `docs/windows-port-block-test.md`）も追加してよいが、zip が肥大化しすぎると ChatGPT 側で展開に失敗することがある点に注意する。

---

## 3. zip の再生成手順

PowerShell から以下を実行すると、上記ファイルだけを再パッケージできます。

```powershell
$paths = @(
  'README.md',
  'README.windows.md',
  'WINDOWS_VERIFICATION_CHECKLIST.md',
  'docs/AGENTS.template.md',
  'docs/macos-skill-setup.md',
  'docs/windows-skill-setup.md',
  'docs/openspec-chatgpt-prompt.md',
  'todo-api/README.md',
  'todo-api/README.windows.md',
  'todo-api-client-sample/README.md',
  'todo-api-client-sample/README.windows.md',
  'todo-api-skills/README.md',
  'todo-api-skills/README.windows.md'
)

Remove-Item -Force spec-driven-context.zip -ErrorAction SilentlyContinue
Compress-Archive -Path $paths -DestinationPath spec-driven-context.zip
```

> 注意: すべて UTF-8 (BOM なし) で保存すること。Windows で作業する場合は `git config --global core.autocrlf false` にしておくと、差分が増えにくい。

---

## 4. ChatGPT / Claude への質問テンプレ

OpenSpec をベースに TODO 管理フローを整理してもらう際の例です。zip を添付したうえで以下を貼り付けます：

```
目的:
- `todo-manage` リポジトリの spec-driven 運用ルールを OpenSpec 形式に落とし込みたい
- Codex CLI / Claude Skills の AGENTS 分担を壊さず、必要な仕様差分を整理したい

提供物:
- 同梱した `spec-driven-context.zip` を展開して内容を把握してください
- OpenSpec: https://github.com/Fission-AI/OpenSpec を参照し、既存テンプレートのどれを流用すべきか提案してください

依頼:
1. zip 内の README / docs を読み、現状のエージェント分担とセットアップ手順を要約する
2. OpenSpec のテンプレート構成にマッピングした表を返す（Section 名、対応するファイル、補足）
3. 不足している仕様 or テンプレがあれば列挙し、`docs/AGENTS.template.md` のどこを拡張すべきか提案する
4. 追加で必要なログ / 設定を聞くときは、参照して良い相対パスを列挙してから質問する
```

必要に応じて「今回のタスク」「対象スプリント」などを冒頭に追記する。LLM に余計な書き換えをさせないため、「自動コミット禁止」「Codex CLI の AGENTS を改変する際は人間レビュー必須」といった制約文を添えておくと安全。

---

## 5. 運用ノート
- zip を更新したら `git status` で差分を確認し、README などの内容も同時に更新した理由をコミットメッセージに残す。
- `spec-driven-context.zip` を添付できないツール（API 経由など）の場合は、zip の内容をそのまま `OpenSpec` issue に貼る案も検討する。
- ChatGPT 側で zip 展開に失敗した場合は、表形式で分割しながら順次投稿する fallback 手順を `logs/review-notes.md` に追記すること。
