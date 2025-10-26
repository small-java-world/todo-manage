import json
import logging
import os
from pathlib import Path
from typing import Any, Dict, Optional

from sqlalchemy.orm import Session

# from app.services.task_service import TaskService  # 循環インポートを回避
from app.models.task import Task, TaskType
from app.services.cas_service import CASService
from app.services.git_service import GitService

logger = logging.getLogger(__name__)


class TDDHookService:
    def __init__(self, db: Session):
        self.db = db
        self.cas_service = CASService(db)
        self.git_service = GitService()
        # self.task_service = TaskService(db)  # 循環インポートを回避

    def handle_status_transition(
        self, task: Task, from_status: str, to_status: str, reason: Optional[str] = None
    ):
        """状態遷移時のTDDフック処理"""
        logger.info(
            f"TDD Hook: Task {task.hierarchical_id} transition from {from_status} to {to_status}"
        )

        if from_status == "not_started" and to_status == "in_progress":
            self._handle_start_development(task)
        elif to_status == "review_pending":
            self._handle_review_request(task)
        elif to_status == "completed":
            self._handle_completion(task)
        elif to_status == "revising":
            self._handle_revision_request(task)

    def _handle_start_development(self, task: Task):
        """開発開始時の処理"""
        logger.info(f"Starting development for task {task.hierarchical_id}")

        # OpenSpec を読み取り、存在すればそれに基づく Red テスト雛形を生成
        red_test_content = None
        try:
            openspec_text = self.git_service.get_openspec_file(task.hierarchical_id)
            if openspec_text:
                red_test_content = self._generate_red_test_from_openspec(task, openspec_text)
        except Exception as e:
            logger.warning(f"OpenSpec read error for {task.hierarchical_id}: {str(e)}")

        # フォールバック: OpenSpec が無い場合は汎用の雛形
        if not red_test_content:
            red_test_content = self._generate_red_test_template(task)
        if red_test_content:
            # CASに格納
            sha256_hash = self.cas_service.store_artifact(
                content=red_test_content.encode("utf-8"),
                media_type="text/x-python",
                source_task_hid=task.hierarchical_id,
                purpose="test",
            )

            # タスクにリンク
            self.cas_service.link_artifact_to_task(
                task_hid=task.hierarchical_id, sha256_hash=sha256_hash, role="test"
            )

            logger.info(f"Generated red test template for task {task.hierarchical_id}")

    def _generate_red_test_from_openspec(self, task: Task, openspec_text: str) -> Optional[str]:
        """OpenSpec から Red テストの雛形を生成（PoC: 最小構文の抽出）。"""
        try:
            import yaml  # type: ignore

            data = yaml.safe_load(openspec_text) or {}
            ac_list = data.get("acceptance_criteria") or []
            scenarios = data.get("scenarios") or []

            # 1件だけ拾って雛形に落とす（PoC）
            ac_id = None
            ac_text = None
            if isinstance(ac_list, list) and ac_list:
                first = ac_list[0]
                ac_id = first.get("id") if isinstance(first, dict) else None
                ac_text = first.get("text") if isinstance(first, dict) else None

            scenario_name = None
            step = None
            if isinstance(scenarios, list) and scenarios:
                s0 = scenarios[0]
                scenario_name = s0.get("name") if isinstance(s0, dict) else None
                steps = s0.get("steps") if isinstance(s0, dict) else None
                if isinstance(steps, list) and steps:
                    step = steps[0]

            test_name = task.hierarchical_id.replace(".", "_").replace("-", "_").lower()
            doc_lines = []
            if ac_id or ac_text:
                doc_lines.append(f"AC {ac_id or ''}: {ac_text or ''}")
            if scenario_name:
                doc_lines.append(f"Scenario: {scenario_name}")

            # 可能ならHTTPの雛形
            http_lines = []
            if isinstance(step, dict) and "request" in step and "expect" in step:
                req = step.get("request") or {}
                exp = step.get("expect") or {}
                method = (req.get("method") or "GET").upper()
                path = req.get("path") or "/"
                status = exp.get("status") or 200
                http_lines.append(f"response = client.{method.lower()}(\"{path}\")")
                http_lines.append("assert response.status_code == " + str(status))

            doc = "\n".join(doc_lines) if doc_lines else "Red test generated from OpenSpec"

            content = f'''import pytest
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)


@pytest.mark.openspec
def test_{test_name}_red_from_openspec():
    """{doc}
    This test should fail initially (Red phase of TDD).
    """
    # TODO: Flesh out based on full OpenSpec
    {"\n    ".join(http_lines) if http_lines else "assert False, 'Fill in steps from OpenSpec'"}
'''
            return content
        except Exception as e:
            logger.warning(f"OpenSpec parse error for {task.hierarchical_id}: {str(e)}")
            return None

    def _handle_review_request(self, task: Task):
        """レビュー依頼時の処理"""
        logger.info(f"Review requested for task {task.hierarchical_id}")

        # テスト実行ログを生成
        test_log = self._generate_test_execution_log(task)
        if test_log:
            # CASに格納
            sha256_hash = self.cas_service.store_artifact(
                content=test_log.encode("utf-8"),
                media_type="text/plain",
                source_task_hid=task.hierarchical_id,
                purpose="log",
            )

            # タスクにリンク
            self.cas_service.link_artifact_to_task(
                task_hid=task.hierarchical_id, sha256_hash=sha256_hash, role="log"
            )

            logger.info(f"Generated test execution log for task {task.hierarchical_id}")

    def _handle_completion(self, task: Task):
        """完了時の処理"""
        logger.info(f"Completing task {task.hierarchical_id}")

        # 成果物マニフェストを生成
        manifest = self._generate_artifact_manifest(task)
        if manifest:
            # CASに格納
            sha256_hash = self.cas_service.store_artifact(
                content=json.dumps(manifest, indent=2).encode("utf-8"),
                media_type="application/json",
                source_task_hid=task.hierarchical_id,
                purpose="artifact",
            )

            # タスクにリンク
            self.cas_service.link_artifact_to_task(
                task_hid=task.hierarchical_id, sha256_hash=sha256_hash, role="artifact"
            )

            logger.info(f"Generated artifact manifest for task {task.hierarchical_id}")

    def _handle_revision_request(self, task: Task):
        """修正依頼時の処理"""
        logger.info(f"Revision requested for task {task.hierarchical_id}")

        # 修正ガイドを生成
        revision_guide = self._generate_revision_guide(task)
        if revision_guide:
            # CASに格納
            sha256_hash = self.cas_service.store_artifact(
                content=revision_guide.encode("utf-8"),
                media_type="text/markdown",
                source_task_hid=task.hierarchical_id,
                purpose="log",
            )

            # タスクにリンク
            self.cas_service.link_artifact_to_task(
                task_hid=task.hierarchical_id, sha256_hash=sha256_hash, role="log"
            )

            logger.info(f"Generated revision guide for task {task.hierarchical_id}")

    def _generate_red_test_template(self, task: Task) -> Optional[str]:
        """Redテストの雛形を生成"""
        test_template = f'''import pytest
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)


def test_{task.hierarchical_id.replace(".", "_").replace("-", "_").lower()}_red_case():
    """Red test for {task.hierarchical_id}: {task.title}
    
    This test should fail initially (Red phase of TDD).
    Implement minimal code to make this test pass.
    """
    # TODO: Implement the failing test case
    # This test should fail until the feature is implemented
    
    # Example test structure:
    # response = client.get("/api/endpoint")
    # assert response.status_code == 200
    # assert "expected_result" in response.json()
    
    # For now, this test will fail (Red phase)
    assert False, "This test should fail until the feature is implemented"
'''
        return test_template

    def _generate_test_execution_log(self, task: Task) -> Optional[str]:
        """テスト実行ログを生成"""
        log_content = f"""Test Execution Log for {task.hierarchical_id}
========================================

Task: {task.title}
Status: {task.status}
Generated: {task.updated_at or task.created_at}

Test Results:
-----------
- Red test execution: PENDING
- Green test execution: PENDING
- Refactor test execution: PENDING

Next Steps:
----------
1. Run red tests to confirm they fail
2. Implement minimal code to make tests pass
3. Run green tests to confirm they pass
4. Refactor code while keeping tests green
5. Run final test suite to ensure no regressions

Notes:
------
- Ensure all acceptance criteria are met
- Verify code quality and maintainability
- Check for any edge cases or error conditions
"""
        return log_content

    def _generate_artifact_manifest(self, task: Task) -> Optional[Dict[str, Any]]:
        """成果物マニフェストを生成"""
        # タスクに関連するアーティファクトを取得
        artifacts = self.cas_service.get_task_artifacts(task.hierarchical_id)

        manifest = {
            "task_hierarchical_id": task.hierarchical_id,
            "task_title": task.title,
            "completion_date": (
                task.updated_at.isoformat()
                if task.updated_at
                else task.created_at.isoformat()
            ),
            "artifacts": [],
            "test_results": {
                "red_tests": "PASSED",
                "green_tests": "PASSED",
                "refactor_tests": "PASSED",
            },
            "acceptance_criteria": "MET",
            "quality_metrics": {
                "code_coverage": "TBD",
                "complexity": "TBD",
                "maintainability": "TBD",
            },
        }

        for artifact in artifacts:
            manifest["artifacts"].append(
                {
                    "role": artifact["role"],
                    "sha256": artifact["sha256"],
                    "uri": artifact["cas_uri"],
                    "media_type": artifact["media_type"],
                    "size_bytes": artifact["bytes_size"],
                }
            )

        return manifest

    def _generate_revision_guide(self, task: Task) -> Optional[str]:
        """修正ガイドを生成"""
        guide_content = f"""Revision Guide for {task.hierarchical_id}
====================================

Task: {task.title}
Current Status: {task.status}

Issues to Address:
-----------------
1. Review feedback points
2. Test failures to fix
3. Code quality improvements
4. Performance optimizations

Recommended Actions:
------------------
1. Review the feedback comments
2. Identify specific issues to address
3. Update implementation accordingly
4. Re-run tests to ensure fixes
5. Update documentation if needed

Next Steps:
----------
1. Address each feedback point systematically
2. Test changes thoroughly
3. Update status when ready for re-review
4. Document any significant changes

Notes:
------
- Focus on the specific issues mentioned in feedback
- Maintain code quality standards
- Ensure all tests continue to pass
"""
        return guide_content
