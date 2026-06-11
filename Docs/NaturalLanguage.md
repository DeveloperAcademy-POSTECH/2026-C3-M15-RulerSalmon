# NaturalLanguage

## 개요
NaturalLanguage는 Apple의 자연어 처리 프레임워크. 문장 분리, 토크나이징, 언어 기반 전처리, 텍스트 분석 보조 처리에 적합한 로컬 NLP 계층

## 기술적 성격
- Apple 제공 경량 자연어 처리 프레임워크
- 문장 단위 분리와 토큰 단위 분석에 적합한 전처리 계층
- 생성형 모델이나 학습 모델 앞단에서 입력 정제를 담당하는 구조

## 이 앱에서 NaturalLanguage가 필요한 이유
- 회고 입력이 한 문장으로 끝나지 않는 경우가 많다는 점
- 분류 모델을 자연어 입력 위에서 다루기 위한 보조 계층 필요성
- 감정 분석 결과를 키워드 단위로 다시 정리할 필요성

## 이 앱에서의 사용 역할
- `NLModel` 기반 4L 분류 실행 역할
- `NLTokenizer` 기반 키워드 추출 보조 역할
- 감정 분석 보조 전처리 역할
- 자연어 관련 경량 분석 보조 역할

## 실제 사용 위치
- `Services/Report/FourLService.swift`
- `Services/SentimentAnalysis/RetrospectiveSentimentAnalyzer.swift`

## 현재 파이프라인에서의 사용 방식

### 4L 분류 실행
- `FourLService`에서 `NLModel(contentsOf:)` 기반 분류 모델 로드
- 문장 chunk별 predicted label hypotheses 계산 구조
- primary label, secondary label, fourL total confidence 계산 구조

### 키워드 추출 보조
- `RetrospectiveSentimentAnalyzer`에서 `NLTokenizer(unit: .word)` 사용
- 감정 세그먼트에서 단어 단위 토큰을 추출한 뒤 stopword를 제외하는 방식
- positive 및 negative keyword 집계에 활용되는 구조

### 커스텀 전처리와의 혼합
- 문장 분리 자체는 현재 `SentenceChunkerService`의 separator 기반 커스텀 처리 구조
- NaturalLanguage는 현재 전체 문장 분리보다 모델 실행과 단어 토큰화 쪽에서 사용되는 구조

## 이 앱에서 중요하게 보는 기술 포인트

### 긴 발화의 분해 방향성
- 사용자 입력을 한 덩어리로 보지 않는 분석 방향성
- chunk 단위 분석과 NaturalLanguage 기반 분류 조합 구조

### 분석 입력 품질 개선
- hypotheses 기반 confidence 계산 안정성
- 토큰 추출 품질이 감정 키워드 집계 결과에 미치는 영향

### 온디바이스 경량 처리
- 네트워크 없는 환경에서도 바로 사용할 수 있는 로컬 분석 계층
- 생성형 모델 호출 전에 가볍게 사용할 수 있는 자연어 처리 보조 계층

## MVP에서 NaturalLanguage를 선택한 이유
- 입력 전처리 품질 향상
- 온디바이스 환경에서의 경량 활용성
- Core ML이나 Foundation Models에 넣기 전 단계로서의 적합성

## 현재 한계와 고려 사항
- 의미적 문맥 이해보다 분류와 토큰화 보조 역할 중심 한계
- 문장 분리 자체는 NaturalLanguage가 아니라 커스텀 separator 로직 기반 상태
- 결국 후속 Core ML 및 Foundation Models와 함께 사용할 때 가장 큰 효과

## 정리
NaturalLanguage는 이 앱에서 4L 분류 실행과 감정 키워드 토큰화를 담당하는 경량 로컬 NLP 계층
