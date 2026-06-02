너는 음성합성/TTS 엔지니어이자 iOS 앱 개발자다.

목표:
8분 정도 되는 한국어 스피치 오디오 1개를 기반으로 MeloTTS 커스텀 보이스 학습 POC를 구성하고, iOS 앱에서 샘플 음성을 생성/재생하는 데모 프로젝트까지 만든다.

최종 목표:
- 한국어 특정 화자 목소리로 MeloTTS fine-tuning POC를 수행한다.
- 학습은 앱에서 하지 않는다.
- 앱에서는 이미 export된 모델을 import해서 추론만 수행한다.
- iOS 샘플 앱에서 특정 Text를 입력하면 커스텀 보이스로 읽는 구조를 검증한다.

전제:
- 입력 오디오는 약 8분짜리 단일 화자 한국어 스피치다.
- transcript가 있다고 가정한다.
- transcript가 없으면 Whisper로 초벌 transcript를 만들고, 사람이 검수할 수 있게 한다.
- 8분 데이터는 제품용 품질을 내기엔 부족하다.
- 이번 목적은 “품질”이 아니라 “학습 → export → iOS import → 재생” 파이프라인 검증이다.
- zero-shot voice cloning이 아니라, 특정 화자 데이터로 fine-tuning하거나 speaker adaptation하는 방향이다.
- MeloTTS는 버전/포크/ONNX export 지원 상태에 따라 구현 차이가 있을 수 있으므로, 학습 및 export 명령에는 주석으로 확인 지점을 명확히 남긴다.

중요:
- 결과물을 설명만 하지 말고 실제 파일과 코드를 생성해라.
- iOS 앱 샘플은 SwiftUI 기반으로 만든다.
- 앱에서는 모델 학습을 절대 하지 않는다.
- 가능하면 ONNX Runtime Mobile 또는 sherpa-onnx 연동 구조를 제안한다.
- MeloTTS의 ONNX export가 바로 되지 않는 경우를 대비해, “임시 서버 합성 모드”와 “로컬 ONNX 추론 모드”를 분리한 구조로 만들어라.
- 최종 목표는 로컬 ONNX 추론이지만, POC 단계에서는 서버 합성 모드로 iOS UI/재생 흐름을 먼저 검증할 수 있게 한다.

프로젝트 전체 구조를 다음처럼 만들어라:

melotts-ios-poc/
  README.md
  requirements.txt

  input/
    raw_speech.wav
    transcript.txt

  dataset/
    wav/
    metadata.csv
    metadata.review.csv

  scripts/
    01_prepare_audio.py
    02_split_audio.py
    03_build_metadata.py
    04_normalize_text.py
    05_train_melotts.sh
    06_export_onnx.sh
    07_test_synthesize.py
    08_package_voice_pack.py

  training/
    configs/
    checkpoints/
    logs/

  output/
    exported/
    samples/
    voice-pack/

  server/
    README.md
    app.py
    synthesize.py

  ios/
    MeloTTSDemo/
      MeloTTSDemo.xcodeproj 또는 Package.swift
      MeloTTSDemo/
        MeloTTSDemoApp.swift
        ContentView.swift
        TTSViewModel.swift
        TTSService.swift
        LocalONNXTTSService.swift
        RemoteTTSService.swift
        AudioPlayer.swift
        VoicePackManager.swift
        Models/
          VoiceManifest.swift
        Resources/
          voice-pack-placeholder/
            manifest.example.json

요구사항:

1. README.md를 작성해라.

README에는 반드시 다음 섹션을 포함해라:
- Overview
- Why MeloTTS
- Architecture
- Quick Start
- Data Preparation
- Training MeloTTS
- Export to ONNX
- Test Synthesis
- Local iOS Inference
- Remote Server Fallback
- Voice Pack Format
- Limitations of 8-minute dataset
- Evaluation Checklist
- Next Steps

