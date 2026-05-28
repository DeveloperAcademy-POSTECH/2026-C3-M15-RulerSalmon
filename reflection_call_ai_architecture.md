# STT-TTS 기반 4L 회고 통화 UX 설계

## 1. 목표

사용자가 회고를 말로 하면, 앱은 실시간으로 사용자의 발화를 분석하고 4L 회고 기준에 맞게 충분히 말하고 있는지 판단한다. 부족한 항목이 있으면 AI가 자연스럽게 질문을 던져 사용자가 더 깊이 회고할 수 있도록 유도한다.

최종 UX는 사용자가 AI와 통화하듯이 대화하는 형태다.

핵심 목표는 다음과 같다.

- 사용자가 말하는 동안 실시간으로 회고 상태를 파악한다.
- 4L 회고의 각 항목이 충분히 채워졌는지 추적한다.
- 부족한 항목이 있으면 자연스럽게 질문한다.
- 응답 지연을 최소화해서 친구와 통화하는 듯한 느낌을 만든다.
- Foundation Model 호출을 최소화하고, 가능한 처리는 앱 내부 로직으로 수행한다.

---

## 2. 핵심 결론

단순한 구조는 다음과 같다.

```text
STT → 전체 텍스트 → Foundation Model → 질문 생성
```

하지만 이 방식은 실시간 통화 UX에는 적합하지 않다.

문제점은 다음과 같다.

- 전체 발화가 끝날 때까지 기다려야 한다.
- Foundation Model 호출이 무겁다.
- 사용자가 말하는 도중에 자연스럽게 개입하기 어렵다.
- 질문 타이밍이 늦거나 부자연스러울 수 있다.

따라서 추천 구조는 다음과 같다.

```text
STT partial result
↓
Utterance Buffer
↓
Chunk Detector
↓
Chunk Pre-Processor
↓
4L State Tracker
↓
Intervention Decider
↓
Question Generator
↓
TTS
```

핵심은 사용자의 발화를 작은 의미 단위인 chunk로 나누고, 각 chunk를 빠르게 분석해 4L 상태를 누적하는 것이다.

---

## 3. Streaming 응답과 일반 응답의 차이

### 일반 응답

일반 응답은 모델이 답변을 전부 만든 뒤에 한 번에 결과를 반환하는 방식이다.

```swift
let answer = try await model.respond(to: prompt)
textView.text = answer
```

사용자 입장에서는 답변이 완성될 때까지 아무 변화가 없다.

### Streaming 응답

Streaming 응답은 모델이 생성하는 결과를 조각조각 받아 화면에 바로 보여주는 방식이다.

```swift
for try await partial in model.streamResponse(to: prompt) {
    textView.text += partial
}
```

모델의 전체 생성 시간이 크게 줄어드는 것은 아니지만, 첫 반응까지의 시간이 짧아져 사용자는 앱이 더 빠르게 반응한다고 느낀다.

통화형 회고 UX에서는 다음과 같이 나누는 것이 좋다.

| 용도 | 추천 방식 |
|---|---|
| 짧은 분류, 감정 태그, 4L 슬롯 판단 | 일반 응답 또는 structured output |
| 사용자에게 보여주는 긴 답변, 최종 회고문 | Streaming 응답 |
| 통화 중 짧은 질문 | 일반 응답 또는 템플릿 기반 생성 |

---

## 4. 4L 회고 상태 모델

4L 회고는 다음 네 가지 항목으로 볼 수 있다.

```text
Liked      좋았던 점
Learned    배운 점
Lacked     부족했던 점
Longed for 바라는 점 / 다음에 원하는 점
```

앱은 대화 중 이 네 가지 항목이 얼마나 채워졌는지를 계속 추적해야 한다.

예시 Swift 모델:

```swift
enum ReflectionDimension: String, Codable {
    case liked
    case learned
    case lacked
    case longedFor
}

struct ReflectionSlot: Codable {
    var evidence: [String]
    var summary: String?
    var confidence: Double
    var isSatisfied: Bool
}

struct ReflectionState: Codable {
    var liked: ReflectionSlot
    var learned: ReflectionSlot
    var lacked: ReflectionSlot
    var longedFor: ReflectionSlot

    var lastUserChunk: String?
    var askedQuestions: [String]
    var currentTopic: String?
}
```

예를 들어 사용자가 다음과 같이 말한 경우:

