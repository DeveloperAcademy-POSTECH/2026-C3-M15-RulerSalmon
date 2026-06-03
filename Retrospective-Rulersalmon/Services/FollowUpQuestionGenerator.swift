//
//  FollowUpQuestionGenerator.swift
//  Retrospective-Rulersalmon
//
//  Created by DevPaul on 5/31/26.
//

import Foundation

enum QuestionGenerationResult: Equatable {
    case none
    case followUp(dimension: ReflectionDimension, text: String)
    case closing(text: String)
}

final class FollowUpQuestionGenerator {
    private let foundationModelService: FoundationModelServicing

    private static let fallbackMarker = "Unable to prepare a model response."
    private static let plannerInstructions = """
    너는 한국어 회고 대화를 이어가는 질문 설계자다.
    현재 회고 상태와 관련 메모리를 참고해서 다음 한 문장을 정한다.
    출력은 반드시 JSON 하나만 한다.
    """

    init(foundationModelService: FoundationModelServicing? = nil) {
        self.foundationModelService = foundationModelService ?? FoundationModelService(instructions: Self.plannerInstructions)
    }

    func generateNextMessage(
        state: ReflectionState,
        analysis: ChunkAnalysis?,
        interventionDecision: InterventionDecision,
        retrievedContext: RetrievedReflectionContext? = nil
    ) async -> QuestionGenerationResult {
        if shouldClose(state: state) {
            if let fmResult = await foundationModelResult(
                state: state,
                analysis: analysis,
                interventionDecision: interventionDecision,
                mode: PlannerMode.closing,
                retrievedContext: retrievedContext
            ) {
                return fmResult
            }

            return .closing(text: fallbackClosingMessage())
        }

        guard interventionDecision.shouldIntervene,
              let target = interventionDecision.targetDimension else {
            return .none
        }

        if let fmResult = await foundationModelResult(
            state: state,
            analysis: analysis,
            interventionDecision: interventionDecision,
            mode: PlannerMode.followUp(target),
            retrievedContext: retrievedContext
        ) {
            return fmResult
        }

        return .followUp(
            dimension: target,
            text: fallbackQuestion(for: target, state: state, analysis: analysis)
        )
    }

    private func foundationModelResult(
        state: ReflectionState,
        analysis: ChunkAnalysis?,
        interventionDecision: InterventionDecision,
        mode: PlannerMode,
        retrievedContext: RetrievedReflectionContext?
    ) async -> QuestionGenerationResult? {
        do {
            let response = try await foundationModelService.respond(
                to: plannerPrompt(
                    state: state,
                    analysis: analysis,
                    interventionDecision: interventionDecision,
                    mode: mode,
                    retrievedContext: retrievedContext
                )
            )

            guard !response.contains(Self.fallbackMarker),
                  let plan = parsePlan(from: response) else {
                return nil
            }

            switch plan.action {
            case "close":
                return .closing(text: renderClosingMessage(plan: plan))

            case "follow_up":
                let dimension = ReflectionDimension(rawValue: plan.dimension ?? "") ?? mode.defaultDimension
                return .followUp(
                    dimension: dimension,
                    text: renderFollowUpQuestion(plan: plan, dimension: dimension, state: state, analysis: analysis)
                )

            default:
                return nil
            }
        } catch {
            return nil
        }
    }

