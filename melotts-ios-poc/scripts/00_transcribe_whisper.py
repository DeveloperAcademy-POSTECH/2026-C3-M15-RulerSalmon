#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

from faster_whisper import WhisperModel


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Create a draft Korean transcript with timestamps using faster-whisper."
    )
    parser.add_argument("--input", required=True, help="Path to input audio file.")
    parser.add_argument(
        "--output",
        default="input/transcript.txt",
        help="Output transcript path. Default: input/transcript.txt",
    )
    parser.add_argument(
        "--model",
        default="small",
        help="Whisper model size or local model path. Example: tiny, base, small, medium",
    )
    parser.add_argument(
        "--device",
        default="cpu",
        choices=["cpu", "auto"],
        help="Inference device for faster-whisper. Use auto if your environment is configured for acceleration.",
    )
    parser.add_argument(
        "--compute-type",
        default="int8",
        help="faster-whisper compute type. Common values: int8, int8_float16, float16",
    )
    parser.add_argument(
        "--language",
        default="ko",
        help="Language hint passed to Whisper. Default: ko",
    )
    parser.add_argument(
        "--beam-size",
        type=int,
        default=5,
        help="Beam size for decoding. Default: 5",
    )
    parser.add_argument(
        "--write-json",
        action="store_true",
        help="Also save a JSON file with raw segment metadata next to the transcript.",
    )
    return parser


def format_timestamp(seconds: float) -> str:
    return f"{seconds:.2f}"


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()

    input_path = Path(args.input)
    output_path = Path(args.output)

    if not input_path.exists():
        parser.error(f"Input audio file does not exist: {input_path}")

    output_path.parent.mkdir(parents=True, exist_ok=True)

    try:
        model = WhisperModel(args.model, device=args.device, compute_type=args.compute_type)
    except Exception as exc:
        raise SystemExit(
            "Failed to initialize faster-whisper model. "
            "Check whether the model name is valid and the package is installed.\n"
            f"Details: {exc}"
        ) from exc

    try:
        segments, info = model.transcribe(
            str(input_path),
            language=args.language,
            beam_size=args.beam_size,
            vad_filter=True,
        )
    except Exception as exc:
        raise SystemExit(
            "Failed to transcribe the input audio with faster-whisper.\n"
            f"Details: {exc}"
        ) from exc

    transcript_lines: list[str] = []
    json_segments: list[dict[str, object]] = []

    for segment in segments:
        text = segment.text.strip()
        if not text:
            continue

        start = format_timestamp(segment.start)
        end = format_timestamp(segment.end)
        transcript_lines.append(f"{start}\t{end}\t{text}")
        json_segments.append(
            {
                "start": segment.start,
                "end": segment.end,
                "text": text,
            }
        )

    if not transcript_lines:
        raise SystemExit("No usable transcript segments were produced from the input audio.")

    output_path.write_text("\n".join(transcript_lines) + "\n", encoding="utf-8")

    if args.write_json:
        json_path = output_path.with_suffix(".segments.json")
        json_path.write_text(
            json.dumps(
                {
                    "language": getattr(info, "language", args.language),
                    "duration": getattr(info, "duration", None),
                    "segments": json_segments,
                },
                ensure_ascii=False,
                indent=2,
            )
            + "\n",
            encoding="utf-8",
        )

    print(f"Draft transcript written to: {output_path}")
    print("Please review the transcript before building the training dataset.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