README에서 명확히 설명해라:
- 8분 데이터는 품질용이 아니라 POC용이다.
- 목소리 느낌은 일부 붙을 수 있지만 발음 안정성, 억양, 긴 문장 품질은 낮을 수 있다.
- 최소 30~60분, 권장 1~3시간 이상 정제 데이터가 필요하다.
- iOS 앱에서는 학습하지 않는다.
- 앱에는 export된 모델과 config만 들어간다.
- MeloTTS의 iOS 로컬 추론은 ONNX export 가능 여부와 전처리/G2P 의존성에 따라 난이도가 있다.
- 따라서 샘플 앱은 RemoteTTSService와 LocalONNXTTSService를 모두 갖는다.

2. 오디오 전처리 스크립트 `scripts/01_prepare_audio.py`를 작성해라.

기능:
- 입력 오디오를 mono WAV로 변환
- sample rate를 44100Hz, 24000Hz, 22050Hz 중 옵션으로 선택 가능
- 기본값은 44100Hz 또는 MeloTTS 권장값으로 설정
- 음량 정규화
- 너무 긴 무음 제거 옵션
- ffmpeg를 사용
- argparse 사용
- 에러 메시지는 사람이 이해하기 쉽게 작성

예시 실행:
python scripts/01_prepare_audio.py \
  --input input/raw_speech.wav \
  --output output/prepared_speech.wav \
  --sample-rate 44100

3. 오디오 분할 스크립트 `scripts/02_split_audio.py`를 작성해라.

기능:
- 8분 스피치를 3~12초 정도의 clip으로 분할
- transcript에 timestamp가 있으면 timestamp 기반 분할
- timestamp가 없으면 Whisper segment 결과를 활용할 수 있는 구조
- 자동 분할 결과를 `dataset/metadata.review.csv`로 저장
- 사람이 검수 후 `metadata.csv`로 확정할 수 있게 한다.
- wav 파일은 `dataset/wav/000001.wav` 형식으로 저장
- argparse 사용

주의:
- clip이 너무 길면 학습 품질이 나빠질 수 있다.
- 너무 짧은 clip은 제거하거나 warning을 남긴다.
- 무음 clip은 제거한다.

4. `scripts/03_build_metadata.py`를 작성해라.

기능:
- `metadata.review.csv`를 읽어서 MeloTTS 학습용 metadata를 생성
- 가능한 포맷을 README에 명시
- 기본 포맷은 아래처럼 한다:

000001|안녕하세요. 오늘은 음성 합성 테스트를 진행합니다.
000002|이 문장은 커스텀 보이스 학습을 위한 예시입니다.

또는 MeloTTS가 요구하는 포맷이 다르면 쉽게 수정할 수 있게 상단에 FORMAT_MODE를 둔다.

5. `scripts/04_normalize_text.py`를 작성해라.

한국어 텍스트 정규화 함수 포함:
- 앞뒤 공백 제거
- 중복 공백 제거
- 따옴표 정리
- 불필요한 특수문자 제거
- 괄호 안 내용 제거 옵션
- 줄바꿈 제거
- 숫자/영어/약어는 우선 그대로 두고 TODO로 남김

TODO 주석:
- 123 → 백이십삼 또는 일이삼
- iOS → 아이오에스
- API → 에이피아이
- % → 퍼센트
- 날짜/시간 정규화
- 고유명사 사전 처리

CLI로도 실행 가능하게 해라:
python scripts/04_normalize_text.py --text "iOS 앱에서 3개의 API를 호출합니다."

6. MeloTTS 학습 스크립트 `scripts/05_train_melotts.sh`를 작성해라.

