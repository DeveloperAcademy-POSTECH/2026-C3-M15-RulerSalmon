# MeloTTS iOS POC

## Overview
This project is a proof of concept for training a custom Korean voice with the official `myshell-ai/MeloTTS` repository, validating checkpoint-based inference first, and then deciding whether export and iOS runtime integration are practical.

This repository is designed to prove the full pipeline:
- prepare data
- fine-tune or adapt a MeloTTS voice
- export inference assets
- package a voice pack
- validate synthesis in Python
- validate playback in iOS through both local and remote inference flows

This is a pipeline validation project, not a production-quality voice project.

## Why MeloTTS
MeloTTS is attractive for this POC because it offers:
- multilingual and cross-language ecosystem momentum
- relatively lightweight deployment expectations compared with larger end-to-end voice systems
- practical fine-tuning/adaptation workflows in the open-source community
- potential ONNX export and mobile-serving paths depending on repo or fork capability

For this project, MeloTTS is used to validate whether a custom Korean speaker workflow can be taken from training artifacts to an iOS playback experience.

## Architecture
The project is split into four layers:

1. Data preparation
- raw speech audio and transcript
- segmentation into short clips
- metadata review and normalization

2. Training and export
- MeloTTS fine-tuning shell wrapper
- export wrapper for ONNX or alternative runtime assets
- sample synthesis validation

3. Packaging
- voice pack manifest
- checksums
- preview audio
- model/config/tokenizer or phonemizer artifacts

4. App runtime
- Remote server fallback mode for fast UI validation
- Local ONNX inference mode for final target architecture
- audio playback and voice pack management in SwiftUI

## Quick Start
```bash
cd melotts-ios-poc
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

# 1) Put your long single-speaker recording in input/
# input/raw_speech.wav

# 2) Prepare audio first
python scripts/01_prepare_audio.py \
  --input input/raw_speech.wav \
  --output output/prepared_speech.wav

# 3) If transcript is missing, create a draft transcript
python scripts/00_transcribe_whisper.py \
  --input output/prepared_speech.wav \
  --output input/transcript.txt \
  --model base \
  --device cpu \
  --compute-type int8 \
  --write-json

# 4) Split audio into clips
python scripts/02_split_audio.py \
  --input output/prepared_speech.wav \
  --transcript input/transcript.txt \
  --output-dir dataset

# 5) Review metadata.review.csv manually, then build metadata.list
python scripts/03_build_metadata.py \
  --input dataset/metadata.review.csv \
  --output dataset/metadata.list \
  --speaker-name DevPaul \
  --language-code KR

# 6) Clone the official repo once
git clone https://github.com/myshell-ai/MeloTTS.git third_party/MeloTTS

# 7) Run official preprocessing + training wrapper
MELOTTS_REPO_DIR=third_party/MeloTTS \
METADATA_PATH=dataset/metadata.list \
CONFIG_PATH=dataset/config.json \
NUM_GPUS=1 \
bash scripts/05_train_melotts.sh

# 8) Test a checkpoint after training
python scripts/07_test_synthesize.py \
  --repo-dir third_party/MeloTTS \
  --checkpoint third_party/MeloTTS/melo/logs/example/G_1000.pth
```


## Data Preparation
The input assumption is a single-speaker Korean speech recording prepared as one long source file and then split into short clips.

Expected inputs:
- `input/raw_speech.wav`
- `input/transcript.txt`

Recommended preparation notes:
- remove non-target speakers
- keep room noise low if possible
- prefer stable speech rate and articulation
- align transcript carefully before training if timestamps are not already available

If transcript quality is uncertain, use Whisper or another ASR tool to draft the transcript first, then manually review it.

Recommended order:
```bash
python scripts/01_prepare_audio.py \
  --input input/raw_speech.wav \
  --output output/prepared_speech.wav

python scripts/00_transcribe_whisper.py \
  --input output/prepared_speech.wav \
  --output input/transcript.txt \
  --write-json
```