```text
오늘 팀 미팅에서 생각보다 의견이 잘 받아들여져서 기분이 좋았어.
```

앱 내부 상태는 다음처럼 갱신될 수 있다.

```json
{
  "liked": {
    "evidence": ["팀 미팅에서 의견이 잘 받아들여져서 기분이 좋았음"],
    "summary": "팀 미팅에서 인정받은 느낌이 긍정적 경험이었다.",
    "confidence": 0.9,
    "isSatisfied": true
  }
}
```

---

## 5. Chunking 전략

STT partial result는 계속 바뀐다.

예를 들면 다음과 같다.

```text
오늘은
오늘은 팀 미팅이
오늘은 팀 미팅이 생각보다
오늘은 팀 미팅이 생각보다 괜찮았고
오늘은 팀 미팅이 생각보다 괜찮았고 내가 말한 의견이
오늘은 팀 미팅이 생각보다 괜찮았고 내가 말한 의견이 잘 받아들여졌어
```

이 partial result마다 Foundation Model을 호출하면 안 된다.

대신 사용자가 하나의 의미 있는 발화를 끝냈다고 판단될 때 chunk를 확정한다.

### 추천 chunk 확정 기준

다음 기준을 조합한다.

```text
1. 침묵 800ms ~ 1500ms
2. 문장 종결 표현 감지
3. 텍스트 길이 기준
4. 의미 전환 표현 감지
5. STT partial 안정화 여부
```

한국어에서는 마침표보다 문장 종결 표현이 중요하다.

예시 종결 표현:

```text
했어
했어요
같아
같아요
느꼈어
느꼈어요
좋았어
아쉬웠어
힘들었어
하고 싶어
해야겠어
것 같아
```

주제 전환 표현도 chunk 분리에 활용할 수 있다.

```text
근데
그리고
또
반면에
아무튼
다음에는
그래서
결국
한편으로는
```

### 추천 초기값

```text
최소 chunk 길이: 20~30자
최대 chunk 길이: 120~180자
침묵 기준: 1.0~1.5초
질문 후 다음 질문까지 최소 간격: 8~12초
연속 AI 발화 제한: 최대 1회
AI 질문 길이: 20~50자
```

---

## 6. Chunk 타입

모든 chunk를 같은 방식으로 처리하지 말고, 먼저 의미 타입을 나누면 안정적이다.

```swift
enum ChunkType: String, Codable {
    case event        // 있었던 일
    case emotion      // 감정
    case insight      // 배운 점
    case problem      // 아쉬움/부족함
    case desire       // 바람/다음 액션
    case filler       // 의미 없는 말
    case unknown
}

struct SpeechChunk: Codable, Identifiable {
    let id: UUID
    let rawText: String
    let cleanedText: String
    let startedAt: Date
    let endedAt: Date
    let type: ChunkType
}
```

예시:

```text
“오늘 회의에서 내가 준비한 내용을 발표했어”
→ event

“생각보다 반응이 좋아서 뿌듯했어”
→ emotion / liked

“내가 준비를 좀 더 하면 말이 덜 꼬인다는 걸 배웠어”
→ insight / learned

“근데 질문을 받았을 때 바로 답을 못한 건 아쉬웠어”
→ problem / lacked

“다음에는 예상 질문을 미리 정리해보고 싶어”
→ desire / longedFor
```

---

## 7. Pre-Processing의 목적

Pre-processing의 목적은 문장을 예쁘게 만드는 것이 아니라, 실시간 분석이 쉬운 형태로 정리하는 것이다.

각 chunk에서 최소한 다음 정보를 뽑는다.

```swift
struct ChunkAnalysis: Codable {
    let originalText: String
    let cleanedText: String
    let summary: String
    let detectedDimensions: [ReflectionDimension]
    let emotions: [String]
    let evidence: [String]
    let missingFollowUpHints: [ReflectionDimension]
    let confidence: Double
}
```

예시 입력:

```text
음 오늘 미팅은 생각보다 괜찮았고, 내가 말한 의견을 팀에서 받아줘서 좀 뿌듯했어.
```

예시 분석 결과:

```json
{
  "cleanedText": "오늘 미팅은 생각보다 괜찮았고, 내가 말한 의견을 팀에서 받아줘서 뿌듯했다.",
  "summary": "팀 미팅에서 의견이 받아들여져 긍정적인 감정을 느낌.",
  "detectedDimensions": ["liked"],
  "emotions": ["뿌듯함", "안도감"],
  "evidence": ["의견을 팀에서 받아줌", "뿌듯했음"],
  "missingFollowUpHints": ["learned", "lacked", "longedFor"],
  "confidence": 0.86
}
```

