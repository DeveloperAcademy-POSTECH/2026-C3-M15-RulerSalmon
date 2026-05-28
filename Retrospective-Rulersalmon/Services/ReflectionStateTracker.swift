//
//  ReflectionStateTracker.swift
//  Retrospective-Rulersalmon
//
//  Created by DevPaul on 5/27/26.
//

import Foundation

struct ReflectionStateTracker {
    func apply(_ analysis: ChunkAnalysis, to state: ReflectionState) -> ReflectionState {
        var newState = state

        for dimension in analysis.detectedDimensions {
            switch dimension {
            case .liked:
                update(slot: &newState.liked, analysis: analysis)
            case .learned:
                update(slot: &newState.learned, analysis: analysis)
            case .lacked:
                update(slot: &newState.lacked, analysis: analysis)
            case .longedFor:
                update(slot: &newState.longedFor, analysis: analysis)
            }
        }

        newState.lastUserChunk = analysis.originalText
        return newState
    }

    private func update(slot: inout ReflectionSlot, analysis: ChunkAnalysis) {
        slot.evidence.append(contentsOf: analysis.evidence)
        slot.summary = analysis.summary
        slot.confidence = max(slot.confidence, analysis.confidence)
        slot.isSatisfied = slot.confidence >= 0.6 || !slot.evidence.isEmpty
    }
}