Output format:
```text
0.00    4.20    안녕하세요. 오늘은 음성 합성 테스트를 진행합니다.
4.20    8.75    이 문장은 커스텀 보이스 학습을 위한 예시입니다.
```

## Training MeloTTS
This project now follows the official `myshell-ai/MeloTTS` custom training flow:
- create `metadata.list`
- run `python preprocess_text.py --metadata ...`
- run `bash train.sh <config.json> <num_of_gpus>`
- test the resulting checkpoint with `python infer.py ...`

Official training doc:
- [MeloTTS training.md](https://github.com/myshell-ai/MeloTTS/blob/main/docs/training.md)

Official metadata format:
```text
path/to/audio_001.wav|SpeakerName|KR|첫 번째 문장
path/to/audio_002.wav|SpeakerName|KR|두 번째 문장
```

In this repo, `scripts/03_build_metadata.py` generates exactly that format:
```bash
python scripts/03_build_metadata.py \
  --input dataset/metadata.review.csv \
  --output dataset/metadata.list \
  --speaker-name DevPaul \
  --language-code KR
```

Then the wrapper script runs the official repo commands for us:
```bash
MELOTTS_REPO_DIR=third_party/MeloTTS \
METADATA_PATH=dataset/metadata.list \
CONFIG_PATH=dataset/config.json \
NUM_GPUS=1 \
bash scripts/05_train_melotts.sh
```

What that wrapper does internally:
1. `pip install -e .` inside `third_party/MeloTTS`
2. `cd third_party/MeloTTS/melo`
3. `python preprocess_text.py --metadata ../../dataset/metadata.list`
4. `bash train.sh ../../dataset/config.json 1`

Important:
- if preprocessing succeeds, `dataset/config.json`, `dataset/train.list`, and `dataset/val.list` should appear
- `model_dir` inside `dataset/config.json` controls where checkpoints/logs are written
- start with the generated config, then lower batch size first if memory is tight

### Apple Silicon note
If you are using an Apple Silicon Mac such as an M5 MacBook Pro, keep one important limitation in mind: the official `myshell-ai/MeloTTS` training code is still CUDA-oriented. In the current upstream code:
- `preprocess_text.py` calls `clean_text_bert(..., device='cuda:0')`
- `train.py` uses `torch.cuda.set_device(...)` and many `.cuda(...)` calls

That means this repo is excellent for:
- preparing the dataset on macOS
- validating metadata format
- handing the finished dataset to the official training flow

But the actual official training run is more realistic on Linux + NVIDIA CUDA unless you are willing to patch the upstream trainer. Reference context:
- [PyTorch MPS backend](https://docs.pytorch.org/docs/stable/notes/mps.html)
- [Apple PyTorch on Metal](https://developer.apple.com/metal/pytorch/)
- [MeloTTS issue about MPS problems](https://github.com/myshell-ai/MeloTTS/issues/202)

Practical recommendation:
- use macOS for dataset prep and quick inference experiments
- use Linux + NVIDIA for the actual official fine-tuning run
- keep the same `dataset/metadata.list`, `train.list`, `val.list`, and `config.json` when moving machines

For your current setup:
- 50 minutes of clean single-speaker Korean is enough to attempt a real fine-tuning pass
- start by training only to a small early checkpoint and listen first
- do not wait for a full long run before evaluating quality

## Export to ONNX
The intended target artifacts are:
- `output/exported/custom_ko_melotts.onnx`
- `output/exported/custom_ko_melotts.config.json`
- optional tokenizer/phonemizer resources copied into `output/exported/`

Because MeloTTS export support varies by repo or fork, checkpoint-based inference is the first milestone. ONNX export stays a second-track experiment after we confirm the model can learn the voice.

Alternative export discussion:
- ONNX Runtime Mobile: best fit for iOS POC target when supported
- TorchScript: sometimes easier than direct ONNX depending on the fork, but less attractive for long-term portable mobile runtime
- Core ML: possible downstream path, but conversion effort is typically higher and often requires extra operator compatibility work

## Test Synthesis
After training starts producing `G_*.pth` checkpoints, test them with the official inference path:

```bash
python scripts/07_test_synthesize.py \
  --repo-dir third_party/MeloTTS \
  --checkpoint third_party/MeloTTS/melo/logs/example/G_1000.pth
```

The wrapper simply calls:
```bash
python infer.py --text "<sentence>" -m /path/to/G_1000.pth -o output/samples
```

Suggested first evaluation:
- does the voice sound like the target speaker at all
- are Korean pronunciations stable
- does the model collapse or repeat
- does it overfit short phrases too quickly

## Local iOS Inference
The final target architecture is local inference on iOS using exported assets.

Important reality check:
- MeloTTS local iOS inference difficulty depends on actual ONNX export support.
- text normalization and phonemization parity between Python and iOS are major integration concerns.
- if the original Python stack relies on G2P or phonemizer components that cannot be mirrored cleanly in Swift, local runtime work becomes harder.

That is why the demo app includes both:
- `LocalONNXTTSService`
- `RemoteTTSService`

The app never trains. It only imports already exported assets.

## Remote Server Fallback
Remote mode exists so that we can validate:
- text entry flow
- synthesize button flow
- audio playback flow
- voice pack loading flow

before finishing local ONNX runtime integration.

This lets the team verify product behavior even if MeloTTS ONNX export or phonemization parity is not ready yet.

## Voice Pack Format
Expected packaged artifact:
- `custom_ko_melotts_v1.zip`

Zip contents:
- `manifest.json`
- `custom_ko_melotts.onnx`
- `custom_ko_melotts.config.json`
- `preview.wav`
- optional `tokenizer/`
- optional `phonemizer/`
- checksum file

The app reads manifest metadata and resolves local resources from that package.

## Limitations of 8-minute dataset
This dataset size is only for POC validation.

Expected limitations:
- some speaker color may transfer
- pronunciation instability may remain
- prosody may feel flat or inconsistent
- long sentence quality may degrade quickly
- repeated artifacts and overfitting are likely
- single speech tone may dominate the generated output

This project should be used to answer:
- can we train?
- can we export?
- can we import into iOS?
- can we play synthesized audio?

It should not be used to judge final voice quality.

## Evaluation Checklist
Use the following checklist after each phase.

Data
- [ ] audio converted to mono WAV
- [ ] sample rate matches the chosen runtime target
- [ ] metadata clips are mostly 3 to 12 seconds
- [ ] transcript lines reviewed by a person

Training
- [ ] training command runs end to end
- [ ] checkpoints are written
- [ ] logs show no catastrophic divergence

Export
- [ ] ONNX file generated
- [ ] config file generated
- [ ] runtime support files copied

Synthesis
- [ ] Python test synthesis produces WAV output
- [ ] short Korean sentence sounds intelligible
- [ ] numeric and acronym sentences expose known TODOs

Packaging
- [ ] voice pack zip created
- [ ] manifest and checksum included
- [ ] preview audio included

iOS
- [ ] remote synthesis mode works
- [ ] local voice pack loads
- [ ] audio playback works
- [ ] local ONNX mode either works or fails gracefully with a known placeholder error

## Next Steps
Recommended follow-up work after this POC:
- collect 30 to 60 minutes minimum of cleaned Korean speaker data
- improve transcript review and timestamp alignment
- add Korean text normalization for numbers, dates, abbreviations, and symbols
- verify exact MeloTTS fork and export command for production reproducibility
- implement real ONNX Runtime Mobile inference in iOS
- test latency and memory usage on device
- compare ONNX and remote quality side by side
- add speaker evaluation rubric and MOS-style listening checklist