조건:
- set -euo pipefail 포함
- 환경 변수로 DATASET_DIR, OUTPUT_DIR, BASE_MODEL, CONFIG_PATH, MAX_EPOCHS, BATCH_SIZE를 받을 수 있게 한다.
- 8분 데이터는 overfitting 위험이 크므로 README와 스크립트 주석에 명시
- 가능하면 pretrained Korean MeloTTS model에서 fine-tuning하는 방향으로 작성
- 실제 MeloTTS repo 버전에 따라 명령이 다를 수 있으므로 TODO와 확인 지점 남김
- 명령이 확정되지 않은 부분은 pseudo-command가 아니라 실행 가능한 shell 구조와 명확한 placeholder로 작성

예상 실행:
DATASET_DIR=dataset \
OUTPUT_DIR=training/checkpoints/custom_ko_voice \
MAX_EPOCHS=50 \
BATCH_SIZE=4 \
bash scripts/05_train_melotts.sh

7. ONNX export 스크립트 `scripts/06_export_onnx.sh`를 작성해라.

목표 산출물:
output/exported/custom_ko_melotts.onnx
output/exported/custom_ko_melotts.config.json
output/exported/tokenizer 또는 phonemizer 관련 파일이 필요한 경우 포함

조건:
- set -euo pipefail 포함
- CHECKPOINT_PATH, CONFIG_PATH, EXPORT_DIR 환경 변수 사용
- MeloTTS의 ONNX export가 현재 repo에서 바로 안 될 수 있으므로 fallback 안내 포함
- TorchScript/Core ML export 가능성도 README에 간단히 비교
- 최종 iOS 샘플 앱은 ONNX Runtime Mobile 기준 인터페이스로 작성하되, export 실패 시 RemoteTTSService로 UI/재생을 먼저 검증할 수 있게 한다.

8. 테스트 합성 스크립트 `scripts/07_test_synthesize.py`를 작성해라.

기능:
- 학습된 checkpoint 또는 export된 모델로 테스트 문장 합성
- output/samples/test_001.wav 등으로 저장
- argparse 사용
- 아직 실제 MeloTTS API가 버전에 따라 다르면 adapter 구조로 작성

테스트 문장:
- 안녕하세요. 이것은 아이오에스 앱에서 사용할 커스텀 음성 테스트입니다.
- 오늘 날씨가 참 좋네요.
- 사용자의 문장을 자연스러운 목소리로 읽어드립니다.
- 숫자와 영어가 포함된 문장도 테스트합니다. iOS 앱에서 3개의 API를 호출합니다.

9. voice pack 패키징 스크립트 `scripts/08_package_voice_pack.py`를 작성해라.

기능:
- export된 모델, config, preview wav를 zip으로 묶음
- manifest.json 생성
- checksum 생성
- version, language, sampleRate, model filename, config filename 포함

voice pack 구조:
custom_ko_melotts_v1.zip
  manifest.json
  custom_ko_melotts.onnx
  custom_ko_melotts.config.json
  preview.wav
  tokenizer/
  phonemizer/

manifest.json 예:
{
  "id": "custom_ko_melotts_v1",
  "name": "Custom Korean MeloTTS Voice v1",
  "engine": "melotts",
  "language": "ko",
  "sampleRate": 44100,
  "model": "custom_ko_melotts.onnx",
  "config": "custom_ko_melotts.config.json",
  "version": "0.1.0",
  "trainingDataMinutes": 8,
  "quality": "poc",
  "requires": {
    "runtime": "onnxruntime-mobile",
    "textNormalizer": true,
    "phonemizer": true
  }
}

10. 간단한 FastAPI 서버 fallback을 만들어라.

폴더:
server/
  README.md
  app.py
  synthesize.py

목적:
- iOS 앱 UI와 오디오 재생 흐름을 먼저 개발할 수 있게 한다.
- 로컬 ONNX 추론이 준비되기 전에는 서버에서 합성된 wav를 내려받아 재생한다.
- endpoint:
  POST /synthesize
  body:
  {
    "text": "안녕하세요.",
    "voiceId": "custom_ko_melotts_v1"
  }
  response:
  audio/wav

