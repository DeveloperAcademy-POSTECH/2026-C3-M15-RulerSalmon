//
//  QuestionPolicyService.swift
//  Retrospective-Rulersalmon
//
//  Created by DevPaul on 6/4/26.
//

import Foundation

struct QuestionPolicyService {
    func makePolicy(
        state: ReflectionState,
        analysis: ChunkAnalysis?,
        turnFourLAnalysis: TurnFourLAnalysis,
        interventionDecision: InterventionDecision
    ) -> QuestionGenerationPolicy {
        let shouldClose = closingCondition(state: state)
        if shouldClose {
            return QuestionGenerationPolicy(
                targetDimension: nil,
                intent: .wrapUp,
                focusText: state.lastUserChunk,
                reasoning: "회고가 충분히 채워져 자연스럽게 마무리할 타이밍",
                shouldClose: true
            )
        }

        guard let target = interventionDecision.targetDimension else {
            return QuestionGenerationPolicy(
                targetDimension: nil,
                intent: .wrapUp,
                focusText: state.lastUserChunk,
                reasoning: "추가 질문 대상이 뚜렷하지 않음",
                shouldClose: true
            )
        }

        let focus = focusText(for: target, state: state, analysis: analysis, turnFourLAnalysis: turnFourLAnalysis)
        let intent = intent(for: target, analysis: analysis, focusText: focus)

        return QuestionGenerationPolicy(
            targetDimension: target,
            intent: intent,
            focusText: focus,
            reasoning: reasoning(for: target, intent: intent, focusText: focus),
            shouldClose: false
        )
    }

    private func closingCondition(state: ReflectionState) -> Bool {
        let slots = [state.liked, state.learned, state.lacked, state.longedFor]
        let satisfiedCount = slots.filter(\.isSatisfied).count
        let averageFidelity = slots.map(\.fidelity).reduce(0, +) / Double(slots.count)
        let averageConfidence = slots.map(\.confidence).reduce(0, +) / Double(slots.count)
        return satisfiedCount == slots.count || (satisfiedCount >= 3 && averageFidelity >= 0.72 && averageConfidence >= 0.70)
    }

    private func focusText(
        for dimension: ReflectionDimension,
        state: ReflectionState,
        analysis: ChunkAnalysis?,
        turnFourLAnalysis: TurnFourLAnalysis
    ) -> String? {
        let slot = slot(for: dimension, state: state)

        if let evidence = slot.evidence.first, !evidence.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return evidence
        }

        if let evidence = turnFourLAnalysis.evidence(for: dimension).first,
           !evidence.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return evidence
        }

        if let summary = analysis?.dimensionSummaries[dimension.rawValue],
           !summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return summary
        }

        return analysis?.cleanedText ?? state.lastUserChunk
    }

    private func intent(for dimension: ReflectionDimension, analysis: ChunkAnalysis?, focusText: String?) -> QuestionIntent {
        let text = [analysis?.cleanedText, focusText].compactMap { $0 }.joined(separator: " ")

        switch dimension {
        case .liked:
            if text.contains("왜") || text.contains("이유") {
                return .reason
            }
            return .example

        case .learned:
            if text.contains("알게") || text.contains("배") || text.contains("이해") {
                return .lesson
            }
            return .reason

        case .lacked:
            if text.contains("막") || text.contains("어렵") || text.contains("부족") || text.contains("쉽지 않았") {
                return .blocker
            }
            if text.contains("답답") || text.contains("불안") || text.contains("부담") {
                return .feeling
            }
            return .reason

        case .longedFor:
            return .nextStep
        }
    }

    private func reasoning(for dimension: ReflectionDimension, intent: QuestionIntent, focusText: String?) -> String {
        let focus = focusText?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "핵심 맥락 없음"
        return "대상 축은 \(dimension.description), 질문 의도는 \(intent.koreanDescription), 초점은 \(focus)"
    }

    private func slot(for dimension: ReflectionDimension, state: ReflectionState) -> ReflectionSlot {
        switch dimension {
        case .liked: return state.liked
        case .learned: return state.learned
        case .lacked: return state.lacked
        case .longedFor: return state.longedFor
        }
    }
}
