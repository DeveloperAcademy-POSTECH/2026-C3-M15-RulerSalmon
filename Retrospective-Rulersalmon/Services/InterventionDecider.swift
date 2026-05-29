//
//  InterventionDecider.swift
//  Retrospective-Rulersalmon
//
//  Created by DevPaul on 5/27/26.
//

import Foundation

struct InterventionDecider {
    func decide(
        state: ReflectionState,
        timeSinceLastAIQuestion: TimeInterval,
        timeSinceLastUserChunk: TimeInterval,
        isUserSpeaking: Bool
    ) -> InterventionDecision {
        guard !isUserSpeaking else {
            return InterventionDecision(
                shouldIntervene: false,
                targetDimension: nil,
                reason: "User is speaking",
                urgency: 0
            )
        }

        guard timeSinceLastUserChunk >= 1.2 else {
            return InterventionDecision(
                shouldIntervene: false,
                targetDimension: nil,
                reason: "User chunk is too fresh",
                urgency: 0
            )
        }

        guard timeSinceLastAIQuestion >= 8 else {
            return InterventionDecision(
                shouldIntervene: false,
                targetDimension: nil,
                reason: "Asked too recently",
                urgency: 0
            )
        }

        guard let target = chooseTargetDimension(in: state) else {
            return InterventionDecision(
                shouldIntervene: false,
                targetDimension: nil,
                reason: "Reflection is sufficiently covered",
                urgency: 0
            )
        }

        return InterventionDecision(
            shouldIntervene: true,
            targetDimension: target,
            reason: reason(for: target, state: state),
            urgency: urgency(for: target)
        )
    }

    private func chooseTargetDimension(in state: ReflectionState) -> ReflectionDimension? {
        let ordered: [ReflectionDimension] = [.learned, .lacked, .longedFor, .liked]

        if let target = ordered.first(where: { !isSatisfied($0, in: state) && !state.askedDimensions.contains($0) }) {
            return target
        }

        if let target = ordered.first(where: { !isSatisfied($0, in: state) }) {
            return target
        }

        return nil
    }

    private func isSatisfied(_ dimension: ReflectionDimension, in state: ReflectionState) -> Bool {
        slot(for: dimension, in: state).isSatisfied
    }

    private func slot(for dimension: ReflectionDimension, in state: ReflectionState) -> ReflectionSlot {
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

    private func reason(for dimension: ReflectionDimension, state: ReflectionState) -> String {
        if state.askedDimensions.contains(dimension) {
            return "\(dimension.description)을 다시 확인할 타이밍"
        }

        return "\(dimension.description)이 아직 부족함"
    }

    private func urgency(for dimension: ReflectionDimension) -> Double {
        switch dimension {
        case .learned:
            return 0.85
        case .lacked:
            return 0.75
        case .longedFor:
            return 0.65
        case .liked:
            return 0.55
        }
    }
}
