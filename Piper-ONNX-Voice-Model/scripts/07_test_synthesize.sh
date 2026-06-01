#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
EXPORTED_DIR="${ROOT_DIR}/output/exported"
SAMPLES_DIR="${ROOT_DIR}/output/samples"
PIPER_REPO="${PIPER_REPO:-/workspace/piper}"

mkdir -p "${SAMPLES_DIR}"

MODEL_PATH="${EXPORTED_DIR}/custom_ko_voice.onnx"
CONFIG_PATH="${EXPORTED_DIR}/custom_ko_voice.onnx.json"

if [[ ! -f "${MODEL_PATH}" ]]; then
  echo "오류: 모델 파일이 없습니다: ${MODEL_PATH}" >&2
  exit 1
fi

if [[ ! -f "${CONFIG_PATH}" ]]; then
  echo "오류: 설정 파일이 없습니다: ${CONFIG_PATH}" >&2
  exit 1
fi

if command -v piper >/dev/null 2>&1; then
  PIPER_CMD=(piper)
else
  PIPER_RUN_DIR="${PIPER_REPO}/src/python_run"
  if [[ ! -d "${PIPER_RUN_DIR}" ]]; then
    echo "오류: piper 실행 파일도 없고 python_run 경로도 찾지 못했습니다: ${PIPER_RUN_DIR}" >&2
    exit 1
  fi
  PIPER_CMD=(python3 -m piper)
  export PYTHONPATH="${PIPER_RUN_DIR}:${PYTHONPATH:-}"
fi

echo "안녕하세요. 이것은 아이오에스 앱에서 사용할 커스텀 음성 테스트입니다." | \
  "${PIPER_CMD[@]}" --model "${MODEL_PATH}" --config "${CONFIG_PATH}" --output_file "${SAMPLES_DIR}/test_001.wav"

echo "오늘 날씨가 참 좋네요." | \
  "${PIPER_CMD[@]}" --model "${MODEL_PATH}" --config "${CONFIG_PATH}" --output_file "${SAMPLES_DIR}/test_002.wav"

echo "사용자의 문장을 자연스러운 목소리로 읽어드립니다." | \
  "${PIPER_CMD[@]}" --model "${MODEL_PATH}" --config "${CONFIG_PATH}" --output_file "${SAMPLES_DIR}/test_003.wav"

echo "완료: 샘플 음성 생성 -> ${SAMPLES_DIR}"
