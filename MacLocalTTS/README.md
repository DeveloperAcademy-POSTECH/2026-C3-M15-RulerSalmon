# MacLocalTTS

CosyVoice3 모델을 Mac 로컬에서 실행해 `chaem`, `cindy`, `friday` 임베딩 음성으로 wav 파일을 생성하는 CLI입니다.

## One-shot

```sh
cd MacLocalTTS
swift run MacLocalTTS \
  --text "오늘 회고를 맥 로컬에서 테스트합니다." \
  --voice chaem \
  --output chaem.wav
```

기본 모델은 속도 테스트용 4-bit 모델입니다.

```sh
swift run MacLocalTTS \
  --text "안녕하세요." \
  --voice friday \
  --model aufklarer/CosyVoice3-0.5B-MLX-8bit \
  --output friday.wav
```

## Loop Mode

모델을 한 번만 로드하고 여러 문장을 연속 합성할 때 사용합니다.

```sh
cd MacLocalTTS
swift run MacLocalTTS --loop
```

프롬프트가 뜨면 아래 형식으로 입력합니다.

```txt
voice|text|output.wav
```

예시:

```txt
cindy|안녕하세요. 신디입니다.|cindy.wav
```

## Voice Embeddings

기본 음성 임베딩은 앱 리소스 폴더에서 자동으로 읽습니다.

```txt
../Retrospective-Rulersalmon/Resources/Voices
```

다른 폴더를 쓰려면 `--voices-dir`, 단일 파일을 쓰려면 `--embedding`을 넘기면 됩니다.
