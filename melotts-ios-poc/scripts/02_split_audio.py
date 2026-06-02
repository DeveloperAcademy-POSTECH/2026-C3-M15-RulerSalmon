#!/usr/bin/env python3
from __future__ import annotations

import argparse
import csv
import re
import sys
import wave
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable


MIN_SECONDS = 1.5
MAX_SECONDS = 12.0
TARGET_MIN = 3.0
TARGET_MAX = 12.0


@dataclass
class Segment:
    start: float
    end: float
    text: str

    @property
    def duration(self) -> float:
        return self.end - self.start


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Split prepared speech audio into clip files and review metadata.")
    parser.add_argument("--input", required=True, help="Prepared WAV input.")
    parser.add_argument("--transcript", required=True, help="Transcript path. Timestamped TSV is preferred.")
    parser.add_argument("--output-dir", required=True, help="Dataset output directory.")
    parser.add_argument("--min-seconds", type=float, default=MIN_SECONDS)
    parser.add_argument("--max-seconds", type=float, default=MAX_SECONDS)
    return parser


def parse_timestamped_line(line: str) -> Segment | None:
    parts = line.strip().split("\t")
    if len(parts) < 3:
        return None
    try:
        start = float(parts[0])
        end = float(parts[1])
    except ValueError:
        return None
    text = "\t".join(parts[2:]).strip()
    if not text:
        return None
    return Segment(start=start, end=end, text=text)


def load_segments(transcript_path: Path, total_duration: float) -> list[Segment]:
    lines = transcript_path.read_text(encoding="utf-8").splitlines()
    timestamped: list[Segment] = []

    for line in lines:
        if not line.strip() or line.strip().startswith("#"):
            continue
        parsed = parse_timestamped_line(line)
        if parsed is None:
            timestamped = []
            break
        timestamped.append(parsed)

    if timestamped:
        return timestamped

    plain_text = " ".join(line.strip() for line in lines if line.strip() and not line.strip().startswith("#"))
    sentence_candidates = [item.strip() for item in re.split(r"(?<=[.!?。！？])\s+", plain_text) if item.strip()]
    if not sentence_candidates:
        raise RuntimeError("No usable transcript lines found. Add timestamped lines or plain reviewed text.")

    estimated_duration = max(total_duration / len(sentence_candidates), TARGET_MIN)
    segments: list[Segment] = []
    cursor = 0.0
    for sentence in sentence_candidates:
        end = min(cursor + estimated_duration, total_duration)
        segments.append(Segment(start=cursor, end=end, text=sentence))
        cursor = end
    if segments:
        segments[-1].end = total_duration
    return segments


def get_wav_duration(path: Path) -> float:
    with wave.open(str(path), "rb") as wav_file:
        return wav_file.getnframes() / float(wav_file.getframerate())


def copy_wav_slice(input_path: Path, output_path: Path, start_sec: float, end_sec: float) -> None:
    with wave.open(str(input_path), "rb") as src:
        frame_rate = src.getframerate()
        channels = src.getnchannels()
        sample_width = src.getsampwidth()
        start_frame = int(start_sec * frame_rate)
        end_frame = int(end_sec * frame_rate)
        frame_count = max(end_frame - start_frame, 0)

        src.setpos(start_frame)
        frames = src.readframes(frame_count)

        output_path.parent.mkdir(parents=True, exist_ok=True)
        with wave.open(str(output_path), "wb") as dst:
            dst.setnchannels(channels)
            dst.setsampwidth(sample_width)
            dst.setframerate(frame_rate)
            dst.writeframes(frames)


def is_mostly_silence(text: str) -> bool:
    stripped = re.sub(r"\s+", "", text)
    return stripped in {"", ".", "...", "음", "어", "아"}


def write_review_csv(rows: Iterable[dict[str, str]], path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="") as fp:
        writer = csv.DictWriter(
            fp,
            fieldnames=["id", "wav_path", "start", "end", "duration", "text", "status", "notes"],
        )
        writer.writeheader()
        writer.writerows(rows)


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()

    input_path = Path(args.input)
    transcript_path = Path(args.transcript)
    output_dir = Path(args.output_dir)

    if not input_path.exists():
        parser.error(f"Input WAV does not exist: {input_path}")
    if not transcript_path.exists():
        parser.error(
            f"Transcript file does not exist: {transcript_path}\n"
            "Create a draft transcript first, for example:\n"
            "python scripts/00_transcribe_whisper.py "
            "--input output/prepared_speech.wav --output input/transcript.txt"
        )

    total_duration = get_wav_duration(input_path)
    segments = load_segments(transcript_path, total_duration)

    review_rows: list[dict[str, str]] = []
    clip_index = 1
    for segment in segments:
        duration = segment.duration
        status = "ok"
        notes: list[str] = []

        if duration < args.min_seconds:
            status = "skip"
            notes.append("too_short")
        elif duration > args.max_seconds:
            status = "review"
            notes.append("too_long")

        if is_mostly_silence(segment.text):
            status = "skip"
            notes.append("silence_or_filler")

        clip_id = f"{clip_index:06d}"
        relative_wav = f"wav/{clip_id}.wav"
        if status != "skip":
            copy_wav_slice(input_path, output_dir / relative_wav, segment.start, segment.end)
            clip_index += 1

        review_rows.append(
            {
                "id": clip_id,
                "wav_path": relative_wav,
                "start": f"{segment.start:.2f}",
                "end": f"{segment.end:.2f}",
                "duration": f"{duration:.2f}",
                "text": segment.text,
                "status": status,
                "notes": ";".join(notes),
            }
        )

    review_csv = output_dir / "metadata.review.csv"
    write_review_csv(review_rows, review_csv)
    print(f"Review metadata written to: {review_csv}")
    print("Please review metadata.review.csv and confirm it before building metadata.list.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
