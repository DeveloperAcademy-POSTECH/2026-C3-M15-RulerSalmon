#!/usr/bin/env python3
import argparse
import subprocess
import sys
from pathlib import Path


def run_ffmpeg(cmd: list[str]) -> None:
    try:
        subprocess.run(cmd, check=True)
    except FileNotFoundError:
        print("오류: ffmpeg를 찾을 수 없습니다. ffmpeg를 설치해 주세요.", file=sys.stderr)
        sys.exit(1)
    except subprocess.CalledProcessError as e:
        print(f"오류: ffmpeg 실행 실패 (exit={e.returncode})", file=sys.stderr)
        sys.exit(e.returncode)


def main() -> None:
    parser = argparse.ArgumentParser(description="Piper 학습용 오디오 전처리")
    parser.add_argument("--input", type=Path, required=True, help="입력 오디오 파일")
    parser.add_argument(
        "--output", type=Path, required=True, help="전처리 결과 wav 파일 경로"
    )
    parser.add_argument(
        "--sample-rate",
        type=int,
        default=22050,
        choices=[22050, 24000],
        help="목표 샘플레이트 (22050 또는 24000)",
    )
    parser.add_argument(
        "--silence-duration",
        type=float,
        default=0.6,
        help="제거 대상 무음 최소 길이(초)",
    )
    parser.add_argument(
        "--silence-threshold",
        type=str,
        default="-40dB",
        help="무음 판단 임계값 (예: -40dB)",
    )
    args = parser.parse_args()

    if not args.input.exists():
        print(f"오류: 입력 파일이 없습니다: {args.input}", file=sys.stderr)
        sys.exit(1)

    args.output.parent.mkdir(parents=True, exist_ok=True)

    # mono 변환, 샘플레이트 통일, loudnorm, 무음 제거
    ffmpeg_cmd = [
        "ffmpeg",
        "-y",
        "-i",
        str(args.input),
        "-ac",
        "1",
        "-ar",
        str(args.sample_rate),
        "-af",
        (
            "loudnorm=I=-16:TP=-1.5:LRA=11,"
            f"silenceremove=stop_periods=-1:stop_duration={args.silence_duration}:"
            f"stop_threshold={args.silence_threshold}"
        ),
        str(args.output),
    ]

    run_ffmpeg(ffmpeg_cmd)
    print(f"완료: 전처리 오디오 저장 -> {args.output}")


if __name__ == "__main__":
    main()
