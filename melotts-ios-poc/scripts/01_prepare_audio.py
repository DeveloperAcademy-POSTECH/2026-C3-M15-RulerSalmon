#!/usr/bin/env python3
from __future__ import annotations

import argparse
import shutil
import subprocess
import sys
from pathlib import Path


SUPPORTED_SAMPLE_RATES = [44100, 24000, 22050]


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Prepare raw speech audio for MeloTTS training.")
    parser.add_argument("--input", required=True, help="Path to the raw input audio file.")
    parser.add_argument("--output", required=True, help="Path to the prepared mono WAV file.")
    parser.add_argument(
        "--sample-rate",
        type=int,
        default=44100,
        choices=SUPPORTED_SAMPLE_RATES,
        help="Target sample rate. Use the MeloTTS-recommended value for your chosen fork when known.",
    )
    parser.add_argument(
        "--trim-silence",
        action="store_true",
        help="Remove long silence regions using ffmpeg silenceremove.",
    )
    parser.add_argument(
        "--loudness-target",
        default="-16",
        help="Loudness normalization target in LUFS for ffmpeg loudnorm.",
    )
    return parser


def ensure_ffmpeg() -> None:
    if shutil.which("ffmpeg") is None:
        raise RuntimeError("ffmpeg is not installed or not available in PATH. Please install ffmpeg first.")


def build_filter_chain(trim_silence: bool, loudness_target: str) -> str:
    filters = [f"loudnorm=I={loudness_target}:TP=-1.5:LRA=11"]
    if trim_silence:
        filters.append("silenceremove=start_periods=1:start_silence=0.4:start_threshold=-40dB:stop_periods=-1:stop_silence=0.5:stop_threshold=-40dB")
    return ",".join(filters)


def run_ffmpeg(input_path: Path, output_path: Path, sample_rate: int, filter_chain: str) -> None:
    output_path.parent.mkdir(parents=True, exist_ok=True)
    command = [
        "ffmpeg",
        "-y",
        "-i",
        str(input_path),
        "-ac",
        "1",
        "-ar",
        str(sample_rate),
        "-vn",
        "-af",
        filter_chain,
        str(output_path),
    ]

    completed = subprocess.run(command, capture_output=True, text=True)
    if completed.returncode != 0:
        message = completed.stderr.strip() or completed.stdout.strip() or "Unknown ffmpeg error"
        raise RuntimeError(f"Failed to prepare audio with ffmpeg. Details: {message}")


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()

    input_path = Path(args.input)
    output_path = Path(args.output)

    if not input_path.exists():
        parser.error(f"Input audio file does not exist: {input_path}")

    ensure_ffmpeg()
    filter_chain = build_filter_chain(args.trim_silence, args.loudness_target)
    run_ffmpeg(input_path, output_path, args.sample_rate, filter_chain)

    print(f"Prepared audio saved to: {output_path}")
    print(f"Sample rate: {args.sample_rate} Hz")
    return 0


if __name__ == "__main__":
    sys.exit(main())
