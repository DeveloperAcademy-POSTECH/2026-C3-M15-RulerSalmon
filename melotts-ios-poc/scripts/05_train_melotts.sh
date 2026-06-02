#!/usr/bin/env bash
set -euo pipefail

MELOTTS_REPO_DIR="${MELOTTS_REPO_DIR:-third_party/MeloTTS}"
MELO_DIR="${MELO_DIR:-${MELOTTS_REPO_DIR}/melo}"
PYTHON_BIN="${PYTHON_BIN:-python3}"
METADATA_PATH="${METADATA_PATH:-dataset/metadata.list}"
CONFIG_PATH="${CONFIG_PATH:-dataset/config.json}"
NUM_GPUS="${NUM_GPUS:-1}"
RUN_PREPROCESS="${RUN_PREPROCESS:-1}"

echo "[INFO] MeloTTS official training wrapper"
echo "[INFO] MELOTTS_REPO_DIR=${MELOTTS_REPO_DIR}"
echo "[INFO] MELO_DIR=${MELO_DIR}"
echo "[INFO] METADATA_PATH=${METADATA_PATH}"
echo "[INFO] CONFIG_PATH=${CONFIG_PATH}"
echo "[INFO] NUM_GPUS=${NUM_GPUS}"

if [[ ! -d "${MELOTTS_REPO_DIR}" ]]; then
  echo "[ERROR] MeloTTS repo directory not found: ${MELOTTS_REPO_DIR}" >&2
  echo "[HINT] git clone https://github.com/myshell-ai/MeloTTS.git ${MELOTTS_REPO_DIR}" >&2
  exit 1
fi

if [[ ! -d "${MELO_DIR}" ]]; then
  echo "[ERROR] MeloTTS melo directory not found: ${MELO_DIR}" >&2
  echo "[HINT] Expected official repo layout: third_party/MeloTTS/melo" >&2
  exit 1
fi

if [[ ! -f "${METADATA_PATH}" ]]; then
  echo "[ERROR] metadata.list not found: ${METADATA_PATH}" >&2
  echo "[HINT] Run scripts/03_build_metadata.py first." >&2
  exit 1
fi

if ! "${PYTHON_BIN}" -c "import torch, sys; sys.exit(0 if torch.cuda.is_available() else 1)" >/dev/null 2>&1; then
  echo "[ERROR] Official MeloTTS training in this repo currently expects CUDA." >&2
  echo "[DETAIL] preprocess_text.py hardcodes device='cuda:0', and train.py uses torch.cuda.set_device(...) plus many .cuda(...) calls." >&2
  echo "[HINT] Use the prepared dataset on a Linux/NVIDIA machine, or port the upstream training code before trying local macOS training." >&2
  exit 1
fi

pushd "${MELOTTS_REPO_DIR}" >/dev/null

if [[ "${RUN_PREPROCESS}" == "1" ]]; then
  echo "[INFO] Running MeloTTS text preprocessing"
  "${PYTHON_BIN}" -m pip install -e .

  pushd melo >/dev/null
  "${PYTHON_BIN}" preprocess_text.py --metadata "../../${METADATA_PATH}"
  popd >/dev/null
else
  echo "[INFO] Skipping preprocess_text.py because RUN_PREPROCESS=${RUN_PREPROCESS}"
fi

if [[ ! -f "${CONFIG_PATH}" ]]; then
  echo "[ERROR] Expected config.json was not created: ${CONFIG_PATH}" >&2
  echo "[HINT] Check the metadata.list format and the preprocess_text.py logs." >&2
  exit 1
fi

pushd melo >/dev/null
echo "[INFO] Launching training with official train.sh"
echo "[INFO] Command: bash train.sh ../../${CONFIG_PATH} ${NUM_GPUS}"
bash train.sh "../../${CONFIG_PATH}" "${NUM_GPUS}"
popd >/dev/null

popd >/dev/null

echo "[INFO] Training command finished."
echo "[INFO] Checkpoints and logs are usually written under the model_dir inside ${CONFIG_PATH}."