    private func plannerPrompt(
        state: ReflectionState,
        analysis: ChunkAnalysis?,
        interventionDecision: InterventionDecision,
        mode: PlannerMode,
        retrievedContext: RetrievedReflectionContext?
    ) -> String {
        let liked = slotLine(for: .liked, slot: state.liked)
        let learned = slotLine(for: .learned, slot: state.learned)
        let lacked = slotLine(for: .lacked, slot: state.lacked)
        let longedFor = slotLine(for: .longedFor, slot: state.longedFor)
        let target = interventionDecision.targetDimension?.rawValue ?? "none"
        let urgency = String(format: "%.2f", interventionDecision.urgency)
        let recentSignals = recentSignals(from: analysis)
        let modeLine = mode.promptLine
        let askedQuestions = recentQuestions(from: state)
        let retrievedMemory = retrievedContext?.koreanPromptBlock() ?? "없음"

        return """
        너는 회고 대화를 이어가는 코치다.
        아래 상태와 관련 메모리를 보고 다음 한 문장을 정해라.

        규칙:
        - 최종 사용자 메시지는 반드시 한국어 반말 한 문장이다.
        - 존댓말, 안내문 톤, 평가하는 말투를 쓰지 마라.
        - 질문은 한 번에 하나만 한다.
        - 문장은 짧고 자연스럽게 유지하되, 너무 얕거나 뻔하면 안 된다.
        - 사용자의 마지막 회고에 가장 가까운 맥락에서 이어지는 질문이어야 한다.
        - 관련 메모리는 같은 세션 안에서 이미 나온 맥락을 다시 연결할 때만 써라.
        - 관련 메모리를 새로운 주제로 확장하는 근거로 쓰지 마라.
        - 관련 메모리와 최신 회고가 충돌하면 최신 회고를 우선한다.
        - 표면 요약 반복보다 이유, 기준, 막힌 지점, 감정의 배경, 다음 시도를 한 단계 더 묻는 게 좋다.
        - 사용자가 고민, 판단, 기준, 최적화, 개선, 막힘을 말했으면 그 구체적인 지점을 먼저 파고들어라.
        - 4L, 점수, 부족한 항목, 평가 기준 같은 내부 판단을 직접 언급하지 마라.
        - 이 프롬프트의 문장을 베끼지 마라.

        출력은 반드시 JSON 하나만 한다. 스키마는 아래와 같다.
        {
          "action": "follow_up" | "close",
          "dimension": "liked" | "learned" | "lacked" | "longedFor" | null,
          "intent": "best_part" | "lesson" | "blocker" | "next_step" | "wrap_up",
          "message": "final Korean message"
        }

        의도 가이드:
        - liked: 무엇이 잘 됐는지, 왜 의미 있었는지, 무엇이 좋았는지
        - learned: 무엇을 새로 알게 됐는지, 어떤 기준이 생겼는지
        - lacked: 어디서 막혔는지, 무엇이 부족했는지, 왜 어려웠는지
        - longedFor: 다음에는 무엇을 바꾸고 싶은지, 어떤 시도를 해보고 싶은지

        모드:
        \(modeLine)

        현재 회고 상태:
        \(liked)
        \(learned)
        \(lacked)
        \(longedFor)

        질문 판단 힌트:
        - 현재 대상 차원: \(target)
        - 긴급도: \(urgency)
        - 판단 이유: \(interventionDecision.reason)
        - 지금까지 한 질문 수: \(state.askedQuestions.count)
        - 최근 질문: \(askedQuestions)
        - 최신 사용자 회고 힌트: \(latestChunkHint(state: state, analysis: analysis))

        최신 분석 신호:
        \(recentSignals)

        같은 세션의 관련 회고 메모리:
        \(retrievedMemory)
        """
    }

    private func slotLine(for dimension: ReflectionDimension, slot: ReflectionSlot) -> String {
        let summary = koreanSignalLabel(for: slot.summary)
        let evidenceCount = slot.evidence.count
        let confidence = String(format: "%.2f", slot.confidence)
        let fidelity = String(format: "%.2f", slot.fidelity)
        let gap = String(format: "%.2f", max(0, 1 - max(slot.confidence, slot.fidelity)))

        return "- \(dimension.description): 충족=\(slot.isSatisfied), confidence=\(confidence), fidelity=\(fidelity), gap=\(gap), evidence 수=\(evidenceCount), 요약 힌트=\(summary)"
    }

    private func recentSignals(from analysis: ChunkAnalysis?) -> String {
        guard let analysis else {
            return "- 없음"
        }

        let dimensions = analysis.detectedDimensions.map(\.description).joined(separator: ", ")
        let keywords = analysis.keywords.prefix(3).joined(separator: ", ")
        let summary = koreanSignalLabel(for: analysis.summary)
        let primary = analysis.primaryDimension?.description ?? "없음"

        return """
        - 중심 차원: \(primary)
        - 감지 차원: \(dimensions.isEmpty ? "없음" : dimensions)
        - 키워드: \(keywords.isEmpty ? "없음" : keywords)
        - 요약 힌트: \(summary)
        """
    }

    private func recentQuestions(from state: ReflectionState) -> String {
        let recent = state.askedQuestions.suffix(3)
        guard !recent.isEmpty else { return "없음" }
        return recent.joined(separator: " / ")
    }

    private func latestChunkHint(state: ReflectionState, analysis: ChunkAnalysis?) -> String {
        let source = analysis?.cleanedText ?? state.lastUserChunk ?? ""
        let trimmed = source.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "없음" }

        if trimmed.contains("고민") || trimmed.contains("판단") || trimmed.contains("기준") {
            return "판단 기준 관련 고민"
        }
        if trimmed.contains("최적화") || trimmed.contains("개선") || trimmed.contains("UX") || trimmed.contains("ux") {
            return "개선 또는 최적화 고민"
        }
        if trimmed.contains("어렵") || trimmed.contains("막") || trimmed.contains("부족") {
            return "어려움 또는 부족 신호"
        }
        if trimmed.contains("배") || trimmed.contains("알게") || trimmed.contains("이해") {
            return "배움 신호"
        }