주의:
- server는 개발용 fallback이다.
- 최종 제품 목표는 iOS on-device inference다.

11. iOS SwiftUI 샘플 앱을 작성해라.

목표:
- TextEditor 또는 TextField에 문장 입력
- “Synthesize” 버튼
- voice 선택 placeholder
- Remote 모드 / Local ONNX 모드 토글
- 합성 중 loading 표시
- 생성된 wav/pcm 재생
- 에러 메시지 표시
- VoicePackManager로 voice pack 설치 여부 확인

필수 파일:
- MeloTTSDemoApp.swift
- ContentView.swift
- TTSViewModel.swift
- TTSService.swift
- RemoteTTSService.swift
- LocalONNXTTSService.swift
- AudioPlayer.swift
- VoicePackManager.swift
- Models/VoiceManifest.swift

12. Swift 코드 구조를 다음처럼 작성해라.

TTSService 프로토콜:
protocol TTSService {
    func synthesize(text: String, voiceId: String) async throws -> URL
}

RemoteTTSService:
- FastAPI 서버의 /synthesize 호출
- wav 파일을 임시 디렉토리에 저장
- 저장된 URL 반환

LocalONNXTTSService:
- 아직 실제 ONNX Runtime 연동이 완성되지 않아도 된다.
- 단, 인터페이스와 TODO를 명확히 작성
- 모델 파일 path, config path, tokenizer/phonemizer path를 로드하는 구조를 잡아라.
- 실제 추론 부분은 `throw TTSServiceError.localRuntimeNotImplemented`로 남겨도 된다.
- 나중에 ONNX Runtime Mobile 또는 sherpa-onnx로 교체 가능하게 작성

AudioPlayer:
- AVAudioPlayer 기반
- URL로 받은 wav 재생
- stop 기능 제공

VoicePackManager:
- Application Support/VoicePacks 디렉토리 관리
- manifest.json 읽기
- 설치된 voice 목록 반환
- 샘플 manifest를 Resources에 포함

13. iOS 앱 README 또는 주석에 다음을 명시해라.

- Remote mode는 개발 편의용이다.
- Local mode는 최종 목표다.
- ONNX Runtime Mobile 연동 시 필요한 작업:
  - custom_ko_melotts.onnx 로드
  - tokenizer/phonemizer 로드
  - text normalization
  - tensor input 구성
  - output PCM/WAV 변환
  - AVAudioEngine 또는 AVAudioPlayer 재생
- MeloTTS는 텍스트 전처리 의존성이 있으므로 Python과 동일한 normalization 결과가 나오게 해야 한다.

14. 전체 실행 순서를 README에 적어라.

예시:

# 1. Install dependencies
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

# 2. Prepare audio
python scripts/01_prepare_audio.py --input input/raw_speech.wav --output output/prepared_speech.wav

# 3. Split audio
python scripts/02_split_audio.py --input output/prepared_speech.wav --transcript input/transcript.txt --output-dir dataset

# 4. Review metadata
open dataset/metadata.review.csv
# 사람이 검수 후 metadata.csv로 저장

# 5. Train
DATASET_DIR=dataset OUTPUT_DIR=training/checkpoints/custom_ko_voice bash scripts/05_train_melotts.sh

# 6. Export
CHECKPOINT_PATH=training/checkpoints/custom_ko_voice/best.ckpt EXPORT_DIR=output/exported bash scripts/06_export_onnx.sh

# 7. Test synthesis
python scripts/07_test_synthesize.py --model output/exported/custom_ko_melotts.onnx --text "안녕하세요."

# 8. Package voice
python scripts/08_package_voice_pack.py --export-dir output/exported --preview output/samples/test_001.wav --output output/voice-pack/custom_ko_melotts_v1.zip

# 9. Run fallback server
cd server
uvicorn app:app --host 0.0.0.0 --port 8000

