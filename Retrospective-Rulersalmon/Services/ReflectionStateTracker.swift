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
        newState.lastUserChunk = analysis.originalText
        newState.currentTopic = makeCurrentTopic(from: analysis, previous: state.currentTopic)
        newState.lastUpdatedAt = .now

        for dimension in analysis.detectedDimensions {
            switch dimension {
            case .liked:
                update(slot: &newState.liked, analysis: analysis, dimension: .liked)
            case .learned:
                update(slot: &newState.learned, analysis: analysis, dimension: .learned)
            case .lacked:
                update(slot: &newState.lacked, analysis: analysis, dimension: .lacked)
            case .longedFor:
                update(slot: &newState.longedFor, analysis: analysis, dimension: .longedFor)
            }
        }
        return newState
    }

    func recordQuestion(for dimension: ReflectionDimension, in state: ReflectionState) -> ReflectionState {
        var newState = state
        if !newState.askedDimensions.contains(dimension) {
            newState.askedDimensions.append(dimension)
        }
        newState.lastUpdatedAt = .now
        return newState
    }

    private func update(slot: inout ReflectionSlot, analysis: ChunkAnalysis, dimension: ReflectionDimension) {
        slot.evidence = mergeEvidence(existing: slot.evidence, incoming: analysis.evidence)
        slot.summary = resolvedSummary(for: dimension, analysis: analysis)
        slot.confidence = max(slot.confidence, analysis.confidence)
        slot.fidelity = max(slot.fidelity, fidelity(for: dimension, analysis: analysis))
        slot.isSatisfied = slot.confidence >= 0.68 || slot.fidelity >= 0.68 || slot.evidence.count >= 2
    }

    private func mergeEvidence(existing: [String], incoming: [String]) -> [String] {
        var merged = existing

        for item in incoming where !merged.contains(item) {
            merged.append(item)
        }

        if merged.count > 5 {
            merged = Array(merged.suffix(5))
        }

        return merged
    }

    private func makeCurrentTopic(from analysis: ChunkAnalysis, previous: String?) -> String? {
        if let primaryDimension = analysis.primaryDimension {
            return primaryDimension.description
        }

        if analysis.chunkType != .unknown && analysis.chunkType != .filler {
            return analysis.chunkType.title
        }

        if analysis.isMeaningful {
            return previous ?? analysis.summary
        }

        return previous
    }

    private func resolvedSummary(for dimension: ReflectionDimension, analysis: ChunkAnalysis) -> String {
        if let summary = analysis.dimensionSummaries[dimension.rawValue]?.trimmingCharacters(in: .whitespacesAndNewlines),
           !summary.isEmpty {
            return summary
        }

        return fallbackDimensionSummary(for: dimension, analysis: analysis)
    }

    private func fallbackDimensionSummary(for dimension: ReflectionDimension, analysis: ChunkAnalysis) -> String {
        let evidence = analysis.evidence.first ?? analysis.summary
        let focus = dimension.description

        switch dimension {
        case .liked:
            return "\(focus)은 \(evidence)"
        case .learned:
            return "\(focus)은 \(evidence)"
        case .lacked:
            return "\(focus)은 \(evidence)"
        case .longedFor:
            return "\(focus)은 \(evidence)"
        }
    }

    private func fidelity(for dimension: ReflectionDimension, analysis: ChunkAnalysis) -> Double {
        var score = 0.0

        if analysis.detectedDimensions.contains(dimension) {
            score += 0.25
        }

        if analysis.primaryDimension == dimension {
            score += 0.2
        }

        if !analysis.evidence.isEmpty {
            score += min(Double(analysis.evidence.count) * 0.15, 0.3)
        }

        if let summary = analysis.dimensionSummaries[dimension.rawValue], !summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            score += 0.15
            score += summarySpecificityBonus(for: dimension, summary: summary)
        } else {
            score += 0.05
        }

        score += keywordBonus(for: dimension, analysis: analysis)

        return min(score, 1.0)
    }

    private func summarySpecificityBonus(for dimension: ReflectionDimension, summary: String) -> Double {
        let lowered = summary.lowercased()
        let cues = summaryCueKeywords(for: dimension)
        if cues.contains(where: { lowered.contains($0.lowercased()) }) {
            return 0.1
        }

        return summary.count >= 18 ? 0.05 : 0
    }

    private func keywordBonus(for dimension: ReflectionDimension, analysis: ChunkAnalysis) -> Double {
        let cues = summaryCueKeywords(for: dimension)
        guard !cues.isEmpty else { return 0 }

        let matched = cues.filter { cue in
            analysis.keywords.contains(where: { $0.contains(cue) }) || analysis.cleanedText.contains(cue)
        }

        return min(Double(matched.count) * 0.08, 0.2)
    }

    private func summaryCueKeywords(for dimension: ReflectionDimension) -> [String] {
        switch dimension {
        case .liked:
            return ["좋았", "뿌듯", "만족", "성공", "잘 됐", "협업", "안정"]
        case .learned:
            return ["배웠", "알게", "깨달", "이해", "정리", "감이", "의미"]
        case .lacked:
            return ["아쉬", "부족", "막혔", "어려웠", "헷갈", "개선", "흔들"]
        case .longedFor:
            return ["다음", "바라", "하고 싶", "해보고 싶", "원하", "개선", "더"]
        }
    }
}
