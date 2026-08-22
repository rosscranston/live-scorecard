#!/usr/bin/env python3
"""Deterministic first-pass semantic duplicate guard for cards and records."""
from __future__ import annotations

import argparse
import json
import re
import sys
import unicodedata
from difflib import SequenceMatcher
from pathlib import Path

STOP_PHRASES = (
    "can you tell me", "could you tell me", "how do you", "what is the",
    "what's the", "please explain", "tell me about"
)

CANONICAL_TOKENS = {
    "price": "cost",
    "prices": "cost",
    "pricing": "cost",
    "priced": "cost",
    "fee": "cost",
    "fees": "cost",
    "charge": "cost",
    "charges": "cost",
    "rate": "cost",
    "rates": "cost",
}

# Remove generic question scaffolding while retaining business-specific modifiers
# such as "per return", "integration", or "security".
STOP_TOKENS = {
    "a", "an", "the", "is", "are", "was", "were", "do", "does", "did",
    "it", "this", "that", "our", "your", "my", "we", "you", "me",
    "much", "how", "what", "please", "product",
}


def normalize(value: str) -> str:
    value = unicodedata.normalize("NFKC", value).lower().strip()
    for phrase in STOP_PHRASES:
        value = value.replace(phrase, " ")
    value = re.sub(r"[^a-z0-9]+", " ", value)
    tokens = [CANONICAL_TOKENS.get(token, token) for token in value.split()]
    tokens = [token for token in tokens if token not in STOP_TOKENS]
    return " ".join(tokens)


def token_jaccard(a: str, b: str) -> float:
    left, right = set(a.split()), set(b.split())
    if not left and not right:
        return 1.0
    if not left or not right:
        return 0.0
    return len(left & right) / len(left | right)


def score(a: str, b: str) -> float:
    na, nb = normalize(a), normalize(b)
    if na == nb:
        return 1.0
    sequence = SequenceMatcher(None, na, nb).ratio()
    jaccard = token_jaccard(na, nb)
    return round((0.55 * sequence) + (0.45 * jaccard), 4)


def read_existing(path: Path, field: str) -> list[dict]:
    data = json.loads(path.read_text(encoding="utf-8"))
    if isinstance(data, dict):
        data = data.get("items", data.get("records", []))
    if not isinstance(data, list):
        raise ValueError("Existing file must contain a JSON array or an object with items/records")
    records = []
    for idx, item in enumerate(data):
        if isinstance(item, str):
            records.append({"id": str(idx), "value": item})
        elif isinstance(item, dict) and field in item:
            records.append({"id": str(item.get("id", idx)), "value": str(item[field])})
    return records


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--candidate", required=True)
    parser.add_argument("--existing-file", type=Path, required=True)
    parser.add_argument("--field", default="question")
    parser.add_argument("--duplicate-threshold", type=float, default=0.86)
    parser.add_argument("--review-threshold", type=float, default=0.72)
    args = parser.parse_args()

    records = read_existing(args.existing_file, args.field)
    ranked = sorted(
        ({"id": r["id"], "value": r["value"], "score": score(args.candidate, r["value"])} for r in records),
        key=lambda x: x["score"], reverse=True
    )
    top = ranked[:5]
    best = top[0]["score"] if top else 0.0
    if best >= args.duplicate_threshold:
        status = "duplicate"
        exit_code = 2
    elif best >= args.review_threshold:
        status = "possible_duplicate"
        exit_code = 1
    else:
        status = "clear"
        exit_code = 0
    print(json.dumps({
        "candidate": args.candidate,
        "normalized": normalize(args.candidate),
        "status": status,
        "best_score": best,
        "matches": top
    }, indent=2, ensure_ascii=False))
    return exit_code


if __name__ == "__main__":
    raise SystemExit(main())
