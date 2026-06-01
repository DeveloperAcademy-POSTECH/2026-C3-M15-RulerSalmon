# Piper ONNX Voice Model Guide

이 문서는 `Piper-ONNX-Voice-Model` 폴더를 다른 프로젝트나 다른 머신으로 가져간 뒤, Docker 컨테이너를 띄우는 단계부터 학습/ONNX export/샘플 합성까지 다시 실행하는 방법을 정리한 가이드입니다.

기준 환경:
- macOS + Docker Desktop
- Docker 안에서 `linux/amd64` Python 3.10 컨테이너 사용
- 로컬 워크스페이스에 `piper` repository를 함께 clone

## 1. 준비물

필수:
- Docker Desktop 설치
- 이 폴더: `Piper-ONNX-Voice-Model`
- 로컬에 clone한 `piper` repository

권장 워크스페이스 구조:

```txt
your-project/
  Piper-ONNX-Voice-Model/
  piper/
```

`piper` clone 예시:

```bash
cd /path/to/your-project
git clone https://github.com/rhasspy/piper.git
```

## 2. 컨테이너 실행

한 번 설치한 패키지를 재사용하려면 `--rm`을 쓰지 않는 편이 좋습니다.

```bash
cd /path/to/your-project

docker run -it \
  --name piper-train \
  --platform linux/amd64 \
  -v "$(pwd)":/workspace \
  -w /workspace/Piper-ONNX-Voice-Model \
  python:3.10-bullseye bash
```

다음부터는 새로 만들지 말고 재사용:

```bash
docker start -ai piper-train
```

주의:
- `docker run --rm -it ...` 로 띄우면 컨테이너를 나갈 때 설치한 `ffmpeg`, `pip` 패키지가 모두 사라집니다.

## 3. 컨테이너 안 1회 초기 설치

컨테이너를 처음 만들었을 때 한 번만 실행합니다.

```bash
apt-get update
apt-get install -y ffmpeg git build-essential espeak-ng

python -m pip install "pip<24.1" "setuptools<81"
python -m pip install "numpy<2" "torchmetrics==0.9.3" "pytorch-lightning==1.7.7"
python -m pip install -r /workspace/piper/src/python/requirements.txt
python -m pip install -r requirements.txt
```

선택:
- `python_run` 기반 샘플 합성까지 확실히 쓰려면 아래도 추가 설치해두면 편합니다.

```bash
python -m pip install -r /workspace/piper/src/python_run/requirements.txt
```

## 4. 입력 파일 준비

`Piper-ONNX-Voice-Model/input/` 안에 아래 파일을 넣습니다.

- `raw_speech.mp3` 또는 `raw_speech.wav`
- `transcript.txt` 선택

예시:

```txt
Piper-ONNX-Voice-Model/
  input/
    raw_speech.mp3
    transcript.txt
```

## 5. 이전 결과 초기화

새 데이터셋으로 다시 돌릴 때 기존 결과를 섞고 싶지 않으면 삭제합니다.

```bash
cd /workspace/Piper-ONNX-Voice-Model

rm -rf dataset/wav/*
rm -rf output/checkpoints/*
rm -rf output/exported/*
rm -rf output/samples/*
rm -f dataset/metadata.csv dataset/segments_review.csv output/prepared.wav
```

## 6. 오디오 전처리

MP3 입력:

```bash
python scripts/01_prepare_audio.py \
  --input input/raw_speech.mp3 \
  --output output/prepared.wav \
  --sample-rate 22050
```

WAV 입력:

```bash
python scripts/01_prepare_audio.py \
  --input input/raw_speech.wav \
  --output output/prepared.wav \
  --sample-rate 22050
```

이 단계에서 하는 일:
- mono 변환
- sample rate 통일
- loudness normalization
- 긴 무음 제거

## 7. 청크 분할

### 7-1. transcript가 있을 때

```bash
python scripts/02_split_audio.py \
  --audio output/prepared.wav \
  --transcript input/transcript.txt \
  --out-dir dataset/wav \
  --segments-csv dataset/segments_review.csv \
  --min-sec 3 \
  --max-sec 12 \
  --sample-rate 22050
```

주의:
- 현재 transcript 모드는 타임스탬프 정렬이 아니라 균등 분할 기반입니다.
- 품질이 중요하면 사람 검수가 필요합니다.

### 7-2. transcript가 없거나 부정확할 때

```bash
python scripts/02_split_audio.py \
  --audio output/prepared.wav \
  --use-whisper \
  --whisper-model small \
  --out-dir dataset/wav \
  --segments-csv dataset/segments_review.csv \
  --min-sec 3 \
  --max-sec 12 \
  --sample-rate 22050
```

권장:
- 50분 정도 파일은 `Whisper small` 기준 시간이 꽤 걸릴 수 있습니다.
- 정합성이 중요하면 `segments_review.csv`를 샘플링 검수하세요.

