#!/usr/bin/env python3
import argparse
import csv
import sys
from pathlib import Path

from importlib.machinery import SourceFileLoader


def load_normalizer(normalizer_path: Path):
    module = SourceFileLoader("normalize_text", str(normalizer_path)).load_module()
    return module.normalize_korean_text


def main() -> None:
    parser = argparse.ArgumentParser(description="segments CSV -> Piper metadata.csv 생성")
    parser.add_argument("--segments-csv", type=Path, required=True, help="02_split_audio.py 결과 CSV")
    parser.add_argument("--output", type=Path, required=True, help="metadata.csv 출력 경로")
    parser.add_argument(
        "--normalizer",
        type=Path,
        default=Path(__file__).parent / "04_normalize_text.py",
        help="텍스트 정규화 스크립트 경로",
    )
    parser.add_argument("--remove-parentheses", action="store_true")
    args = parser.parse_args()

    if not args.segments_csv.exists():
        print(f"오류: segments CSV 파일이 없습니다: {args.segments_csv}", file=sys.stderr)
        sys.exit(1)

    if not args.normalizer.exists():
        print(f"오류: 정규화 스크립트를 찾을 수 없습니다: {args.normalizer}", file=sys.stderr)
        sys.exit(1)

    normalize = load_normalizer(args.normalizer)

    rows_out = []
    with args.segments_csv.open("r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            wav = row.get("wav", "").strip()
            text = row.get("text", "").strip()
            if not wav or not text:
                continue

            norm = normalize(text, remove_parentheses=args.remove_parentheses)
            if not norm:
                continue

            wav_stem = Path(wav).stem
            rows_out.append(f"{wav_stem}|{norm}")

    if not rows_out:
        print("오류: metadata에 기록할 유효 데이터가 없습니다.", file=sys.stderr)
        sys.exit(1)

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text("\n".join(rows_out) + "\n", encoding="utf-8")
    print(f"완료: metadata 생성 -> {args.output} ({len(rows_out)} rows)")


if __name__ == "__main__":
    main()
