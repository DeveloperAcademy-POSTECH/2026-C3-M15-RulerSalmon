#!/usr/bin/env python3
from __future__ import annotations

import argparse
import csv
import sys
from pathlib import Path


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Build MeloTTS metadata.list from reviewed CSV.")
    parser.add_argument("--input", required=True, help="Path to metadata.review.csv")
    parser.add_argument("--output", required=True, help="Path to metadata.list")
    parser.add_argument(
        "--speaker-name",
        default="Speaker01",
        help="Speaker name written to metadata.list. Example: DevPaul",
    )
    parser.add_argument(
        "--language-code",
        default="KR",
        help="MeloTTS language code. Korean uses KR.",
    )
    return parser


def format_line(row: dict[str, str], speaker_name: str, language_code: str) -> str:
    text = row["text"].strip()
    wav_path = row["wav_path"].strip()
    return f"{wav_path}|{speaker_name}|{language_code}|{text}"


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()

    input_path = Path(args.input)
    output_path = Path(args.output)

    if not input_path.exists():
        parser.error(f"Input CSV does not exist: {input_path}")

    lines: list[str] = []
    with input_path.open("r", encoding="utf-8", newline="") as fp:
        reader = csv.DictReader(fp)
        for row in reader:
            if row.get("status", "").strip().lower() == "skip":
                continue
            text = row.get("text", "").strip()
            if not text:
                continue
            lines.append(format_line(row, args.speaker_name, args.language_code))

    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text("\n".join(lines) + "\n", encoding="utf-8")

    print(f"Metadata written to: {output_path}")
    print(f"Speaker name: {args.speaker_name}")
    print(f"Language code: {args.language_code}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
