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
    You plan the next short but meaningful message for a Korean retrospective coach.
    Decide only one next action based on structured reflection state.
    Your job is not casual chit-chat.
    Your job is to help the user deepen the reflection one step further.
    Output JSON only.
    """

    init(foundationModelService: FoundationModelServicing? = nil) {
        self.foundationModelService = foundationModelService ?? FoundationModelService(instructions: Self.plannerInstructions)
    }

    func generateNextMessage(
        state: ReflectionState,
        analysis: ChunkAnalysis?,
        interventionDecision: InterventionDecision
    ) async -> QuestionGenerationResult {
        if shouldClose(state: state) {
            if let fmResult = await foundationModelResult(
                state: state,
                analysis: analysis,
                interventionDecision: interventionDecision,
                mode: .closing
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
            mode: .followUp(target)
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
        mode: PlannerMode
    ) async -> QuestionGenerationResult? {
        do {
            let response = try await foundationModelService.respond(
                to: plannerPrompt(
                    state: state,
                    analysis: analysis,
                    interventionDecision: interventionDecision,
                    mode: mode
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
        mode: PlannerMode
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

        return """
        Decide the next Korean coach message for a retrospective conversation.

        Rules:
        - The final user-facing message must be in Korean.
        - Use casual Korean speech only. Always speak in 반말.
        - Never use honorific or polite endings such as "요", "까요", "해요", "주세요", "있을까요", "좋을 것 같아요".
        - Keep it short: exactly one sentence.
        - Ask exactly one question only.
        - Never ask two questions in a row.
        - Never connect two separate prompts in one message.
        - Aim for roughly 18 to 42 Korean characters.
        - Sound warm, friendly, and lightly mentoring, like a close senior or thoughtful friend.
        - Do not simply paraphrase or repeat the user's wording.
        - Stay close to what the user actually said. Do not jump to a new topic unless the state strongly supports it.
        - Base the question on the strongest visible cue from the latest reflection, not on a generic coaching pattern.
        - Ask one level deeper: reason, turning point, decision criterion, tradeoff, emotion behind the event, blocker, or next concrete experiment.
        - Prefer specific questions over broad ones.
        - If the same dimension is still weak, continue digging into that dimension instead of jumping around.
        - A good follow-up should feel like a natural continuation of the user's last thought.
        - If action is follow_up, ask exactly one natural question.
        - If action is close, end the reflection naturally without sounding abrupt.
        - Avoid vague questions like "어땠어?", "왜 그랬어?" unless there is no better anchor.
        - Avoid sounding generic, shallow, or like a template.
        - If the user mentions 고민, 판단, 기준, 최적화, 개선, 막힘, 선택, trade-off, ask about the concrete point of difficulty or criterion first.
        - Do not introduce themes like goal-setting, feedback process, teamwork, schedule, or communication unless they are explicitly present in the reflection state.
        - Prefer concrete questions about difficulty, decision criteria, bottlenecks, meaning, or next action before broader coaching themes.
        - Never copy wording from this prompt.
        - Never quote or reuse list items from this prompt verbatim.
        - Write the question as if you inferred it freshly from the reflection, not from instructions.
        - Never mention 4L, reflection dimensions, weak slots, missing information, scores, confidence, fidelity, completeness, or evaluation.
        - Do not hint that you are checking a framework or rubric.
        - The user should feel invited to keep talking, not assessed.
        - Ask in a way that sounds curious and conversational, not diagnostic.

        Output JSON only with this schema:
        {
          "action": "follow_up" | "close",
          "dimension": "liked" | "learned" | "lacked" | "longedFor" | null,
          "intent": "best_part" | "lesson" | "blocker" | "next_step" | "wrap_up",
          "message": "final Korean message"
        }

        Intent guidance:
        - liked: ask what specifically worked, why it mattered, or what made it feel meaningful.
        - learned: ask what new insight, criterion, or realization emerged.
        - lacked: ask what blocked progress, what felt insufficient, or where the user struggled most.
        - longedFor: ask what they want to change next time, what experiment they want to try, or what better version they imagine.

        Mode:
        \(modeLine)

        Reflection state:
        \(liked)
        \(learned)
        \(lacked)
        \(longedFor)

        Decision hints:
        - target dimension: \(target)
        - urgency: \(urgency)
        - reason: \(interventionDecision.reason)
        - asked question count: \(state.askedQuestions.count)
        - recent asked questions: \(askedQuestions)
        - latest user chunk hint: \(latestChunkHint(state: state, analysis: analysis))

        Recent analysis signals:
        \(recentSignals)
        """
    }

    private func slotLine(for dimension: ReflectionDimension, slot: ReflectionSlot) -> String {
        let summary = englishLabel(for: slot.summary)
        let evidenceCount = slot.evidence.count
        let confidence = String(format: "%.2f", slot.confidence)
        let fidelity = String(format: "%.2f", slot.fidelity)
        let gap = String(format: "%.2f", max(0, 1 - max(slot.confidence, slot.fidelity)))

        return "- \(dimension.rawValue): satisfied=\(slot.isSatisfied), confidence=\(confidence), fidelity=\(fidelity), gap=\(gap), evidenceCount=\(evidenceCount), summaryHint=\(summary)"
    }

    private func recentSignals(from analysis: ChunkAnalysis?) -> String {
        guard let analysis else {
            return "- none"
        }

        let dimensions = analysis.detectedDimensions.map(\.rawValue).joined(separator: ", ")
        let keywords = analysis.keywords.prefix(3).map(englishLabel).joined(separator: ", ")
        let summary = englishLabel(for: analysis.summary)
        let primary = analysis.primaryDimension?.rawValue ?? "none"

        return """
        - primaryDimension: \(primary)
        - detectedDimensions: \(dimensions.isEmpty ? "none" : dimensions)
        - keywords: \(keywords.isEmpty ? "none" : keywords)
        - summaryHint: \(summary)
        """
    }

    private func recentQuestions(from state: ReflectionState) -> String {
        let recent = state.askedQuestions.suffix(3)
        guard !recent.isEmpty else { return "none" }
        return recent.map(englishLabel).joined(separator: ", ")
    }

    private func latestChunkHint(state: ReflectionState, analysis: ChunkAnalysis?) -> String {
        let source = analysis?.cleanedText ?? state.lastUserChunk ?? ""
        let trimmed = source.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "none" }

        if trimmed.contains("고민") || trimmed.contains("판단") || trimmed.contains("기준") {
            return "decision_or_criteria_concern"
        }
        if trimmed.contains("최적화") || trimmed.contains("개선") || trimmed.contains("UX") || trimmed.contains("ux") {
            return "improvement_or_optimization_concern"
        }
        if trimmed.contains("어렵") || trimmed.contains("막") || trimmed.contains("부족") {
            return "difficulty_or_lack_signal"
        }
        if trimmed.contains("배") || trimmed.contains("알게") || trimmed.contains("이해") {
            return "learning_signal"
        }

        return "general_reflection_signal"
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

    private func englishLabel(for text: String?) -> String {
        guard let text = text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !text.isEmpty else {
            return "none"
        }

        // Keep the payload locale-safe by avoiding the original Korean text.
        if text.contains("좋") || text.contains("만족") || text.contains("뿌듯") {
            return "positive_result"
        }
        if text.contains("배") || text.contains("알게") || text.contains("이해") {
            return "learning_signal"
        }
        if text.contains("부족") || text.contains("어려") || text.contains("막") {
            return "difficulty_signal"
        }
        if text.contains("다음") || text.contains("바꾸") || text.contains("개선") {
            return "future_change_signal"
        }

        return "reflection_signal"
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