chunk 하나가 반드시 하나의 4L 항목에만 해당하는 것은 아니다.

예를 들어:

```text
질문에 바로 답을 못해서 아쉬웠는데, 다음에는 예상 질문을 준비해야겠다고 생각했어.
```

이 경우 다음 두 항목에 동시에 해당한다.

```text
Lacked: 질문에 바로 답하지 못함
Longed for: 다음에는 예상 질문을 준비하고 싶음
```

---

## 8. Foundation Model 역할 분리

Foundation Model을 하나의 만능 처리기로 쓰면 느려질 수 있다.

역할을 세 가지로 나누는 것이 좋다.

### 8.1 Fast Classifier

짧은 chunk를 보고 4L 어디에 해당하는지 판단한다.

```text
입력: chunk 하나
출력: JSON
빈도: 자주 호출됨
목표: 빠른 분류와 요약
```

예시 prompt:

```text
다음 사용자의 회고 발화를 4L 기준으로 분류해.
해당하는 항목만 골라.
출력은 JSON만.

4L:
- liked: 좋았던 점
- learned: 배운 점
- lacked: 부족했던 점
- longedFor: 바라는 점, 다음에 하고 싶은 점

발화:
"{chunk}"
```

예시 출력:

```json
{
  "dimensions": ["liked"],
  "summary": "팀에서 의견이 받아들여져 뿌듯함을 느낌",
  "emotions": ["뿌듯함"],
  "confidence": 0.88
}
```

### 8.2 State Updater

현재까지의 회고 상태와 새 분석 결과를 합친다.

이 부분은 가능하면 Foundation Model이 아니라 앱 코드로 처리한다.

```swift
func updateState(
    state: ReflectionState,
    analysis: ChunkAnalysis
) -> ReflectionState {
    var newState = state

    for dimension in analysis.detectedDimensions {
        switch dimension {
        case .liked:
            newState.liked.evidence.append(contentsOf: analysis.evidence)
            newState.liked.summary = analysis.summary
            newState.liked.confidence = max(newState.liked.confidence, analysis.confidence)
            newState.liked.isSatisfied = newState.liked.confidence > 0.7

        case .learned:
            newState.learned.evidence.append(contentsOf: analysis.evidence)
            newState.learned.summary = analysis.summary
            newState.learned.confidence = max(newState.learned.confidence, analysis.confidence)
            newState.learned.isSatisfied = newState.learned.confidence > 0.7

        case .lacked:
            newState.lacked.evidence.append(contentsOf: analysis.evidence)
            newState.lacked.summary = analysis.summary
            newState.lacked.confidence = max(newState.lacked.confidence, analysis.confidence)
            newState.lacked.isSatisfied = newState.lacked.confidence > 0.7

        case .longedFor:
            newState.longedFor.evidence.append(contentsOf: analysis.evidence)
            newState.longedFor.summary = analysis.summary
            newState.longedFor.confidence = max(newState.longedFor.confidence, analysis.confidence)
            newState.longedFor.isSatisfied = newState.longedFor.confidence > 0.7
        }
    }

    newState.lastUserChunk = analysis.originalText
    return newState
}
```

### 8.3 Question Generator

질문 생성은 매 chunk마다 하면 안 된다.

다음 조건을 만족할 때만 질문을 생성한다.

```text
- 사용자가 1.5초 이상 멈춤
- 최근 chunk 분석이 끝남
- 아직 부족한 4L 항목이 있음
- 직전에 AI가 질문한 지 충분히 시간이 지남
- 사용자의 감정 흐름을 끊지 않음
```

예시 prompt:

```text
너는 친구처럼 자연스럽게 회고를 도와주는 통화 상대야.

현재 회고 상태:
- 좋았던 점: 충분함
- 배운 점: 부족함
- 부족했던 점: 부족함
- 바라는 점: 없음

사용자가 마지막으로 한 말:
"오늘 팀 미팅에서 의견이 잘 받아들여져서 뿌듯했어."

목표:
사용자가 자연스럽게 "배운 점"을 말하도록 유도해.

규칙:
- 한 문장만 말해.
- 질문은 부담스럽지 않게.
- 면접관처럼 묻지 마.
- 20자~45자 사이.
```

예시 출력:

