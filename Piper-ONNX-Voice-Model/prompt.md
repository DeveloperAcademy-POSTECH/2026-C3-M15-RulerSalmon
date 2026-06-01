너는 음성합성/TTS 엔지니어다.

목표:
8분 정도 되는 한국어 스피치 오디오 1개를 기반으로 Piper TTS 커스텀 보이스 학습 POC를 구성해줘.
최종 목표는 iOS 앱에 넣을 수 있는 Piper ONNX voice model을 만드는 것이다.

전제:
- 학습은 앱에서 하지 않는다.
- 학습은 로컬 Mac 또는 Linux GPU 서버에서 실행할 수 있게 한다.
- 우선 목표는 고품질이 아니라 “학습 파이프라인 검증”이다.
- 입력 오디오는 약 8분짜리 단일 화자 한국어 스피치다.
- 오디오와 대본 transcript가 있다고 가정한다.
- 만약 transcript가 없으면 Whisper로 초벌 transcript를 만들고, 사람이 검수할 수 있는 구조를 제공한다.
- 최종 산출물은 다음과 같다:
  - dataset 정리 스크립트
  - metadata.csv
  - Piper 학습 실행 명령
  - ONNX export 명령
  - 샘플 합성 명령
  - iOS 앱에서 import할 파일 목록

요구사항:
1. 프로젝트 폴더 구조를 설계해줘.

예상 구조:
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
  README.md

2. 오디오 전처리 스크립트를 작성해줘.

해야 할 일:
- 입력 파일을 mono WAV로 변환
- sample rate를 22050Hz 또는 24000Hz로 통일
- 음량 정규화
- 너무 긴 무음 제거
- 결과 파일을 output 또는 dataset 준비용 위치에 저장

가능하면 ffmpeg를 사용하고, Python에서 subprocess로 호출해도 된다.

3. 8분짜리 오디오를 문장 단위 또는 3~12초 단위 clip으로 나누는 스크립트를 작성해줘.

주의사항:
- Piper 학습용 데이터는 너무 긴 clip이 좋지 않다.
- 3~12초 정도의 clip을 목표로 한다.
- transcript가 문장 단위로 있으면 문장 기준으로 나눈다.
- transcript 타임스탬프가 없으면 Whisper word/segment timestamp를 활용하는 방식을 제안해줘.
- 자동 분할 결과는 사람이 검수할 수 있도록 CSV를 만든다.

출력 예:
dataset/wav/000001.wav
dataset/wav/000002.wav
dataset/wav/000003.wav

4. metadata.csv를 만들어줘.

포맷은 Piper 학습에 맞게 구성한다.
가능한 포맷 예:
000001|안녕하세요. 오늘은 앱 음성 합성 테스트를 진행합니다.
000002|이 문장은 커스텀 보이스 학습을 위한 예시입니다.

또는 Piper 학습 스크립트가 요구하는 포맷에 맞게 조정해줘.

5. 한국어 텍스트 정규화 함수를 만들어줘.

최소 처리:
- 앞뒤 공백 제거
- 중복 공백 제거
- 특수문자 제거 또는 치환
- 따옴표 정리
- 괄호 안 불필요한 내용 제거 옵션
- 숫자, 영어, 약어는 우선 그대로 두되 TODO로 남겨라

추후 개선 TODO:
- 123 → 백이십삼 / 일이삼 선택 처리
- iOS → 아이오에스
- API → 에이피아이
- % → 퍼센트
- 날짜/시간 정규화

6. Piper 학습 환경 구성 방법을 README에 적어줘.

가능하면 다음 두 가지 루트를 모두 적어줘:
- Docker 기반 Linux/NVIDIA GPU
- Python venv/conda 기반 로컬 실행

단, Apple Silicon Mac에서 MPS 학습은 불안정할 수 있으니 “POC 가능, 본 학습은 NVIDIA CUDA 권장”이라고 명시해줘.

7. Piper 학습 명령을 작성해줘.

조건:
- 8분 데이터라서 과적합이 매우 쉽게 발생한다.
- 따라서 high quality 모델을 기대하지 말고, pipeline verification이라고 명시한다.
- pre-trained checkpoint에서 fine-tuning하는 방향을 우선 제안한다.
- batch size, max epochs, validation split, checkpoint 저장 경로를 설정할 수 있게 해줘.
- 학습 스크립트는 bash로 만들어줘.
- 실제 Piper repository의 현재 학습 명령과 맞지 않을 수 있으므로, README에 “사용 중인 Piper 버전에 맞춰 명령 확인 필요”라고 적어줘.