        return "일반 회고 신호"
    }

    private func parsePlan(from response: String) -> QuestionPlan? {
        let cleaned = response.trimmingCharacters(in: .whitespacesAndNewlines)

        if let data = cleaned.data(using: .utf8),
           let plan = try? JSONDecoder().decode(QuestionPlan.self, from: data) {
            return plan
        }

        guard let start = cleaned.firstIndex(of: "{"),
              let end = cleaned.lastIndex(of: "}") else {
            return nil
        }

        let snippet = String(cleaned[start...end])
        guard let data = snippet.data(using: .utf8) else {
            return nil
        }

        return try? JSONDecoder().decode(QuestionPlan.self, from: data)
    }

    private func renderFollowUpQuestion(
        plan: QuestionPlan,
        dimension: ReflectionDimension,
        state: ReflectionState,
        analysis: ChunkAnalysis?
    ) -> String {
        let trimmed = normalizeQuestion(plan.message)
        if isUsableKoreanMessage(trimmed),
           !looksPromptCopied(trimmed),
           !containsHonorificTone(trimmed),
           !containsMultipleQuestions(trimmed),
           !containsAwkwardPhrasing(trimmed) {
            return trimmed
        }

        return fallbackQuestion(for: dimension, state: state, analysis: analysis)
    }

    private func renderClosingMessage(plan: QuestionPlan) -> String {
        let trimmed = normalizeQuestion(plan.message)
        if isUsableKoreanMessage(trimmed),
           !looksPromptCopied(trimmed),
           !containsHonorificTone(trimmed),
           !containsAwkwardPhrasing(trimmed) {
            return trimmed
        }

        return fallbackClosingMessage()
    }

    private func normalizeQuestion(_ text: String) -> String {
        var trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.hasPrefix("\""), trimmed.hasSuffix("\""), trimmed.count >= 2 {
            trimmed.removeFirst()
            trimmed.removeLast()
        }

        return trimmed
    }

    private func isUsableKoreanMessage(_ text: String) -> Bool {
        guard !text.isEmpty else { return false }
        return text.contains { scalar in
            ("가"..."힣").contains(String(scalar))
        }
    }

    private func looksPromptCopied(_ text: String) -> Bool {
        let bannedFragments = [
            "무엇이 가장 어려웠는지",
            "어떤 기준에 따라 판단했는지",
            "어디서 막혔는지",
            "좀 더 자세히 이야기해 보는게 좋을 것 같아",
            "다음 단계에서는",
            "예를 들어"
        ]

        return bannedFragments.contains { text.contains($0) }
    }

    private func containsHonorificTone(_ text: String) -> Bool {
        let bannedFragments = [
            "해요",
            "했어요",
            "있어요",
            "좋아요",
            "볼까요",
            "할까요",
            "줄래요",
            "주세요",
            "좋을 것 같아요",
            "해보실래요",
            "있을까요"
        ]

        return bannedFragments.contains { text.contains($0) }
    }

    private func containsMultipleQuestions(_ text: String) -> Bool {
        let questionMarkCount = text.filter { $0 == "?" }.count
        if questionMarkCount > 1 {
            return true
        }

        let sentenceBreaks = CharacterSet(charactersIn: ".!?")
        let parts = text
            .components(separatedBy: sentenceBreaks)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        return parts.count > 1
    }

    private func containsAwkwardPhrasing(_ text: String) -> Bool {
        let bannedFragments = [
            "어떻게 하면",
            "개선할 수 있을 거야",
            "설명해줄 수 있을까",
            "말해줄 수 있을까",
            "어떻게 개선할 수 있을 거야"
        ]

        return bannedFragments.contains { text.contains($0) }
    }

    private func shouldClose(state: ReflectionState) -> Bool {
        let slots = [state.liked, state.learned, state.lacked, state.longedFor]
        let satisfiedCount = slots.filter(\.isSatisfied).count
        let averageFidelity = slots.map(\.fidelity).reduce(0, +) / Double(slots.count)
        let averageConfidence = slots.map(\.confidence).reduce(0, +) / Double(slots.count)

        return satisfiedCount == slots.count || (satisfiedCount >= 3 && averageFidelity >= 0.72 && averageConfidence >= 0.70)
    }

    private func fallbackQuestion(
        for dimension: ReflectionDimension,
        state: ReflectionState,
        analysis: ChunkAnalysis?
    ) -> String {
        let context = QuestionContext(state: state, analysis: analysis)
        let focus = context.focusPhrase(for: dimension)

        switch dimension {
        case .liked:
            if let focus {
                return "\(focus) 쪽에서 특히 괜찮았던 건 뭐였어?"
            }
            return "이번 경험에서 뭐가 제일 좋았어?"

        case .learned:
            if let focus {
                return "\(focus)를 지나면서 새로 보인 게 있었어?"
            }
            return "이번 경험을 하면서 새로 알게 된 게 있어?"

        case .lacked:
            if let focus {
                return "\(focus) 쪽은 왜 그렇게 고민이 길어졌어?"
            }
            return "이번에는 어느 지점에서 제일 많이 막혔어?"

        case .longedFor:
            if let focus {
                return "다음엔 \(focus) 쪽을 어떻게 바꿔보고 싶어?"
            }
            return "다음엔 어떤 식으로 바꿔보고 싶어?"
        }
    }

    private func fallbackClosingMessage() -> String {
        "좋아, 지금 회고는 꽤 잘 정리됐어. 여기서 천천히 마무리해도 되겠다."
    }

    private func koreanSignalLabel(for text: String?) -> String {
        guard let text = text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !text.isEmpty else {
            return "없음"
        }

        if text.contains("좋") || text.contains("만족") || text.contains("뿌듯") {
            return "긍정 결과"
        }
        if text.contains("배") || text.contains("알게") || text.contains("이해") {
            return "배움 신호"
        }
        if text.contains("부족") || text.contains("어려") || text.contains("막") {
            return "어려움 신호"
        }
        if text.contains("다음") || text.contains("바꾸") || text.contains("개선") {
            return "다음 변화 신호"
        }

        return "회고 신호"
    }
}