```text
오 좋다. 그 경험에서 배운 것도 있었어?
```

---

## 9. AI 개입 타이밍

통화 UX에서는 질문 품질만큼 타이밍이 중요하다.

### AI가 끼어들면 안 되는 상황

```text
사용자가 아직 말하고 있음
STT partial이 계속 바뀌고 있음
방금 감정적인 이야기를 시작함
사용자가 생각을 정리하는 중임
AI가 방금 질문했음
```

### AI가 끼어들기 좋은 상황

```text
사용자가 1.2~2.0초 이상 멈춤
하나의 사건 설명이 끝남
4L 중 특정 항목이 비어 있음
사용자가 “음...”, “뭐였지...”처럼 막힘
사용자가 “그게 다야” 같은 종료 신호를 줌
```

예시 decision layer:

```swift
struct InterventionDecision {
    let shouldIntervene: Bool
    let targetDimension: ReflectionDimension?
    let reason: String
    let urgency: Double
}

final class InterventionDecider {
    func decide(
        state: ReflectionState,
        silenceDuration: TimeInterval,
        timeSinceLastAIQuestion: TimeInterval,
        isUserSpeaking: Bool
    ) -> InterventionDecision {
        guard !isUserSpeaking else {
            return .init(
                shouldIntervene: false,
                targetDimension: nil,
                reason: "User is still speaking",
                urgency: 0
            )
        }

        guard silenceDuration > 1.2 else {
            return .init(
                shouldIntervene: false,
                targetDimension: nil,
                reason: "Silence too short",
                urgency: 0
            )
        }

        guard timeSinceLastAIQuestion > 8 else {
            return .init(
                shouldIntervene: false,
                targetDimension: nil,
                reason: "Asked too recently",
                urgency: 0
            )
        }

        if !state.learned.isSatisfied {
            return .init(
                shouldIntervene: true,
                targetDimension: .learned,
                reason: "Learned is missing",
                urgency: 0.7
            )
        }

        if !state.lacked.isSatisfied {
            return .init(
                shouldIntervene: true,
                targetDimension: .lacked,
                reason: "Lacked is missing",
                urgency: 0.6
            )
        }

        if !state.longedFor.isSatisfied {
            return .init(
                shouldIntervene: true,
                targetDimension: .longedFor,
                reason: "Longed for is missing",
                urgency: 0.6
            )
        }

        return .init(
            shouldIntervene: false,
            targetDimension: nil,
            reason: "Reflection is sufficiently covered",
            urgency: 0
        )
    }
}
```

---

## 10. 자연스러운 통화를 위한 AI 발화 타입

AI가 항상 질문만 하면 심문처럼 느껴진다.

따라서 AI 발화를 네 가지 타입으로 나누는 것이 좋다.

```swift
enum AIInterventionType {
    case backchannel    // 맞장구
    case reflection     // 사용자의 말 짧게 반영
    case followUp       // 질문
    case transition     // 다음 4L로 자연스럽게 이동
}
```

### Backchannel

```text
음, 그랬구나.
오, 그건 꽤 뿌듯했겠다.
아 그 상황은 좀 부담됐겠다.
```

### Reflection

```text
네가 준비한 게 인정받은 느낌이었구나.
질문을 받았을 때 살짝 당황했던 게 남아있네.
```

### Follow-up

```text
그 경험에서 배운 것도 있었어?
다음엔 어떻게 해보고 싶어?
```

### Transition

```text
좋았던 점은 잘 들렸어. 그럼 아쉬웠던 쪽도 조금 떠오르는 게 있어?
```

좋은 대화 예시:

```text
사용자: 오늘 미팅에서 내 의견이 잘 받아들여져서 좋았어.
AI: 오, 그건 꽤 뿌듯했겠다. 그 경험에서 배운 것도 있었어?

사용자: 음... 내가 생각보다 준비를 잘 했던 것 같아.
AI: 준비가 자신감으로 이어졌던 거네. 혹시 아쉬웠던 부분도 있었어?
```

---

## 11. 질문 생성 최적화

질문을 매번 Foundation Model로 생성하면 지연이 생길 수 있다.

초기 버전에서는 템플릿 기반 질문을 준비하고, Foundation Model은 후보 중 가장 자연스러운 것을 고르는 역할만 하게 하는 것이 좋다.

예시 템플릿:

