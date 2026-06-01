#!/usr/bin/env bash
set -euo pipefail

# Piper 버전에 맞게 export 명령 확인 필요

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CHECKPOINTS_DIR="${ROOT_DIR}/output/checkpoints"
EXPORTED_DIR="${ROOT_DIR}/output/exported"

: "${PIPER_REPO:?환경변수 PIPER_REPO(로컬 piper repo 경로)를 지정해 주세요}"
: "${TRAINED_CKPT:?환경변수 TRAINED_CKPT(학습 완료 checkpoint 경로)를 지정해 주세요}"

mkdir -p "${EXPORTED_DIR}"

PYTHONPATH="${PIPER_REPO}/src/python" python3 -m piper_train.export_onnx \
  "${TRAINED_CKPT}" \
  "${EXPORTED_DIR}/custom_ko_voice.onnx"

# config(json)는 버전에 따라 파일명/위치가 다를 수 있어 복사 로직 분기
if [[ -f "${TRAINED_CKPT}.json" ]]; then
  cp "${TRAINED_CKPT}.json" "${EXPORTED_DIR}/custom_ko_voice.onnx.json"
elif [[ -f "${CHECKPOINTS_DIR}/preprocessed/config.json" ]]; then
  cp "${CHECKPOINTS_DIR}/preprocessed/config.json" "${EXPORTED_DIR}/custom_ko_voice.onnx.json"
elif [[ -f "${CHECKPOINTS_DIR}/config.json" ]]; then
  cp "${CHECKPOINTS_DIR}/config.json" "${EXPORTED_DIR}/custom_ko_voice.onnx.json"
elif [[ -f "$(dirname "${TRAINED_CKPT}")/../hparams.yaml" ]]; then
  cp "$(dirname "${TRAINED_CKPT}")/../hparams.yaml" "${EXPORTED_DIR}/training-hparams.yaml"
else
  echo "오류: onnx 설정 json을 찾지 못했습니다. Piper 버전별 export 산출물을 확인해 주세요." >&2
  exit 1
fi

echo "완료: ${EXPORTED_DIR}/custom_ko_voice.onnx"
if [[ -f "${EXPORTED_DIR}/custom_ko_voice.onnx.json" ]]; then
  echo "완료: ${EXPORTED_DIR}/custom_ko_voice.onnx.json"
fi
