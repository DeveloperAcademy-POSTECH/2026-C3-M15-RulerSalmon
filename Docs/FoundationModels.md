# Foundation Models

## 개요
Foundation Models는 Apple의 온디바이스 생성형 AI 프레임워크. 앱 내부에서 외부 서버 호출 없이 텍스트 생성, 구조화 응답 생성, 짧은 문맥 기반 추론을 수행하는 방식

## 기술적 성격
- Apple 플랫폼 전용 온디바이스 생성형 모델 접근 계층
- `LanguageModelSession` 기반 세션형 호출 구조
- 자유 응답과 구조화 응답을 모두 다루는 생성 계층
- 네트워크 비의존형 동작 구조
- 사용자 텍스트가 디바이스 외부로 나가지 않는 로컬 추론 구조

## 이 앱에서 Foundation Models가 필요한 이유
- 회고 대화에서 자연스러운 후속 질문 생성 필요성
- 1차 분류 결과를 그대로 노출하지 않고 한 번 더 검토할 필요성
- 회고 리포트 문장을 사용자 친화적으로 정제할 필요성
- 요약, 액션 아이템, 인사이트처럼 규칙만으로 만들기 어려운 출력 필요성

## 이 앱에서의 사용 역할
- 회고 채팅 단계의 질문 생성 엔진 역할
- 4L 1차 분류 결과의 2차 검토 계층 역할
- 리포트 문장 정제 및 요약 생성 역할
- 주간 및 월간 인사이트 생성 역할

## 실제 사용 위치
- `Services/ReflectionTurnGenerator.swift`
- `Services/FoundationModelService.swift`
- `Services/ReflectionInsightService.swift`
- `Services/Report/FourLRefinementService.swift`
- `Services/Report/ReflectionFoundationModelService.swift`
- `Services/Report/ReflectionSummaryService.swift`
- `Models/ReflectionSecondPassValidation.swift`
- `Models/TodayReportView/ReflectionSummaryOutput.swift`

## 현재 회고 파이프라인에서의 사용 방식
1. 사용자 발화 입력
2. `FourLService`를 통한 1차 분류 수행
3. 현재 세션 메모리 기반 문맥 검색
4. `ReflectionTurnGenerator`에서 Foundation Model 호출
5. 2차 검토 결과와 다음 질문 동시 생성
6. 리포트 단계에서 정제 및 요약 생성
7. 분석 단계에서 인사이트 문장 생성 및 갱신

## 현재 구현 구조

### 세션 기반 질문 생성 구조
- `ReflectionTurnGenerator` 내부 `LanguageModelSession` 보유 구조
- 고정 instructions와 동적 prompt 분리 구조
- 최근 질문 히스토리, 현재 세션 문맥, 1차 분류 결과를 함께 전달하는 방식

### warm-up 구조
- 첫 응답 지연 완화를 위한 사전 준비 호출 구조
- 채팅 화면 진입 시 `warmUpIfNeeded()` 호출 방식
- 실사용 세션과 분리된 임시 세션 기반 준비 확인 구조

### 구조화 출력 기반 검토 구조
- 질문만 생성하는 단순 호출이 아니라 검토 결과와 질문을 함께 생성하는 구조
- 요약, 차원, 근거, 키워드, confidence를 포함한 검토 payload 생성 방식
- 출력 실패 시 fallback 검토 로직으로 내려가는 이중 안전장치 구조

### 종료 유도와 상태 기반 질문 조절 구조
- `ReflectionCompletionState`를 프롬프트에 전달하는 방식
- 계속 탐색, 마무리 유도, 종료 의사 확인 상태에 따른 질문 톤 조절 구조

### 인사이트 생성 구조
- `ReflectionInsightService`에서 FoundationModelService를 통한 인사이트 후보 및 증분 갱신 구조
- 감정 기록이 일정 수 이상 쌓였을 때 주간/월간 관점의 reflection 및 strength 포인트 생성 구조

## 이 앱에서 중요하게 보는 기술 포인트

### 프롬프트 길이 통제
- 온디바이스 모델의 context window 한계 고려 필요성
- 전체 누적 메모리가 아니라 현재 세션 메모리만 사용하는 경량 문맥 전략
- 최근 질문 3개 정도만 전달하는 제한적 히스토리 전략

### 출력 실패 대비
- structured output 실패 가능성 고려
- 질문이 비질문형 요약으로 생성되는 경우 fallback 치환 구조
- Foundation Model 호출 실패 시 1차 분류 결과 기반 기본 질문 반환 구조

### 역할 분리
- Core ML 계층의 분류 역할과 Foundation Models 계층의 생성 역할 분리
- deterministic 분류와 generative 응답의 역할 분담 구조

## MVP에서 Foundation Models를 선택한 이유
- 온디바이스 동작 가능성
- 높은 보안성과 개인화 가능성
- Apple 생태계 안에서의 권한, 성능, 배포 구조 정합성

## 현재 한계와 고려 사항
- 첫 호출 latency 존재
- context window 초과 가능성
- 긴 회고 문맥 누적 시 질문 반복 또는 품질 저하 가능성
- 시스템 availability에 따른 사용 가능 여부 분기 필요성

## 정리
Foundation Models는 이 앱에서 단순 챗봇 엔진이 아니라, 회고 맥락을 읽고 다음 질문을 생성하며 리포트 문장을 정제하고 인사이트를 생성하는 핵심 생성 계층