```swift
let learnedQuestions = [
    "그 경험에서 배운 것도 있었어?",
    "돌아보면 뭔가 깨달은 게 있어?",
    "다음엔 다르게 해보고 싶은 부분이 보여?"
]

let lackedQuestions = [
    "아쉬웠던 부분도 있었어?",
    "조금 부족했다고 느낀 건 뭐였어?",
    "마음에 걸리는 장면이 있었어?"
]

let longedForQuestions = [
    "다음엔 어떻게 해보고 싶어?",
    "앞으로 바라는 방향은 있어?",
    "비슷한 일이 오면 어떻게 해보고 싶어?"
]
```

Foundation Model에는 다음처럼 요청할 수 있다.

```text
다음 후보 중 현재 대화에 가장 자연스러운 질문 하나를 골라.

사용자 마지막 말:
"..."

후보:
1. 그 경험에서 배운 것도 있었어?
2. 아쉬웠던 부분도 있었어?
3. 다음엔 어떻게 해보고 싶어?
```

이 방식은 완전 생성보다 빠르고 예측 가능하다.

---

## 12. 실시간 처리 흐름

### 12.1 STT partial 수신

```swift
func handlePartialText(_ text: String) {
    utteranceBuffer.update(partialText: text)
}
```

여기서는 Foundation Model을 호출하지 않는다. partial result는 불안정하기 때문이다.

### 12.2 안정된 발화 감지

```swift
final class UtteranceBuffer {
    private var latestPartialText: String = ""
    private var lastStableText: String = ""
    private var lastUpdatedAt: Date = .now

    func update(partialText: String) {
        latestPartialText = partialText
        lastUpdatedAt = .now
    }

    func shouldCommitChunk(
        silenceDuration: TimeInterval
    ) -> Bool {
        guard latestPartialText.count > lastStableText.count else {
            return false
        }

        let newText = String(latestPartialText.dropFirst(lastStableText.count))
        let hasEnoughLength = newText.count >= 25
        let hasSentenceEnding = Self.hasKoreanSentenceEnding(newText)
        let hasEnoughSilence = silenceDuration > 1.0

        return hasEnoughSilence && (hasEnoughLength || hasSentenceEnding)
    }

    func commitChunk() -> String {
        let newText = String(latestPartialText.dropFirst(lastStableText.count))
        lastStableText = latestPartialText
        return newText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func hasKoreanSentenceEnding(_ text: String) -> Bool {
        let endings = [
            "했어", "했어요", "였어", "였어요",
            "좋았어", "좋았어요",
            "아쉬웠어", "아쉬웠어요",
            "힘들었어", "힘들었어요",
            "같아", "같아요",
            "싶어", "싶어요",
            "해야겠어", "해야겠어요"
        ]

        return endings.contains { text.hasSuffix($0) }
    }
}
```

### 12.3 Chunk 분석

```swift
func processCommittedChunk(_ rawChunk: String) async {
    let cleaned = cleanChunk(rawChunk)

    guard !isTrivial(cleaned) else {
        return
    }

    let analysis = await foundationModel.classifyChunk(cleaned)
    reflectionState = updateState(
        state: reflectionState,
        analysis: analysis
    )

    await maybeGenerateFollowUpQuestion()
}
```

### 12.4 질문 생성 여부 판단

```swift
func maybeGenerateFollowUpQuestion() async {
    let decision = interventionDecider.decide(
        state: reflectionState,
        silenceDuration: currentSilenceDuration,
        timeSinceLastAIQuestion: Date().timeIntervalSince(lastAIQuestionAt),
        isUserSpeaking: voiceActivityDetector.isSpeaking
    )

    guard decision.shouldIntervene,
          let target = decision.targetDimension
    else {
        return
    }

    let question = await foundationModel.generateFollowUpQuestion(
        state: reflectionState,
        target: target
    )

    lastAIQuestionAt = .now
    await ttsService.speak(question)
}
```

---

## 13. 추천 앱 아키텍처

