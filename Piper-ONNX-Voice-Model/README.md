# Piper ONNX Korean Voice POC (8-minute dataset)

8분 단일 화자 한국어 스피치 오디오를 이용해 Piper 커스텀 음성 학습 파이프라인을 검증하고, iOS 앱에서 사용할 ONNX 음성 모델을 만드는 POC 프로젝트입니다.

중요:
- 목표는 고품질 모델이 아니라 학습 파이프라인 검증입니다.
- Apple Silicon Mac MPS로도 POC 시도는 가능하지만, 본 학습/안정성은 NVIDIA CUDA 환경을 권장합니다.
- Piper 학습 CLI는 버전별 옵션 차이가 큽니다. 아래 명령은 템플릿이며 사용 중인 Piper 버전에 맞춰 반드시 확인해야 합니다.

## 폴더 구조

```txt
piper-voice-poc/
  input/
    raw_speech.wav
    transcript.txt
  dataset/
    wav/
    metadata.csv
  scripts/
    01_prepare_audio.py
    02_split_audio.py
    03_build_metadata.py
    04_normalize_text.py
    05_train.sh
    06_export_onnx.sh
    07_test_synthesize.sh
  output/
    checkpoints/
    exported/
    samples/
  voice-pack/
    manifest.example.json
  README.md
  requirements.txt
```

## Quick Start

```bash
cd Piper-ONNX-Voice-Model
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

# 1) 오디오 전처리
python scripts/01_prepare_audio.py \
  --input input/raw_speech.wav \
  --output output/prepared.wav \
  --sample-rate 22050

# 2-A) transcript 기반 균등 분할
python scripts/02_split_audio.py \
  --audio output/prepared.wav \
  --transcript input/transcript.txt \
  --out-dir dataset/wav \
  --segments-csv dataset/segments_review.csv \
  --min-sec 3 --max-sec 12 --sample-rate 22050

# 2-B) transcript가 부정확/부재면 Whisper 분할
python scripts/02_split_audio.py \
  --audio output/prepared.wav \
  --use-whisper \
  --whisper-model small \
  --out-dir dataset/wav \
  --segments-csv dataset/segments_review.csv \
  --min-sec 3 --max-sec 12 --sample-rate 22050

# 3) metadata 생성
python scripts/03_build_metadata.py \
  --segments-csv dataset/segments_review.csv \
  --output dataset/metadata.csv
```

## Data Preparation

1. `input/raw_speech.wav`와 `input/transcript.txt`를 준비합니다.
2. `01_prepare_audio.py`로 mono/샘플레이트/정규화/무음 제거를 수행합니다.
3. `02_split_audio.py`로 3~12초 clip을 만들고 `dataset/segments_review.csv`를 생성합니다.
4. `segments_review.csv`를 사람이 검수(오탈자, 잘린 문장, 부자연 구간 제거)합니다.
5. `03_build_metadata.py`로 Piper 학습용 `dataset/metadata.csv`를 생성합니다.

`metadata.csv` 예시:

```txt
000001|안녕하세요. 오늘은 앱 음성 합성 테스트를 진행합니다.
000002|이 문장은 커스텀 보이스 학습을 위한 예시입니다.
```

## Training

Docker 기반 Linux/NVIDIA GPU 루트:
- CUDA 가능한 서버에서 Piper 학습 환경 이미지를 준비하고, 이 프로젝트 폴더를 마운트합니다.
- `PIPER_REPO`, `PRETRAINED_CKPT`를 환경변수로 주고 `scripts/05_train.sh`를 실행합니다.

Python venv/conda 기반 로컬 루트:
- 로컬(또는 서버)에 Piper repository를 clone합니다.
- 해당 repo 의존성을 설치합니다.
- 아래처럼 실행합니다.

```bash
export PIPER_REPO=/path/to/piper
export PRETRAINED_CKPT=/path/to/pretrained.ckpt
export BATCH_SIZE=8
export MAX_EPOCHS=30
export VALID_SPLIT=0.1
bash scripts/05_train.sh
```

주의:
- 8분 데이터는 매우 과적합되기 쉬우므로 `pipeline verification` 목적이어야 합니다.
- pre-trained checkpoint에서 fine-tuning 우선 권장합니다.
- Piper 버전에 따라 학습 명령/옵션이 다르므로 반드시 현재 버전 문서 확인이 필요합니다.

## Export to ONNX

```bash
export PIPER_REPO=/path/to/piper
export TRAINED_CKPT=output/checkpoints/last.ckpt
bash scripts/06_export_onnx.sh
```

목표 산출물:
- `output/exported/custom_ko_voice.onnx`
- `output/exported/custom_ko_voice.onnx.json`

## Test Synthesis

```bash
bash scripts/07_test_synthesize.sh
```

생성 결과:
- `output/samples/test_001.wav`
- `output/samples/test_002.wav`
- `output/samples/test_003.wav`

## iOS Importing

앱에 포함할 파일:
- `custom_ko_voice.onnx`
- `custom_ko_voice.onnx.json`
- 필요 시 `espeak-ng-data` 또는 phonemizer 관련 리소스

권장 런타임:
- sherpa-onnx iOS
- 또는 ONNX Runtime 직접 사용

원칙:
- 앱에서는 학습하지 않고 추론만 수행합니다.

권장 voice pack 구조:

```txt
custom_ko_voice_v1.zip
  manifest.json
  custom_ko_voice.onnx
  custom_ko_voice.onnx.json
  preview.wav
```

`manifest.json` 예시는 `voice-pack/manifest.example.json`를 참고하세요.

## Limitations of 8-minute dataset

- 8분 데이터는 커스텀 보이스 품질 확보에 매우 부족합니다.
- 음색 유사도는 일부 반영될 수 있지만, 발음 안정성/억양/긴 문장 품질은 낮을 수 있습니다.
- 특정 스피치 톤에 과적합될 가능성이 큽니다.
- 최소 30~60분, 권장 1~3시간 이상의 정제 데이터가 필요합니다.

POC 성공 기준:
- 학습 파이프라인이 작동한다.
- ONNX export가 된다.
- 샘플 음성이 생성된다.
- iOS 앱에서 모델을 로드할 수 있다.
- 특정 화자의 음색이 약간이라도 반영되는지 확인한다.

## Next Steps

품질 개선 로드맵:
1. 8분 데이터로 pipeline 검증
2. 30분 데이터로 1차 voice similarity 확인
3. 60분 데이터로 발음/억양 안정화
4. 2~3시간 데이터로 앱 배포 후보 모델 생성
5. 숫자/영어/고유명사 normalization 강화
6. iPhone 실기기에서 latency, memory, battery 테스트
