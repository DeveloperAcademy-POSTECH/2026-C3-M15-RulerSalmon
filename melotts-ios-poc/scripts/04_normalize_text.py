#!/usr/bin/env python3
from __future__ import annotations

import argparse
import re
import sys


def normalize_text(text: str, remove_parentheses: bool = False) -> str:
    value = text.strip()
    value = value.replace("“", '"').replace("”", '"').replace("‘", "'").replace("’", "'")
    value = value.replace("\n", " ").replace("\r", " ")

    if remove_parentheses:
        value = re.sub(r"\([^)]*\)", " ", value)
        value = re.sub(r"\[[^\]]*\]", " ", value)

    value = re.sub(r"[^0-9A-Za-z가-힣ㄱ-ㅎㅏ-ㅣ\s.,!?%:/'-]", " ", value)
    value = re.sub(r"\s+", " ", value)
    value = re.sub(r"\s+([.,!?])", r"\1", value)
    return value.strip()


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Normalize Korean transcript text for MeloTTS metadata.")
    parser.add_argument("--text", required=True, help="Input text to normalize")
    parser.add_argument("--remove-parentheses", action="store_true", help="Remove text inside parentheses or brackets")
    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()

    result = normalize_text(args.text, remove_parentheses=args.remove_parentheses)
    print(result)
    print("# TODO: 123 -> 백이십삼 or 일이삼")
    print("# TODO: iOS -> 아이오에스")
    print("# TODO: API -> 에이피아이")
    print("# TODO: % -> 퍼센트")
    print("# TODO: 날짜/시간 정규화")
    print("# TODO: 고유명사 사전 처리")
    return 0


if __name__ == "__main__":
    sys.exit(main())