```swift
final class ReflectionCallCoordinator {
    private let speechService: SpeechRecognitionService
    private let chunker: SpeechChunker
    private let analyzer: ReflectionChunkAnalyzer
    private let stateTracker: ReflectionStateTracker
    private let decider: InterventionDecider
    private let questionGenerator: FollowUpQuestionGenerator
    private let ttsService: TTSService

    private var state = ReflectionState.empty
    private var lastAIQuestionAt: Date = .distantPast

    func startCall() async throws {
        try await speechService.startRecording { [weak self] partialText in
            Task {
                await self?.handlePartialText(partialText)
            }
        }
    }

    @MainActor
    private func handlePartialText(_ partialText: String) async {
        chunker.update(partialText)

        if let chunk = chunker.commitIfNeeded() {
            await process(chunk)
        }
    }

    private func process(_ chunk: SpeechChunk) async {
        let analysis = await analyzer.analyze(chunk)
        state = stateTracker.apply(analysis, to: state)

        let decision = decider.decide(using: state)

        guard decision.shouldIntervene,
              let target = decision.targetDimension
        else {
            return
        }

        let question = await questionGenerator.generate(
            state: state,
            target: target
        )

        await ttsService.speak(question)
    }
}
```

---

## 14. Latency 최적화 전략

나쁜 구조:

```text
partial result 들어올 때마다
→ Foundation Model 분석
→ 질문 생성 여부 판단
→ 질문 생성
```

좋은 구조:

```text
partial result
→ 버퍼만 업데이트

chunk 확정
→ 짧은 분석 호출

침묵 감지 + 부족 항목 있음
→ 짧은 질문 생성 호출
```

Foundation Model 호출 빈도는 대략 다음 정도가 적절하다.

```text
사용자가 계속 말하는 중:
- 3~8초마다 chunk 분석 1회

사용자가 멈춤:
- 필요할 때 질문 생성 1회

전체 녹음 종료:
- 최종 회고문 생성 1회
```

통화 중 역할 분배:

```text
자주 호출:
- chunk 분류
- 감정/증거 추출

가끔 호출:
- 자연스러운 follow-up 질문 생성

마지막에 한 번:
- 최종 회고문 생성
```

---

## 15. 최종 회고 생성

통화 중에는 전체 회고문을 계속 만들 필요가 없다.

통화 중에는 4L 상태만 채우고, 사용자가 종료하면 최종 회고문을 생성한다.

```text
통화 중:
- chunk 분석
- 4L 상태 업데이트
- 짧은 질문 생성

통화 종료:
- 4L 상태 기반 최종 회고문 생성
```

최종 prompt는 전체 transcript보다 정리된 state를 넣는 것이 좋다.

```text
다음 4L 회고 상태를 바탕으로 자연스러운 회고문을 작성해.

Liked:
- 팀 미팅에서 의견이 받아들여져 뿌듯함

Learned:
- 준비를 충분히 하면 자신감 있게 말할 수 있음을 배움

Lacked:
- 예상 질문에 바로 답하지 못한 점이 아쉬움

Longed for:
- 다음 회의 전 예상 질문을 정리하고 싶음
```

이렇게 하면 최종 회고문 생성이 더 안정적이고 빠르다.

---

## 16. 구현 순서 추천

처음부터 모든 것을 Foundation Model 기반으로 만들기보다 다음 순서로 구현하는 것이 좋다.

```text
1. STT partial buffer 만들기
2. silence + 문장 끝 기준 chunker 만들기
3. chunk → 4L JSON classifier 만들기
4. ReflectionState 누적하기
5. 부족한 4L 찾기
6. 템플릿 기반 follow-up 질문부터 붙이기
7. 이후 Foundation Model로 질문을 더 자연스럽게 다듬기
8. 통화 종료 시 최종 회고문 생성하기
```

초기 버전에서는 질문 생성을 전부 Foundation Model에 맡기지 말고, 템플릿 + 상황 선택 방식으로 시작하는 것이 좋다.

그렇게 하면 빠르고 예측 가능하다. 이후 자연스러움이 부족한 부분만 Foundation Model로 다듬으면 된다.

---

## 17. 최종 요약

이 UX에서 chunking은 단순한 최적화가 아니라 대화 품질의 핵심 구조다.

가장 중요한 설계 원칙은 다음과 같다.

```text
사용자의 말을 실시간으로 전부 이해하려 하지 말고,
의미 있는 발화 단위로 잘라서,
4L 상태를 조금씩 채우고,
부족한 칸이 보일 때만 자연스럽게 물어본다.
```

추천 최종 구조:

```text
음성 입력
↓
STT partial result
↓
partial buffer
↓
silence / sentence ending 기반 chunk commit
↓
chunk pre-processing
↓
4L classifier
↓
ReflectionState update
↓
InterventionDecider
↓
템플릿 또는 Foundation Model 기반 follow-up 질문
↓
TTS
↓
통화 종료 후 최종 회고문 생성
```
