//
//  SpeechChunkBuffer.swift
//  Retrospective-Rulersalmon
//
//  Created by DevPaul on 5/27/26.
//

import Foundation

@MainActor
final class UtteranceBuffer {
    var silenceCommitDelayNanoseconds: UInt64 = 800_000_000
    var minimumMeaningfulCharacterCount: Int = 8
    var minimumStableCharacterCount: Int = 12
    var longUtteranceCharacterCount: Int = 28

    private var committedTranscript = ""
    private var latestTranscript = ""
    private var latestRevision = 0
    private var commitTask: Task<Void, Never>?

    func reset() {
        commitTask?.cancel()
        commitTask = nil
        committedTranscript = ""
        latestTranscript = ""
        latestRevision = 0
    }

    func update(
        partialText: String,
        onCommitted: @escaping @MainActor (String) -> Void
    ) {
        let normalized = normalize(partialText)
        guard !normalized.isEmpty else { return }
        guard normalized != latestTranscript else { return }

        latestTranscript = normalized
        latestRevision += 1
        let revision = latestRevision

        commitTask?.cancel()
        commitTask = Task { [weak self] in
            guard let self else { return }

            do {
                try await Task.sleep(nanoseconds: silenceCommitDelayNanoseconds)
            } catch {
                return
            }

            guard !Task.isCancelled else { return }
            guard revision == self.latestRevision else { return }

            let committedChunk = self.extractCommittedChunk()
            guard self.shouldCommit(text: self.latestTranscript, committedChunk: committedChunk) else { return }
            guard !committedChunk.isEmpty else { return }

            self.committedTranscript = self.latestTranscript
            await MainActor.run {
                onCommitted(committedChunk)
            }
        }
    }

    private func shouldCommit(text: String, committedChunk: String) -> Bool {
        let normalized = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return false }

        let characterCount = normalized.count
        let hasSentenceBoundary = containsSentenceBoundary(in: normalized)
        let hasTopicShift = containsTopicShiftMarker(in: normalized)

        if committedChunk.isEmpty {
            return false
        }

        if hasTopicShift {
            return true
        }

        if hasSentenceBoundary {
            return true
        }

        if characterCount >= longUtteranceCharacterCount {
            return true
        }

        return characterCount >= minimumStableCharacterCount || isMeaningful(normalized)
    }

    private func extractCommittedChunk() -> String {
        let normalizedCommitted = normalize(committedTranscript)
        let normalizedLatest = normalize(latestTranscript)

        if normalizedLatest.hasPrefix(normalizedCommitted) {
            let suffix = normalizedLatest.dropFirst(normalizedCommitted.count)
            return normalize(String(suffix))
        }

        let committedTokens = tokenize(normalizedCommitted)
        let latestTokens = tokenize(normalizedLatest)
        let overlap = overlapCount(committedTokens: committedTokens, latestTokens: latestTokens)

        guard overlap < latestTokens.count else {
            return ""
        }

        return latestTokens.dropFirst(overlap).joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func normalize(_ text: String) -> String {
        text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
    }

    private func tokenize(_ text: String) -> [String] {
        text
            .split(whereSeparator: { $0.isWhitespace })
            .map(String.init)
    }

    private func overlapCount(committedTokens: [String], latestTokens: [String]) -> Int {
        guard !committedTokens.isEmpty, !latestTokens.isEmpty else { return 0 }

        let maxOverlap = min(committedTokens.count, latestTokens.count, 8)
        guard maxOverlap > 0 else { return 0 }

        for length in stride(from: maxOverlap, through: 1, by: -1) {
            let committedSuffix = Array(committedTokens.suffix(length))
            let latestPrefix = Array(latestTokens.prefix(length))
            if committedSuffix == latestPrefix {
                return length
            }
        }

        return 0
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

    private func isMeaningful(_ text: String) -> Bool {
        let compact = text.replacingOccurrences(of: " ", with: "")
        return compact.count >= minimumMeaningfulCharacterCount
    }
}

typealias SpeechChunkBuffer = UtteranceBuffer
