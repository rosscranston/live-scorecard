from __future__ import annotations

import importlib.util
import json
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("sync_policy", ROOT / "scripts" / "sync_policy.py")
module = importlib.util.module_from_spec(spec)
assert spec.loader
spec.loader.exec_module(module)
POLICY = json.loads((ROOT / "config" / "sync-policy.json").read_text())


class SyncPolicyTests(unittest.TestCase):
    def test_learning_change_is_allowed(self) -> None:
        result = module.classify(["state/audits/2026-08-15.json"], POLICY)
        self.assertEqual(["state/audits/2026-08-15.json"], result["allowed"])

    def test_skill_instruction_is_protected(self) -> None:
        result = module.classify(["skills/day-operator/SKILL.md"], POLICY)
        self.assertEqual(["skills/day-operator/SKILL.md"], result["protected"])

    def test_secret_path_is_forbidden(self) -> None:
        result = module.classify(["config/connectors.yaml"], POLICY)
        self.assertEqual(["config/connectors.yaml"], result["forbidden"])

    def test_unclassified_document_requires_manual_review(self) -> None:
        result = module.classify(["README.md"], POLICY)
        self.assertEqual(["README.md"], result["unclassified"])


if __name__ == "__main__":
    unittest.main()
