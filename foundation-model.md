# Foundation Model Guide

이 문서는 현재 프로젝트에서 Foundation Model을 어디에 어떻게 쓰는지 정리한 문서다.

## 1. 구성 요소

- `Retrospective-Rulersalmon/Services/FoundationModelService.swift`
  - FM 세션을 생성하고 `respond(to:)`를 통해 실제 호출을 수행하는 공통 래퍼다.
  - `defaultInstructions`로 기본 성격을 정하고, `init(instructions:)`로 기능별 instructions를 주입한다.
  - iOS 26 미만, 모듈 미지원, 호출 실패 시에는 fallback 문자열을 반환한다.

- `Retrospective-Rulersalmon/Services/ReflectionChunkAnalyzer.swift`
  - 회고 발화 청크를 분석하는 FM 입력과 출력을 담당한다.
  - `analysisInstructions`가 분석용 기본 지시문이다.
  - `analysisPrompt(for:)`가 실제 프롬프트 본문이며, chunkType, 4L 차원, summary, dimensionSummaries, evidence, confidence 등을 JSON으로 뽑도록 요구한다.
  - 많은 few-shot 예시를 넣어서 liked, learned, lacked, longedFor가 과하게 뭉개지지 않도록 튜닝한다.
  - FM이 실패하면 휴리스틱 fallback 분석으로 보정한다.

- `Retrospective-Rulersalmon/Services/FollowUpQuestionGenerator.swift`
  - follow-up 질문 생성을 담당한다.
  - `instructions`는 FM이 어떤 follow-up angle을 고를지 정하는 지시문이다.
  - `questionPrompt(for:state:analysis:)`는 FM에 넘기는 실제 입력 프롬프트이며, 현재는 영어 메타데이터만 넣는다.
  - FM 출력은 질문 문장이 아니라 `angle` JSON만 받는다.
  - `parseQuestionPlan(from:)`가 FM 응답을 파싱하고, `renderKoreanQuestion(...)`이 최종 한국어 질문을 만든다.
  - FM 실패 시에는 `fallbackQuestion(...)`이 한국어 fallback 질문을 반환한다.

- `Retrospective-Rulersalmon/ViewModels/AssistantChatViewModel.swift`
  - 기본 채팅용 FM 경로다.
  - 별도 튜닝 instructions는 없고 `FoundationModelService()` 기본값을 사용한다.
  - 사용자의 텍스트를 그대로 `respond(to:)`에 전달한다.

- `Retrospective-Rulersalmon/ViewModels/ReflectionCallViewModel.swift`
  - FM 자체를 직접 튜닝하지는 않지만, 언제 어떤 context를 FM에 넘길지 결정한다.
  - turn end가 확정된 뒤 `FollowUpQuestionGenerator.generateQuestion(...)`을 호출한다.
  - 즉, FM 입력 품질과 호출 타이밍에 영향을 준다.

## 2. 현재 튜닝 포인트

- `instructions`
  - FM의 역할과 출력 형식을 정한다.
  - 분석용, 질문 생성용, 기본 chat용으로 각각 다르게 설정되어 있다.

- `prompt`
  - 실제 입력 텍스트다.
  - 분석기는 한국어 회고 원문과 예시를 포함한다.
  - 질문 생성기는 영어 상태 스냅샷을 넣고, FM은 angle만 고르게 한다.

- `few-shot examples`
  - `ReflectionChunkAnalyzer.swift` 안의 예시 블록이 핵심 튜닝 자산이다.
  - 어떤 문장을 liked, learned, lacked, longedFor로 나눌지 예시로 강하게 유도한다.

- `fallback rules`
  - FM 실패 시 무엇으로 대체할지 정한다.
  - 분석은 로컬 휴리스틱 fallback으로 내려가고, 질문은 한국어 로컬 렌더러로 내려간다.

## 3. 현재 데이터 흐름

- 회고 입력이 들어오면 `SpeechChunkBuffer`가 chunk를 안정화한다.
- `ReflectionChunkAnalyzer`가 FM 우선으로 chunk를 분석한다.
- `ReflectionStateTracker`가 4L 상태와 confidence, fidelity를 갱신한다.
- `FollowUpQuestionGenerator`가 turn end 이후 최신 상태를 보고 FM에 follow-up angle을 요청한다.
- FM 결과가 성공하면 한국어 질문으로 렌더링하고, 실패하면 한국어 fallback 질문으로 내려간다.

## 4. 현재 주의점

- 질문 생성 FM은 현재 영어 입력만 받도록 설계되어 있다.
- 최종 사용자 질문은 한국어로 렌더링된다.
- 분석 FM은 아직 한국어 회고 원문을 다루기 때문에, 지원 언어 이슈가 있으면 fallback으로 내려갈 수 있다.
- 콘솔 로그로 `session.respond invoked`, `session.respond succeeded`, `session.respond failed`를 확인하면 실제 호출 여부를 추적할 수 있다.

