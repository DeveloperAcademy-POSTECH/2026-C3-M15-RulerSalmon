#!/usr/bin/env bash
set -euo pipefail

# Piper 버전에 맞게 명령/옵션 확인 필요
# 본 스크립트는 '학습 파이프라인 검증(POC)' 목적 예시입니다.

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DATASET_DIR="${ROOT_DIR}/dataset"
OUTPUT_DIR="${ROOT_DIR}/output/checkpoints"
PREPROCESSED_DIR="${OUTPUT_DIR}/preprocessed"

: "${PIPER_REPO:?환경변수 PIPER_REPO(로컬 piper repo 경로)를 지정해 주세요}"

BATCH_SIZE="${BATCH_SIZE:-8}"
MAX_EPOCHS="${MAX_EPOCHS:-30}"
VALID_SPLIT="${VALID_SPLIT:-0.1}"
DATASET_FORMAT="${DATASET_FORMAT:-ljspeech}"
SAMPLE_RATE="${SAMPLE_RATE:-22050}"
QUALITY="${QUALITY:-x-low}"

mkdir -p "${OUTPUT_DIR}"

echo "[INFO] Training start (POC)"
echo "[INFO] dataset: ${DATASET_DIR}"
echo "[INFO] output : ${OUTPUT_DIR}"
echo "[INFO] batch=${BATCH_SIZE}, epochs=${MAX_EPOCHS}, val_split=${VALID_SPLIT}"
echo "[INFO] format=${DATASET_FORMAT}, sample_rate=${SAMPLE_RATE}, quality=${QUALITY}"

# monotonic_align Cython extension build (required by older Piper training code)
echo "[INFO] Building monotonic_align extension"
(
  cd "${PIPER_REPO}/src/python"
  python3 piper_train/vits/monotonic_align/setup.py build_ext --inplace
)

PYTHONPATH="${PIPER_REPO}/src/python" python3 -m piper_train.preprocess \
  --input-dir "${DATASET_DIR}" \
  --output-dir "${PREPROCESSED_DIR}" \
  --dataset-format "${DATASET_FORMAT}" \
  --language "ko" \
  --sample-rate "${SAMPLE_RATE}" \
  --single-speaker

TRAIN_CMD=(
  python3 -m piper_train
  --dataset-dir "${PREPROCESSED_DIR}"
  --default_root_dir "${OUTPUT_DIR}"
  --quality "${QUALITY}"
  --batch-size "${BATCH_SIZE}"
  --max_epochs "${MAX_EPOCHS}"
  --validation-split "${VALID_SPLIT}"
  --accelerator auto
  --devices 1
)

if [[ -n "${PRETRAINED_CKPT:-}" ]]; then
  if [[ -f "${PRETRAINED_CKPT}" ]]; then
    TRAIN_CMD+=(--resume_from_checkpoint "${PRETRAINED_CKPT}")
    echo "[INFO] resume checkpoint: ${PRETRAINED_CKPT}"
  else
    echo "[WARN] PRETRAINED_CKPT 파일을 찾지 못해 무시합니다: ${PRETRAINED_CKPT}"
  fi
fi

PYTHONPATH="${PIPER_REPO}/src/python" "${TRAIN_CMD[@]}"

cat <<MSG
[INFO] Training finished.
[NOTE] Piper 버전에 따라 train.py 경로/옵션이 다를 수 있습니다.
[NOTE] 현재 사용 중인 Piper 브랜치 문서를 반드시 다시 확인하세요.
MSG
