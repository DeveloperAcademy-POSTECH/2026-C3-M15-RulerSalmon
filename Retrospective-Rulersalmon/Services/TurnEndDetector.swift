//
//  TurnEndDetector.swift
//  Retrospective-Rulersalmon
//
//  Created by DevPaul on 5/29/26.
//

import Foundation

struct TurnEndDecision {
    let shouldEnd: Bool
    let confidence: Double
    let reason: String
}

struct TurnEndDetector {
    var shortSilenceThreshold: TimeInterval = 1.0
    var standardSilenceThreshold: TimeInterval = 1.6
    var longSilenceThreshold: TimeInterval = 2.2
    var minimumMeaningfulCharacterCount: Int = 18
    var minimumTokenCount: Int = 6

    func decide(
        transcript: String,
        analysis: ChunkAnalysis?,
        silence: TimeInterval
    ) -> TurnEndDecision {
        let normalized = normalize(transcript)
        guard !normalized.isEmpty else {
            return TurnEndDecision(
                shouldEnd: false,
                confidence: 0,
                reason: "turn transcript is empty"
            )
        }

        let characterCount = normalized.count
        let tokenCount = normalized.split(whereSeparator: { $0.isWhitespace }).count
        let hasSentenceBoundary = analysis?.hasSentenceBoundary ?? containsSentenceBoundary(in: normalized)
        let hasTopicShift = analysis?.hasTopicShift ?? containsTopicShiftMarker(in: normalized)
        let hasMajorClosingCue = containsMajorParagraphMarker(in: normalized)
        let hasContinuationCue = containsContinuationMarker(in: normalized)
        let isMeaningful = (analysis?.isMeaningful ?? false)
            || characterCount >= minimumMeaningfulCharacterCount
            || tokenCount >= minimumTokenCount

        if hasContinuationCue && silence < longSilenceThreshold {
            return TurnEndDecision(
                shouldEnd: false,
                confidence: 0.18,
                reason: "continuation cue detected"
            )
        }

        let score = turnEndScore(
            silence: silence,
            hasSentenceBoundary: hasSentenceBoundary,
            hasTopicShift: hasTopicShift,
            hasMajorClosingCue: hasMajorClosingCue,
            isMeaningful: isMeaningful,
            characterCount: characterCount
        )

        let threshold = hasMajorClosingCue || hasTopicShift ? 0.55 : 0.68
        let shouldEnd = score >= threshold && (
            hasSentenceBoundary || hasMajorClosingCue || silence >= longSilenceThreshold
        )

        return TurnEndDecision(
            shouldEnd: shouldEnd,
            confidence: min(score, 1.0),
            reason: turnEndReason(
                shouldEnd: shouldEnd,
                hasSentenceBoundary: hasSentenceBoundary,
                hasTopicShift: hasTopicShift,
                hasMajorClosingCue: hasMajorClosingCue,
                silence: silence
            )
        )
    }

    private func turnEndScore(
        silence: TimeInterval,
        hasSentenceBoundary: Bool,
        hasTopicShift: Bool,
        hasMajorClosingCue: Bool,
        isMeaningful: Bool,
        characterCount: Int
    ) -> Double {
        var score = 0.0

        if silence >= shortSilenceThreshold {
            score += 0.2
        }

        if silence >= standardSilenceThreshold {
            score += 0.3
        }

        if silence >= longSilenceThreshold {
            score += 0.25
        }

        if hasSentenceBoundary {
            score += 0.2
        }

        if hasMajorClosingCue {
            score += 0.18
        }

        if hasTopicShift {
            score += 0.08
        }

        if isMeaningful {
            score += 0.1
        }

        if characterCount >= 60 {
            score += 0.05
        }

        return score
    }

    private func turnEndReason(
        shouldEnd: Bool,
        hasSentenceBoundary: Bool,
        hasTopicShift: Bool,
        hasMajorClosingCue: Bool,
        silence: TimeInterval
    ) -> String {
        guard shouldEnd else {
            if silence >= longSilenceThreshold {
                return "waiting for a clearer closing cue"
            }

            return "speech still feels open"
        }

        if hasMajorClosingCue {
            return "closing cue and silence detected"
        }

        if hasTopicShift && hasSentenceBoundary {
            return "topic shift and sentence boundary detected"
        }

        if hasSentenceBoundary {
            return "sentence boundary and silence detected"
        }

        return "silence threshold reached"
    }

    private func normalize(_ text: String) -> String {
        text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
    }

    private func containsSentenceBoundary(in text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }

        let punctuationMarks: Set<Character> = [".", "?", "!", "…", "~", "。", "？", "！"]
        if let lastCharacter = trimmed.last, punctuationMarks.contains(lastCharacter) {
            return true
        }

        let sentenceEndings = [
            "다", "요", "죠", "습니다", "입니다", "예요", "이에요",
            "했어요", "했어", "였어요", "였어", "네요", "구요", "듯해요", "같아요"
        ]

        let lastToken = trimmed.split(whereSeparator: { $0.isWhitespace }).last.map(String.init) ?? trimmed
        return sentenceEndings.contains { lastToken.hasSuffix($0) }
    }

    private func containsTopicShiftMarker(in text: String) -> Bool {
        let markers = [
            "근데", "그리고", "다음", "한편", "또", "이제", "원래",
            "결국", "마지막으로", "전환", "바뀌", "넘어가", "다시", "새로"
        ]
        return markers.contains { text.contains($0) }
    }

    private func containsMajorParagraphMarker(in text: String) -> Bool {
        let markers = [
            "다만", "하지만", "그런데", "전체적으로",
            "정리하면", "결론적으로", "마지막으로",
            "한편", "반면", "다음에는", "다음엔", "추가로", "끝으로"
        ]
        return markers.contains { text.contains($0) }
    }

    private func containsContinuationMarker(in text: String) -> Bool {
        let markers = [
            "그리고", "근데", "다만", "하지만", "그런데", "또",
            "추가로", "이어서", "그다음", "계속", "아직", "아무래도"
        ]

        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return markers.contains(where: { trimmed.hasSuffix($0) || trimmed.contains(" \($0)") })
    }
}