struct ReflectionMemoryEntry: Identifiable, Equatable {
    let id: UUID
    let text: String
    let summary: String
    let dimensionHints: [ReflectionDimension]
    let keywords: [String]
    let evidence: [String]
    let createdAt: Date

    init(
        id: UUID = UUID(),
        text: String,
        summary: String,
        dimensionHints: [ReflectionDimension],
        keywords: [String],
        evidence: [String],
        createdAt: Date
    ) {
        self.id = id
        self.text = text
        self.summary = summary
        self.dimensionHints = dimensionHints
        self.keywords = keywords
        self.evidence = evidence
        self.createdAt = createdAt
    }
}

struct RetrievedReflectionContext: Equatable {
    let entries: [ReflectionMemoryEntry]

    var isEmpty: Bool {
        entries.isEmpty
    }

    func koreanPromptBlock() -> String {
        guard !entries.isEmpty else { return "없음" }

        return entries.enumerated().map { index, entry in
            let dimensions = entry.dimensionHints.map(\.description).joined(separator: ", ")
            let keywords = entry.keywords.prefix(3).joined(separator: ", ")
            let evidence = entry.evidence.prefix(2).joined(separator: " / ")

            return """
            \(index + 1). 요약: \(entry.summary)
               원문: \(entry.text)
               차원: \(dimensions.isEmpty ? "없음" : dimensions)
               키워드: \(keywords.isEmpty ? "없음" : keywords)
               근거: \(evidence.isEmpty ? "없음" : evidence)
            """
        }
        .joined(separator: "\n")
    }
}

private extension FollowUpQuestionGenerator {
    enum PlannerMode {
        case followUp(ReflectionDimension)
        case closing

        var promptLine: String {
            switch self {
            case .followUp(let dimension):
                return "Prefer action=follow_up and stay aligned with target dimension \(dimension.rawValue)."
            case .closing:
                return "Prefer action=close because the reflection is likely complete."
            }
        }

        var defaultDimension: ReflectionDimension {
            switch self {
            case .followUp(let dimension):
                return dimension
            case .closing:
                return .liked
            }
        }
    }

    struct QuestionPlan: Codable {
        let action: String
        let dimension: String?
        let intent: String?
        let message: String
    }

    struct QuestionContext {
        let state: ReflectionState
        let analysis: ChunkAnalysis?

        func focusPhrase(for dimension: ReflectionDimension) -> String? {
            let slot = slot(for: dimension)

            if let summary = slot.summary?.trimmingCharacters(in: .whitespacesAndNewlines),
               !summary.isEmpty {
                return clipped(summary)
            }

            if let evidence = slot.evidence.first(where: { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) {
                return clipped(evidence)
            }

            if let summary = analysis?.dimensionSummaries[dimension.rawValue]?.trimmingCharacters(in: .whitespacesAndNewlines),
               !summary.isEmpty {
                return clipped(summary)
            }

            if let topic = state.currentTopic?.trimmingCharacters(in: .whitespacesAndNewlines),
               !topic.isEmpty {
                return clipped(topic)
            }

            return nil
        }

        private func slot(for dimension: ReflectionDimension) -> ReflectionSlot {
            switch dimension {
            case .liked:
                return state.liked
            case .learned:
                return state.learned
            case .lacked:
                return state.lacked
            case .longedFor:
                return state.longedFor
            }
        }

        private func clipped(_ text: String) -> String {
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.count <= 22 {
                return trimmed
            }

            let index = trimmed.index(trimmed.startIndex, offsetBy: 22)
            return String(trimmed[..<index])
        }
    }
}