8. ONNX export 스크립트를 만들어줘.

최종적으로 아래 파일이 나오게 해줘:
output/exported/custom_ko_voice.onnx
output/exported/custom_ko_voice.onnx.json

9. 테스트 합성 스크립트를 만들어줘.

입력 문장 예:
안녕하세요. 이것은 아이오에스 앱에서 사용할 커스텀 음성 테스트입니다.
오늘 날씨가 참 좋네요.
사용자의 문장을 자연스러운 목소리로 읽어드립니다.

출력:
output/samples/test_001.wav
output/samples/test_002.wav
output/samples/test_003.wav

10. 8분 데이터셋의 한계와 평가 방법을 README에 명확히 적어줘.

반드시 포함:
- 8분은 커스텀 보이스 품질을 내기엔 매우 부족하다.
- 목소리 느낌은 일부 붙을 수 있지만, 발음 안정성/억양/긴 문장 품질은 낮을 수 있다.
- 같은 스피치 톤에 과적합될 가능성이 높다.
- 최소 30~60분, 권장 1~3시간 이상의 정제 데이터가 필요하다.
- POC 성공 기준은 “완성도”가 아니라 다음이다:
  - 학습 파이프라인이 작동한다.
  - ONNX export가 된다.
  - 샘플 음성이 생성된다.
  - iOS 앱에서 모델을 로드할 수 있다.
  - 특정 화자의 음색이 약간이라도 반영되는지 확인한다.

11. iOS importing 가이드도 README에 추가해줘.

내용:
- 앱에 포함해야 할 파일:
  - custom_ko_voice.onnx
  - custom_ko_voice.onnx.json
  - espeak-ng-data 또는 phonemizer 관련 데이터가 필요한 경우 해당 리소스
- 권장 런타임:
  - sherpa-onnx iOS
  - 또는 ONNX Runtime 직접 사용
- 앱에서는 학습하지 않고, 추론만 한다.
- voice pack 구조를 추천한다.

voice pack 예:
custom_ko_voice_v1.zip
  manifest.json
  custom_ko_voice.onnx
  custom_ko_voice.onnx.json
  preview.wav

manifest.json 예:
{
  "id": "custom_ko_voice_v1",
  "name": "Custom Korean Voice v1",
  "language": "ko",
  "sampleRate": 22050,
  "model": "custom_ko_voice.onnx",
  "config": "custom_ko_voice.onnx.json",
  "version": "0.1.0",
  "trainingDataMinutes": 8,
  "quality": "poc"
}

12. 전체 코드를 생성해줘.

반드시 생성할 파일:
- README.md
- requirements.txt
- scripts/01_prepare_audio.py
- scripts/02_split_audio.py
- scripts/03_build_metadata.py
- scripts/04_normalize_text.py
- scripts/05_train.sh
- scripts/06_export_onnx.sh
- scripts/07_test_synthesize.sh
- voice-pack/manifest.example.json

13. 스크립트는 실제로 실행 가능한 수준으로 작성해줘.

다만 Piper 학습 명령은 버전별 차이가 있을 수 있으므로, 해당 부분은 주석으로 “Piper 버전에 맞게 확인 필요”라고 남겨줘.

14. README 마지막에 다음 섹션을 넣어줘.

- Quick Start
- Data Preparation
- Training
- Export to ONNX
- Test Synthesis
- iOS Importing
- Limitations of 8-minute dataset
- Next Steps

15. 마지막으로, 이 POC 이후 품질 개선 로드맵을 제안해줘.

로드맵:
- 8분 데이터로 pipeline 검증
- 30분 데이터로 1차 voice similarity 확인
- 60분 데이터로 발음/억양 안정화
- 2~3시간 데이터로 앱 배포 후보 모델 생성
- 숫자/영어/고유명사 normalization 강화
- iPhone 실기기에서 latency, memory, battery 테스트

중요:
- 결과물을 설명만 하지 말고, 실제 파일 내용과 코드를 만들어줘.
- bash 스크립트에는 set -euo pipefail을 넣어줘.
- Python 스크립트에는 argparse를 사용해줘.
- 에러 메시지는 사람이 이해하기 쉽게 작성해줘.
- 한국어 주석을 적당히 포함해줘.
