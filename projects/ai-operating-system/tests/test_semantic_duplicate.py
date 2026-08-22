from __future__ import annotations

import importlib.util
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("duplicate_guard", ROOT / "scripts" / "semantic_duplicate_guard.py")
module = importlib.util.module_from_spec(spec)
assert spec.loader
spec.loader.exec_module(module)


class DuplicateTests(unittest.TestCase):
    def test_normalized_same_question(self) -> None:
        self.assertEqual(
            module.normalize("How much does it cost?"),
            module.normalize("Can you tell me how much does it cost")
        )

    def test_unrelated_questions_score_low(self) -> None:
        self.assertLess(module.score("How much does it cost?", "How is client data encrypted?"), 0.5)

    def test_same_question_scores_high(self) -> None:
        self.assertGreaterEqual(module.score("What is the price?", "What is the pricing?"), 0.7)

    def test_pricing_intent_survives_question_scaffolding(self) -> None:
        self.assertEqual(
            module.normalize("What is the pricing?"),
            module.normalize("How much does the product cost?"),
        )


if __name__ == "__main__":
    unittest.main()
