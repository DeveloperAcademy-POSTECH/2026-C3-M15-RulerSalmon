# Piper

## 개요
Piper는 로컬 오프라인 TTS를 위한 음성 합성 스택. 이 프로젝트에서 다루는 모델은 한국어 단일 화자 기반 Piper 음성 모델

## 문서 작성 기준
- 첨부된 `model-technical-summary.md` 내용 기준
- 저장소 내부 `piper/README.md`, `piper/TRAINING.md`, `piper/VOICES.md` 내용 참고 기준

## 기술적 성격
- Piper 학습 스택 기반 TTS 구조
- VITS 계열 학습 파이프라인 기반 음성 생성 구조
- eSpeak phonemizer 기반 전처리 구조
- ONNX export 기반 런타임 추론 구조
- 단일 화자 한국어 음성 모델 구조

## 현재 모델 구성
- 언어: 한국어
- eSpeak voice: `ko`
- speaker 수: `1`
- sample rate: `22050 Hz`
- phoneme type: `espeak`
- num_symbols: `256`

## 현재 추론 파라미터
- `noise_scale = 0.667`
- `length_scale = 1.0`
- `noise_w = 0.8`

## 현재 산출물
- `my_voice.onnx`
- `my_voice.config.json`
- `my_voice.onnx.json`

### 런타임 관점의 핵심 포인트
- 실제 추론의 핵심 파일은 `my_voice.onnx`
- Piper 런타임이 `model.onnx` 옆의 `model.onnx.json` 형태 설정 파일을 기대하는 구조
- 설정 파일 이름 정합성 확보 필요성

## 데이터셋 구성 방식

### 원본 데이터 성격
- 유튜브/방송 계열 단일 화자 음성 기반 데이터셋
- 단순 단일 화자 데이터셋이 아닌 방송 음향 질감이 포함될 수 있는 데이터셋
- 압축 질감, 저역 울림, 공간 잔향, 마이크 특성, 방송용 후처리 가능성 포함 데이터셋

### 데이터 생성 흐름
1. 긴 원본 오디오 준비
2. Whisper timestamp 기반 발화 단위 분할
3. 각 클립별 txt 전사 생성
4. `metadata.csv` 생성

### 1차 데이터셋 규모
- utterance 수: `1466`
- wav 수: `1466`
- txt 수: `1466`

## 전사 검수 방식

### 검수 목적
- 1000개 이상 클립의 수작업 검수 비용 절감 목적
- 자동화 기반 전사 audit 수행 목적

### 검수 흐름
1. 각 학습용 wav 파일에 Whisper 재실행
2. 기존 전사와 Whisper 재전사 비교
3. 유사도 점수 계산
4. CSV 형태 audit 결과 생성

### audit 주요 지표
- `score`
- `char_similarity`
- `token_similarity`
- `reference_text`
- `whisper_text`

### 현재 audit 결과
- audit 대상 수: `1466`
- 평균 score: `94.24`

### score 해석 시 주의점
- 최종 음질 점수가 아닌 전사 유사도 평균값
- 레벤슈타인 거리 기반 유사도 알고리즘 기준 값

## 정제 기준 강화 배경

### 단순 score 기반 필터링의 한계
- 깨진 문자 혼입 가능성
- 한국어 외 잡문 혼입 가능성
- 짧은 감탄사/추임새 포함 가능성
- 길이는 짧지만 score만 높은 파일 존재 가능성
- Whisper와 길이 차이가 큰 파일 존재 가능성

### 강화된 필터링 목적
- 문자열 유사도보다 학습용 샘플의 순수성 확보 목적
- TTS 품질 저하 가능성이 있는 샘플 제거 목적

## 현재 순수성 기반 필터링 구조

### 사용 지표
- `score`
- `purity_score`
- `hangul_ratio`
- `mismatch_ratio`
- `suspicious_char_count`
- clip duration
- text length
- token count
- filler/interjection 여부

### 주요 지표 의미

#### score
- 기존 전사와 Whisper 재전사의 유사도

#### purity_score
- 전사 일치도, 한국어 비율, 길이 mismatch, 이상 문자, 텍스트 길이, 클립 길이 등을 함께 반영한 종합 순수성 점수

#### hangul_ratio
- 전체 텍스트 대비 한국어 비율

#### mismatch_ratio
- 기존 전사와 Whisper 전사 간 길이 차이의 정규화 값

#### suspicious_char_count
- 깨진 문자 및 이상 문자 개수

## strict keep 기준
- `score >= 80`
- `purity_score >= 88`
- `hangul_ratio >= 0.7`
- `mismatch_ratio <= 0.25`
- `suspicious_char_count == 0`

## 필터링 결과
- keep: `1031`
- remove: `435`

## 최종 학습용 데이터셋
- utterance 수: `1031`
- wav 수: `1031`
- txt 수: `1031`

## Piper 공식 학습 구조와의 연결 지점

### Piper 학습 문서 기준 핵심 단계
1. dataset 준비
2. preprocess 수행
3. training 수행
4. export 수행

### 내부 문서에서 확인 가능한 핵심 설정
- quality 단계 선택 구조
- single-speaker / multi-speaker 선택 구조
- `config.json`, `dataset.jsonl` 중심 학습 구조
- ONNX export 기반 추론 구조

## 이 프로젝트에서 읽어야 할 포인트
- 현재 모델은 단순히 한국어 TTS 모델이 아니라 한국어 단일 화자 Piper 기반 모델이라는 점
- 음성 품질은 모델 구조뿐 아니라 데이터 정제 품질에 크게 좌우된다는 점
- 현재 튜닝 포인트는 모델 아키텍처보다 filtered dataset 품질과 strict keep 기준이라는 점

## 정리
Piper 관련 부록은 현재 음성 모델이 어떤 계열의 TTS 모델인지, 어떤 데이터 정제 과정을 거쳤는지, 그리고 최종 학습셋이 어떤 기준으로 선택되었는지 설명하는 참고 문서
