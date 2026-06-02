#!/usr/bin/env bash
set -euo pipefail

CHECKPOINT_PATH="${CHECKPOINT_PATH:-training/checkpoints/custom_ko_voice/last.ckpt}"
CONFIG_PATH="${CONFIG_PATH:-training/configs/melotts_ko.yaml}"
EXPORT_DIR="${EXPORT_DIR:-output/exported}"
MELOTTS_REPO_DIR="${MELOTTS_REPO_DIR:-third_party/MeloTTS}"
PYTHON_BIN="${PYTHON_BIN:-python3}"

mkdir -p "${EXPORT_DIR}"

if [[ ! -f "${CHECKPOINT_PATH}" ]]; then
  echo "[ERROR] Checkpoint not found: ${CHECKPOINT_PATH}" >&2
  exit 1
fi

echo "[INFO] Exporting MeloTTS artifacts for iOS inference"
echo "[WARN] ONNX export support depends on the exact MeloTTS repo or fork."
echo "[WARN] If direct export is unavailable, keep RemoteTTSService as the immediate POC path."

pushd "${MELOTTS_REPO_DIR}" >/dev/null

# TODO: Replace with the verified export command for your MeloTTS fork.
if [[ -f "export_onnx.py" ]]; then
  "${PYTHON_BIN}" export_onnx.py \
    --checkpoint "../${CHECKPOINT_PATH}" \
    --config "../${CONFIG_PATH}" \
    --output "../${EXPORT_DIR}/custom_ko_melotts.onnx"
elif [[ -f "tools/export_onnx.py" ]]; then
  "${PYTHON_BIN}" tools/export_onnx.py \
    --checkpoint "../${CHECKPOINT_PATH}" \
    --config "../${CONFIG_PATH}" \
    --output "../${EXPORT_DIR}/custom_ko_melotts.onnx"
else
  echo "[WARN] No direct ONNX exporter found in ${MELOTTS_REPO_DIR}."
  echo "[WARN] You may need to export TorchScript first, or temporarily use RemoteTTSService."
fi

popd >/dev/null

if [[ -f "${CONFIG_PATH}" ]]; then
  cp "${CONFIG_PATH}" "${EXPORT_DIR}/custom_ko_melotts.config.json" || true
fi

mkdir -p "${EXPORT_DIR}/tokenizer"
mkdir -p "${EXPORT_DIR}/phonemizer"

echo '{"note":"Replace this placeholder with verified MeloTTS tokenizer assets if required."}' > "${EXPORT_DIR}/tokenizer/README.json"
echo '{"note":"Replace this placeholder with verified MeloTTS phonemizer assets if required."}' > "${EXPORT_DIR}/phonemizer/README.json"

echo "[INFO] Export step completed. Verify ONNX file availability in ${EXPORT_DIR}."
