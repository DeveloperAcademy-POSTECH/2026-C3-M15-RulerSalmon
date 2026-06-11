# Core ML

## 개요
Core ML은 Apple의 온디바이스 머신러닝 실행 프레임워크. 학습된 모델을 앱 번들에 포함하고 디바이스 내부에서 빠르게 추론하는 구조

## 기술적 성격
- 로컬 추론 중심 구조
- 모델 번들 포함 방식
- 네트워크 비의존형 분류 작업 처리 구조
- 생성형 모델이 아닌 분류형/점수형 추론에 강한 실행 계층

## 이 앱에서 Core ML이 필요한 이유
- 회고 발화를 먼저 기계적으로 분류할 1차 분류 계층 필요성
- 감정 분석을 규칙보다 안정적으로 점수화할 필요성
- 생성형 모델 호출 이전에 lightweight 분류 단계를 둘 필요성

## 이 앱에서의 사용 역할
- 4L 분류용 1차 classifier 역할
- 감정 분석용 score predictor 역할
- 생성형 Foundation Model 앞단의 deterministic 분석 계층 역할

## 실제 사용 위치
- `Resources/FourLClassifier.mlmodel`
- `Resources/MLModels/SentimentAnalysis/HowRUInt8.mlpackage`
- `Services/Report/FourLService.swift`
- `Services/SentimentAnalysis/RetrospectiveSentimentAnalyzer.swift`
- `Services/SentimentAnalysis/HowRUTokenizer.swift`

## 현재 사용 모델

### 1. FourLClassifier
- 회고 발화를 `Liked`, `Learned`, `Lacked`, `Longed for` 관점으로 분류하는 모델
- `FourLService`에서 `NLModel` 형태로 로드해 사용
- 문장 chunk 단위 분류 방식

### 2. HowRUInt8
- 회고 전사문의 감정 score 계산용 모델
- `RetrospectiveSentimentAnalyzer`에서 로드해 사용
- 세그먼트 단위 감정 score 추론 구조

## 현재 파이프라인에서의 사용 방식

### 4L 분류 파이프라인
1. 사용자 입력 수집
2. `SentenceChunkerService`를 통한 의미 단위 분리
3. `FourLService`에서 문장별 4L 분류
4. 분류 confidence, secondary label, fourL total score 계산
5. Foundation Model 검토 단계로 결과 전달

### 감정 분석 파이프라인
1. 회고 전사문 수집
2. 세그먼트 단위 분리
3. `HowRUTokenizer`를 통한 모델 입력 변환
4. `HowRUInt8` 추론 수행
5. positive/negative percentage 및 keyword 집계

## 이 앱에서 중요하게 보는 기술 포인트

### 분류와 생성의 역할 분리
- Core ML의 기계적 1차 분류
- Foundation Models의 자연어 생성과 해석 보강
- 두 계층을 섞지 않고 단계별 책임 분리

### fallback 설계
- 모델 로드 실패 시 앱 전체 중단 방지
- 감정 분석 모델 실패 시 lexical fallback 사용 구조
- 4L 분류 모델 미존재 시 empty fallback 경로 제공

### 세밀한 입력 단위 처리
- 긴 사용자 발화를 그대로 분류하지 않는 방식
- chunk 단위 분리 후 개별 분류 수행 구조
- 세그먼트 단위 감정 분석을 통한 부분 감정 반영 구조

## 현재 한계와 고려 사항
- 모델 품질 자체는 학습 데이터 품질의 영향
- 분류 confidence가 높아도 사용자 맥락 전체를 설명하지는 못하는 한계
- Core ML만으로 자연스러운 질문 생성 불가능

## 정리
Core ML은 이 앱에서 회고 내용을 먼저 구조화하고 수치화하는 1차 분석 엔진 역할
