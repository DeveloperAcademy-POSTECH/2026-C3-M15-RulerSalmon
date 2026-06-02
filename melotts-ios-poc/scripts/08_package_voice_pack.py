#!/usr/bin/env python3
from __future__ import annotations

import argparse
import hashlib
import json
import shutil
import sys
import tempfile
import zipfile
from pathlib import Path


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Package exported MeloTTS assets into a voice pack zip.")
    parser.add_argument("--export-dir", required=True, help="Directory containing exported model assets.")
    parser.add_argument("--preview", required=True, help="Preview WAV path.")
    parser.add_argument("--output", required=True, help="Output voice pack zip path.")
    parser.add_argument("--version", default="0.1.0")
    parser.add_argument("--sample-rate", type=int, default=44100)
    parser.add_argument("--voice-id", default="custom_ko_melotts_v1")
    parser.add_argument("--name", default="Custom Korean MeloTTS Voice v1")
    return parser


def sha256_file(path: Path) -> str:
    hasher = hashlib.sha256()
    with path.open("rb") as fp:
        for chunk in iter(lambda: fp.read(65536), b""):
            hasher.update(chunk)
    return hasher.hexdigest()


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()

    export_dir = Path(args.export_dir)
    preview_path = Path(args.preview)
    output_path = Path(args.output)

    model_path = export_dir / "custom_ko_melotts.onnx"
    config_path = export_dir / "custom_ko_melotts.config.json"
    tokenizer_dir = export_dir / "tokenizer"
    phonemizer_dir = export_dir / "phonemizer"

    for required in [export_dir, preview_path, model_path, config_path]:
        if not required.exists():
            parser.error(f"Required path does not exist: {required}")

    manifest = {
        "id": args.voice_id,
        "name": args.name,
        "engine": "melotts",
        "language": "ko",
        "sampleRate": args.sample_rate,
        "model": model_path.name,
        "config": config_path.name,
        "version": args.version,
        "trainingDataMinutes": 8,
        "quality": "poc",
        "requires": {
            "runtime": "onnxruntime-mobile",
            "textNormalizer": True,
            "phonemizer": True,
        },
    }

    output_path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory() as tmp_dir_str:
        tmp_dir = Path(tmp_dir_str)
        shutil.copy2(model_path, tmp_dir / model_path.name)
        shutil.copy2(config_path, tmp_dir / config_path.name)
        shutil.copy2(preview_path, tmp_dir / "preview.wav")

        if tokenizer_dir.exists():
            shutil.copytree(tokenizer_dir, tmp_dir / "tokenizer", dirs_exist_ok=True)
        if phonemizer_dir.exists():
            shutil.copytree(phonemizer_dir, tmp_dir / "phonemizer", dirs_exist_ok=True)

        manifest_path = tmp_dir / "manifest.json"
        manifest_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

        checksum_items = {
            model_path.name: sha256_file(tmp_dir / model_path.name),
            config_path.name: sha256_file(tmp_dir / config_path.name),
            "preview.wav": sha256_file(tmp_dir / "preview.wav"),
            "manifest.json": sha256_file(manifest_path),
        }
        (tmp_dir / "checksums.json").write_text(json.dumps(checksum_items, indent=2) + "\n", encoding="utf-8")

        with zipfile.ZipFile(output_path, "w", compression=zipfile.ZIP_DEFLATED) as zf:
            for path in sorted(tmp_dir.rglob("*")):
                if path.is_file():
                    zf.write(path, path.relative_to(tmp_dir))

    print(f"Voice pack created: {output_path}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
