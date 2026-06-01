#!/usr/bin/env python3
import argparse
import csv
import math
import subprocess
import sys
from pathlib import Path
from typing import Any


def run_command(cmd: list[str]) -> str:
    try:
        result = subprocess.run(cmd, check=True, capture_output=True, text=True)
        return result.stdout.strip()
    except FileNotFoundError:
        print(f"오류: 명령어를 찾을 수 없습니다: {cmd[0]}", file=sys.stderr)
        sys.exit(1)
    except subprocess.CalledProcessError as e:
        print(f"오류: 명령 실행 실패: {' '.join(cmd)}", file=sys.stderr)
        print(e.stderr, file=sys.stderr)
        sys.exit(e.returncode)


def ffprobe_duration(audio_path: Path) -> float:
    out = run_command([
        "ffprobe",
        "-v",
        "error",
        "-show_entries",
        "format=duration",
        "-of",
        "default=noprint_wrappers=1:nokey=1",
        str(audio_path),
    ])
    return float(out)


def split_with_whisper(audio_path: Path, model: str) -> list[dict[str, Any]]:
    try:
        import whisper
    except ImportError:
        print("오류: whisper 패키지가 없습니다. `pip install -r requirements.txt`를 실행해 주세요.", file=sys.stderr)
        sys.exit(1)

    m = whisper.load_model(model)
    result = m.transcribe(str(audio_path), language="ko")

    segments: list[dict[str, Any]] = []
    for seg in result.get("segments", []):
        text = (seg.get("text") or "").strip()
        if not text:
            continue
        segments.append({
            "start": float(seg["start"]),
            "end": float(seg["end"]),
            "text": text,
        })
    return segments


def split_even_chunks(audio_path: Path, transcript: str, min_sec: float, max_sec: float) -> list[dict[str, Any]]:
    duration = ffprobe_duration(audio_path)
    target = max(min_sec, min(max_sec, 8.0))
    chunks = max(1, math.ceil(duration / target))
    chunk_duration = duration / chunks

    sentences = [s.strip() for s in transcript.replace("\n", " ").split(".") if s.strip()]
    if not sentences:
        sentences = [transcript.strip()]

    segments: list[dict[str, Any]] = []
    for i in range(chunks):
        start = i * chunk_duration
        end = duration if i == chunks - 1 else (i + 1) * chunk_duration
        text = sentences[i % len(sentences)]
        if not text.endswith("."):
            text += "."
        segments.append({"start": start, "end": end, "text": text})
    return segments


def export_clip(audio_path: Path, out_path: Path, start: float, end: float, sample_rate: int) -> None:
    out_path.parent.mkdir(parents=True, exist_ok=True)
    cmd = [
        "ffmpeg",
        "-y",
        "-i",
        str(audio_path),
        "-ss",
        f"{start:.3f}",
        "-to",
        f"{end:.3f}",
        "-ac",
        "1",
        "-ar",
        str(sample_rate),
        str(out_path),
    ]
    run_command(cmd)


def main() -> None:
    parser = argparse.ArgumentParser(description="학습용 3~12초 음성 클립 분할")
    parser.add_argument("--audio", type=Path, required=True, help="전처리된 단일 wav")
    parser.add_argument("--out-dir", type=Path, required=True, help="출력 wav 디렉터리")
    parser.add_argument("--segments-csv", type=Path, required=True, help="검수용 세그먼트 CSV")
    parser.add_argument("--transcript", type=Path, help="원문 transcript (타임스탬프 없음)")
    parser.add_argument("--use-whisper", action="store_true", help="Whisper 타임스탬프 사용")
    parser.add_argument("--whisper-model", default="small", help="Whisper 모델명")
    parser.add_argument("--min-sec", type=float, default=3.0)
    parser.add_argument("--max-sec", type=float, default=12.0)
    parser.add_argument("--sample-rate", type=int, default=22050, choices=[22050, 24000])
    args = parser.parse_args()

    if not args.audio.exists():
        print(f"오류: 오디오 파일이 없습니다: {args.audio}", file=sys.stderr)
        sys.exit(1)

    if args.min_sec <= 0 or args.max_sec <= 0 or args.min_sec > args.max_sec:
        print("오류: min-sec/max-sec 값이 유효하지 않습니다.", file=sys.stderr)
        sys.exit(1)

    if args.use_whisper:
        segments = split_with_whisper(args.audio, args.whisper_model)
        if not segments:
            print("오류: Whisper가 세그먼트를 생성하지 못했습니다.", file=sys.stderr)
            sys.exit(1)
    else:
        if not args.transcript or not args.transcript.exists():
            print("오류: --use-whisper가 없으면 --transcript 파일이 필요합니다.", file=sys.stderr)
            sys.exit(1)
        transcript = args.transcript.read_text(encoding="utf-8").strip()
        if not transcript:
            print("오류: transcript가 비어 있습니다.", file=sys.stderr)
            sys.exit(1)
        segments = split_even_chunks(args.audio, transcript, args.min_sec, args.max_sec)

    args.out_dir.mkdir(parents=True, exist_ok=True)
    args.segments_csv.parent.mkdir(parents=True, exist_ok=True)

    written = []
    for idx, seg in enumerate(segments, start=1):
        start = float(seg["start"])
        end = float(seg["end"])
        duration = end - start
        if duration < args.min_sec:
            continue
        if duration > args.max_sec:
            # 너무 긴 경우 균등 재분할
            n = math.ceil(duration / args.max_sec)
            piece = duration / n
            for j in range(n):
                s = start + j * piece
                e = end if j == n - 1 else start + (j + 1) * piece
                if (e - s) < args.min_sec:
                    continue
                clip_id = len(written) + 1
                wav_name = f"{clip_id:06d}.wav"
                export_clip(args.audio, args.out_dir / wav_name, s, e, args.sample_rate)
                written.append({
                    "id": f"{clip_id:06d}",
                    "wav": wav_name,
                    "start": round(s, 3),
                    "end": round(e, 3),
                    "duration": round(e - s, 3),
                    "text": seg["text"],
                })
        else:
            clip_id = len(written) + 1
            wav_name = f"{clip_id:06d}.wav"
            export_clip(args.audio, args.out_dir / wav_name, start, end, args.sample_rate)
            written.append({
                "id": f"{clip_id:06d}",
                "wav": wav_name,
                "start": round(start, 3),
                "end": round(end, 3),
                "duration": round(duration, 3),
                "text": seg["text"],
            })

    if not written:
        print("오류: 생성된 클립이 없습니다. 분할 조건을 확인해 주세요.", file=sys.stderr)
        sys.exit(1)

    with args.segments_csv.open("w", encoding="utf-8", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=["id", "wav", "start", "end", "duration", "text"])
        writer.writeheader()
        writer.writerows(written)

    print(f"완료: 클립 {len(written)}개 생성 -> {args.out_dir}")
    print(f"완료: 검수 CSV 저장 -> {args.segments_csv}")


if __name__ == "__main__":
    main()
