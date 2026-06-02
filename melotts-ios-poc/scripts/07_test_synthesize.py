#!/usr/bin/env python3
from __future__ import annotations

import argparse
import subprocess
import sys
from pathlib import Path


TEST_SENTENCES = [
    "안녕, 이건 커스텀 한국어 음성 테스트야.",
    "이번 모델이 내 목소리 느낌을 얼마나 따라가는지 확인해보자.",
    "로직, 최적화, 그리고 사용자 경험 같은 단어도 자연스럽게 읽는지 보자.",
]


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Test inference with an official MeloTTS checkpoint.")
    parser.add_argument("--repo-dir", default="third_party/MeloTTS", help="Official MeloTTS repo path.")
    parser.add_argument("--checkpoint", required=True, help="Path to G_*.pth checkpoint.")
    parser.add_argument("--text", help="Single text to synthesize.")
    parser.add_argument("--output-dir", default="output/samples", help="Directory for generated WAV files.")
    parser.add_argument("--python-bin", default="python3", help="Python executable used for MeloTTS.")
    return parser


def run_infer(
    python_bin: str,
    repo_dir: Path,
    checkpoint: Path,
    text: str,
    output_dir: Path,
) -> None:
    melo_dir = repo_dir / "melo"
    infer_script = melo_dir / "infer.py"
    if not infer_script.exists():
        raise FileNotFoundError(f"infer.py not found: {infer_script}")

    command = [
        python_bin,
        "infer.py",
        "--text",
        text,
        "-m",
        str(checkpoint.resolve()),
        "-o",
        str(output_dir.resolve()),
    ]
    subprocess.run(command, cwd=melo_dir, check=True)


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()

    repo_dir = Path(args.repo_dir)
    checkpoint = Path(args.checkpoint)
    output_dir = Path(args.output_dir)

    if not repo_dir.exists():
        parser.error(f"Repo path does not exist: {repo_dir}")
    if not checkpoint.exists():
        parser.error(f"Checkpoint path does not exist: {checkpoint}")

    texts = [args.text] if args.text else TEST_SENTENCES
    output_dir.mkdir(parents=True, exist_ok=True)

    for text in texts:
        print(f"Synthesizing: {text}")
        run_infer(args.python_bin, repo_dir, checkpoint, text, output_dir)

    print(f"Generated samples in: {output_dir}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
