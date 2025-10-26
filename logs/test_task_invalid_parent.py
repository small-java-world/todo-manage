"""
TDD RED テストケース: 存在しないparent_idでタスク作成時の404エラー

受入条件:
- タスク作成時に parent_id が存在しない場合、404 エラーを返すこと

このテストは、TDD の RED フェーズで作成されました。
現在の実装では、このテストは失敗する（または異なるエラーを返す）可能性があります。
"""

import pytest
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)


def test_task_creation_with_invalid_parent_id():
    """存在しない parent_id を指定した場合、404 を返すこと"""

    # 存在しないparent_idを指定してタスクを作成
    response = client.post(
        "/tasks/",
        json={
            "title": "Invalid Parent Task",
            "type": "task",
            "parent_id": 99999  # 存在しないID
        }
    )

    # 404エラーが返ることを確認
    assert response.status_code == 404, (
        f"Expected status code 404, but got {response.status_code}. "
        f"Response: {response.json()}"
    )

    # エラーメッセージに "parent" が含まれることを確認（オプション）
    error_detail = response.json().get("detail", "")
    assert "parent" in error_detail.lower(), (
        f"Expected error message to mention 'parent', but got: {error_detail}"
    )


# TDD サイクルの説明
"""
RED フェーズ (現在):
- このテストは、存在しない parent_id を指定した場合に 404 エラーを返すという
  受入条件を検証します。
- 現在の実装では、このテストは失敗する可能性があります。

GREEN フェーズ (次のステップ):
- このテストだけを通す最小の実装を追加します:
  1. parent_id が指定されている場合、そのタスクが存在するか確認
  2. 存在しない場合は HTTPException(status_code=404) を発生させる
  3. 存在する場合のみタスクを作成

REFACTOR フェーズ (その後):
- 重複コードの排除
- 変数名や関数名の改善
- 設計の整合性を確認
- 他の親子関係バリデーションとの統合
"""
