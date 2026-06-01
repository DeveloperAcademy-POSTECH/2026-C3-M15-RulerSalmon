#!/usr/bin/env python3
import argparse
import re
import sys
from pathlib import Path


def normalize_korean_text(text: str, remove_parentheses: bool = False) -> str:
    # 앞뒤 공백 및 줄바꿈 정리
    normalized = text.strip().replace("\n", " ").replace("\t", " ")

    # 따옴표/아포스트로피 통일
    normalized = normalized.replace("“", '"').replace("”", '"')
    normalized = normalized.replace("‘", "'").replace("’", "'")

    # 괄호 안 불필요한 내용 제거 (옵션)
    if remove_parentheses:
        normalized = re.sub(r"\([^)]*\)", " ", normalized)
        normalized = re.sub(r"\[[^\]]*\]", " ", normalized)

    # 허용할 문자: 한글, 영문, 숫자, 기본 문장부호
    normalized = re.sub(r"[^0-9A-Za-z가-힣ㄱ-ㅎㅏ-ㅣ\s.,?!'\"%-/:]", " ", normalized)

    # 중복 공백 정리
    normalized = re.sub(r"\s+", " ", normalized).strip()

    # TODO: 숫자/영어/약어 발음 정규화
    # - 123 -> 백이십삼 / 일이삼 선택
    # - iOS -> 아이오에스
    # - API -> 에이피아이
    # - % -> 퍼센트
    # - 날짜/시간 정규화

    return normalized


def main() -> None:
    parser = argparse.ArgumentParser(description="한국어 TTS 텍스트 정규화")
    parser.add_argument("--text", type=str, help="정규화할 단일 텍스트")
    parser.add_argument("--input", type=Path, help="입력 텍스트 파일 경로")
    parser.add_argument("--output", type=Path, help="출력 텍스트 파일 경로")
    parser.add_argument(
        "--remove-parentheses",
        action="store_true",
        help="괄호 안 내용을 제거합니다.",
    )
    args = parser.parse_args()

    if not args.text and not args.input:
        parser.error("--text 또는 --input 중 하나는 반드시 필요합니다.")

    if args.text:
        print(normalize_korean_text(args.text, remove_parentheses=args.remove_parentheses))
        return

    if not args.input.exists():
        print(f"오류: 입력 파일을 찾을 수 없습니다: {args.input}", file=sys.stderr)
        sys.exit(1)

    raw = args.input.read_text(encoding="utf-8")
    normalized = "\n".join(
        normalize_korean_text(line, remove_parentheses=args.remove_parentheses)
        for line in raw.splitlines()
    )

    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(normalized + "\n", encoding="utf-8")
        print(f"완료: 정규화 결과 저장 -> {args.output}")
    else:
        print(normalized)


if __name__ == "__main__":
    main()
