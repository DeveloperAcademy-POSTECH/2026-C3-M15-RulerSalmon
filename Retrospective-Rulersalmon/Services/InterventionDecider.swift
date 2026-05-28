//
//  InterventionDecider.swift
//  Retrospective-Rulersalmon
//
//  Created by DevPaul on 5/27/26.
//

import Foundation

struct InterventionDecider {
    func decide(state: ReflectionState, timeSinceLastAIQuestion: TimeInterval) -> InterventionDecision {
        guard timeSinceLastAIQuestion >= 8 else {
            return InterventionDecision(
                shouldIntervene: false,
                targetDimension: nil,
                reason: "Asked too recently",
                urgency: 0
            )
        }

        if !state.learned.isSatisfied {
            return InterventionDecision(
                shouldIntervene: true,
                targetDimension: .learned,
                reason: "Learned is missing",
                urgency: 0.8
            )
        }

        if !state.lacked.isSatisfied {
            return InterventionDecision(
                shouldIntervene: true,
                targetDimension: .lacked,
                reason: "Lacked is missing",
                urgency: 0.7
            )
        }

        if !state.longedFor.isSatisfied {
            return InterventionDecision(
                shouldIntervene: true,
                targetDimension: .longedFor,
                reason: "Longed For is missing",
                urgency: 0.65
            )
        }

        if !state.liked.isSatisfied {
            return InterventionDecision(
                shouldIntervene: true,
                targetDimension: .liked,
                reason: "Liked is missing",
                urgency: 0.5
            )
        }

        return InterventionDecision(
            shouldIntervene: false,
            targetDimension: nil,
            reason: "Reflection is sufficiently covered",
            urgency: 0
        )
    }
}
