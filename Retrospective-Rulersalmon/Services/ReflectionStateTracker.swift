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
        let dimensionEvidence = dimensionEvidence(for: dimension, analysis: analysis)
        slot.evidence = mergeEvidence(existing: slot.evidence, incoming: dimensionEvidence)
        slot.summary = resolvedSummary(for: dimension, analysis: analysis)
        slot.confidence = max(slot.confidence, confidence(for: dimension, analysis: analysis))
        slot.fidelity = max(slot.fidelity, fidelity(for: dimension, analysis: analysis))
        let strongMatch = slot.confidence >= 0.72 && slot.fidelity >= 0.68
        let evidenceBackedMatch = slot.evidence.count >= 2 && slot.fidelity >= 0.62
        slot.isSatisfied = strongMatch || evidenceBackedMatch
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
           !summary.isEmpty,
           isDimensionSpecific(summary, for: dimension) {
            return summary
        }

        return fallbackDimensionSummary(for: dimension, analysis: analysis)
    }

    private func fallbackDimensionSummary(for dimension: ReflectionDimension, analysis: ChunkAnalysis) -> String {
        let evidence = dimensionEvidence(for: dimension, analysis: analysis).first
            ?? analysis.evidence.first
            ?? analysis.summary

        switch dimension {
        case .liked:
            return "좋았던 점은 \(evidence)"
        case .learned:
            return "배운 점은 \(evidence)"
        case .lacked:
            return "부족했던 점은 \(evidence)"
        case .longedFor:
            return "바라는 점은 \(evidence)"
        }
    }

    private func dimensionEvidence(for dimension: ReflectionDimension, analysis: ChunkAnalysis) -> [String] {
        let cues = summaryCueKeywords(for: dimension)
        let preferred = analysis.evidence.filter { item in
            let lowered = item.lowercased()
            return cues.contains(where: { lowered.contains($0.lowercased()) })
        }

        if !preferred.isEmpty {
            return preferred
        }

        let clauseMatches = analysis.clauses.filter { clause in
            let lowered = clause.lowercased()
            return cues.contains(where: { lowered.contains($0.lowercased()) })
        }

        if !clauseMatches.isEmpty {
            return clauseMatches
        }

        return analysis.evidence
    }

    private func isDimensionSpecific(_ summary: String, for dimension: ReflectionDimension) -> Bool {
        let lowered = summary.lowercased()
        let targetCues = summaryCueKeywords(for: dimension)
        let otherCues = ReflectionDimension.allCases
            .filter { $0 != dimension }
            .flatMap { summaryCueKeywords(for: $0) }

        let targetMatch = targetCues.contains { lowered.contains($0.lowercased()) }
        let otherMatch = otherCues.contains { lowered.contains($0.lowercased()) }

        if targetMatch && !otherMatch {
            return true
        }

        if summary.contains(dimension.description) && !otherMatch {
            return true
        }

        return false
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

    private func confidence(for dimension: ReflectionDimension, analysis: ChunkAnalysis) -> Double {
        var score = 0.0

        if analysis.detectedDimensions.contains(dimension) {
            score += 0.18
        }

        if analysis.primaryDimension == dimension {
            score += 0.16
        }

        if !dimensionEvidence(for: dimension, analysis: analysis).isEmpty {
            score += 0.22
        }

        if let summary = analysis.dimensionSummaries[dimension.rawValue], !summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            score += 0.14
            score += summarySpecificityBonus(for: dimension, summary: summary)
        }

        score += keywordBonus(for: dimension, analysis: analysis) * 0.6

        if analysis.chunkType == .unknown || analysis.chunkType == .filler {
            score -= 0.12
        }

        if analysis.missingFollowUpHints.contains(dimension) {
            score -= 0.08
        }

        return min(max(score, 0), 0.9)
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