## 8. metadata 생성

```bash
python scripts/03_build_metadata.py \
  --segments-csv dataset/segments_review.csv \
  --output dataset/metadata.csv
```

확인:

```bash
sed -n '1,20p' dataset/metadata.csv
```

형식:

```txt
000001|안녕하세요. 오늘은 앱 음성 합성 테스트를 진행합니다.
000002|이 문장은 커스텀 보이스 학습을 위한 예시입니다.
```

## 9. 학습

가장 안전한 시작값:

```bash
export PIPER_REPO=/workspace/piper
export BATCH_SIZE=2
export MAX_EPOCHS=10
bash scripts/05_train.sh
```

50분 정도 데이터에 대해 조금 더 시도해볼 값:

```bash
export PIPER_REPO=/workspace/piper
export BATCH_SIZE=2
export MAX_EPOCHS=20
bash scripts/05_train.sh
```

메모리가 충분하고 실험해볼 때:

```bash
export PIPER_REPO=/workspace/piper
export BATCH_SIZE=4
export MAX_EPOCHS=20
bash scripts/05_train.sh
```

주의:
- `Killed`가 뜨면 보통 메모리 부족입니다.
- 그 경우 `BATCH_SIZE=2` 또는 `1`로 낮추세요.
- `Epoch 9`에서 끝났다면 `MAX_EPOCHS=10` 설정으로 정상 종료한 것입니다.

체크포인트 위치:

```bash
find /workspace/Piper-ONNX-Voice-Model/output/checkpoints -name "*.ckpt" | sort
```

## 10. ONNX export

최신 체크포인트를 자동으로 잡는 방식:

```bash
export PIPER_REPO=/workspace/piper
export TRAINED_CKPT=$(find /workspace/Piper-ONNX-Voice-Model/output/checkpoints -name "*.ckpt" | sort | tail -n 1)
bash scripts/06_export_onnx.sh
```

성공 산출물:
- `output/exported/custom_ko_voice.onnx`
- `output/exported/custom_ko_voice.onnx.json`

## 11. 샘플 합성

```bash
export PIPER_REPO=/workspace/piper
bash scripts/07_test_synthesize.sh
```

성공 산출물:
- `output/samples/test_001.wav`
- `output/samples/test_002.wav`
- `output/samples/test_003.wav`

## 12. 자주 막히는 문제

`ffmpeg를 찾을 수 없습니다`
- 컨테이너 안에서 `apt-get install -y ffmpeg` 필요

`piper_phonemize` 설치 실패
- macOS 로컬보다 Docker Linux 환경이 훨씬 안정적

`pytorch-lightning 1.7.x` 설치 실패
- `pip<24.1` 필요

`NumPy 2.x` 관련 에러
- `numpy<2` 로 고정

`Killed`
- 보통 메모리 부족
- `BATCH_SIZE=2`로 낮추기

`오디오가 웅웅거리기만 함`
- 정합성 문제일 가능성이 큼
- `segments_review.csv`, `metadata.csv`, 실제 wav 샘플을 검수해야 함

`audio amplitude out of range, auto clipped`
- 치명적 에러 아님
- 생성 오디오가 과출력이라 자동 클리핑된 경고

## 13. 재실행 최소 명령

이미 같은 컨테이너를 재사용 중이고 의존성도 설치되어 있다면, 보통 아래만 다시 하면 됩니다.

```bash
cd /workspace/Piper-ONNX-Voice-Model

python scripts/01_prepare_audio.py --input input/raw_speech.mp3 --output output/prepared.wav --sample-rate 22050
python scripts/02_split_audio.py --audio output/prepared.wav --use-whisper --whisper-model small --out-dir dataset/wav --segments-csv dataset/segments_review.csv --min-sec 3 --max-sec 12 --sample-rate 22050
python scripts/03_build_metadata.py --segments-csv dataset/segments_review.csv --output dataset/metadata.csv

export PIPER_REPO=/workspace/piper
export BATCH_SIZE=2
export MAX_EPOCHS=10
bash scripts/05_train.sh

export TRAINED_CKPT=$(find /workspace/Piper-ONNX-Voice-Model/output/checkpoints -name "*.ckpt" | sort | tail -n 1)
bash scripts/06_export_onnx.sh
bash scripts/07_test_synthesize.sh
```

## 14. 품질 관련 현실적인 기대치

- 8분 데이터: 파이프라인 검증용
- 30~60분 데이터: 목소리 느낌 확인 가능
- 1~3시간 이상 정제 데이터: 실제 배포 후보 품질을 노려볼 수 있음

좋은 품질의 핵심은:
- `epoch`보다 데이터 정합성
- `batch size`보다 잘 맞는 `wav-text` 쌍
- 자동 전사 결과 검수