# 10. Run iOS demo app
open ios/MeloTTSDemo/MeloTTSDemo.xcodeproj

15. 평가 체크리스트를 README에 작성해라.

체크 항목:
- 학습이 끝까지 도는가
- 샘플 wav가 생성되는가
- 특정 화자의 음색이 조금이라도 반영되는가
- 발음 오류가 얼마나 나는가
- 긴 문장에서 깨지는가
- ONNX export가 가능한가
- iOS 앱에서 remote mode 재생이 가능한가
- iOS local mode로 넘어가기 위한 blocker가 무엇인가
- 모델 크기
- 첫 음성 출력 지연
- 메모리 사용량
- 배터리 영향

16. 8분 데이터셋의 한계를 강하게 명시해라.

반드시 포함:
- 8분 데이터로는 제품 품질을 기대하면 안 된다.
- single speech tone에 과적합될 수 있다.
- 다양한 발음, 감정, 문장 길이, 숫자, 영어, 고유명사가 부족하다.
- POC 이후 최소 30~60분 데이터로 재학습해야 한다.
- 앱 배포 후보 모델은 1~3시간 이상의 정제 데이터가 바람직하다.

17. 다음 단계 로드맵을 README에 작성해라.

로드맵:
- 8분 데이터로 pipeline 검증
- iOS remote mode로 UI/재생 흐름 검증
- ONNX export 가능성 검증
- LocalONNXTTSService 실제 구현
- 30분 데이터로 voice similarity 확인
- 60분 데이터로 발음/억양 안정화
- 2~3시간 데이터로 앱 배포 후보 모델 생성
- 숫자/영어/고유명사 normalization 강화
- iPhone 실기기에서 latency, memory, battery 테스트
- voice pack 다운로드/업데이트 시스템 구현

18. 각 파일을 실제 코드로 생성해라.

반드시 생성:
- README.md
- requirements.txt
- scripts/01_prepare_audio.py
- scripts/02_split_audio.py
- scripts/03_build_metadata.py
- scripts/04_normalize_text.py
- scripts/05_train_melotts.sh
- scripts/06_export_onnx.sh
- scripts/07_test_synthesize.py
- scripts/08_package_voice_pack.py
- server/README.md
- server/app.py
- server/synthesize.py
- ios/MeloTTSDemo/MeloTTSDemo/MeloTTSDemoApp.swift
- ios/MeloTTSDemo/MeloTTSDemo/ContentView.swift
- ios/MeloTTSDemo/MeloTTSDemo/TTSViewModel.swift
- ios/MeloTTSDemo/MeloTTSDemo/TTSService.swift
- ios/MeloTTSDemo/MeloTTSDemo/RemoteTTSService.swift
- ios/MeloTTSDemo/MeloTTSDemo/LocalONNXTTSService.swift
- ios/MeloTTSDemo/MeloTTSDemo/AudioPlayer.swift
- ios/MeloTTSDemo/MeloTTSDemo/VoicePackManager.swift
- ios/MeloTTSDemo/MeloTTSDemo/Models/VoiceManifest.swift
- ios/MeloTTSDemo/MeloTTSDemo/Resources/voice-pack-placeholder/manifest.example.json

19. 코딩 스타일:
- Python은 argparse, pathlib, type hints 사용
- bash는 set -euo pipefail 사용
- Swift는 async/await 사용
- 에러 enum을 정의
- UI는 단순하지만 실제 실행 가능한 구조
- TODO는 구체적으로 작성
- 한국어 주석을 적당히 포함

20. 마지막 출력:
- 생성된 파일 트리를 보여줘.
- 실행 순서를 요약해줘.
- MeloTTS ONNX export가 막힐 경우의 대안 3가지를 제안해줘:
  1. 서버 fallback으로 앱 UX 먼저 검증
  2. sherpa-onnx 지원 모델로 우회
  3. Piper/VITS custom voice로 iOS 로컬 추론 우선 검증
