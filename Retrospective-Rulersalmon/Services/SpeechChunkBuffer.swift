//
//  SpeechChunkBuffer.swift
//  Retrospective-Rulersalmon
//
//  Created by DevPaul on 5/27/26.
//

import Foundation

@MainActor
final class UtteranceBuffer {
    var silenceCommitDelayNanoseconds: UInt64 = 1_000_000_000
    var minimumMeaningfulCharacterCount: Int = 8
    var minimumStableCharacterCount: Int = 12
    var longUtteranceCharacterCount: Int = 28

    private var committedTranscript = ""
    private var latestTranscript = ""
    private var latestRevision = 0
    private var commitTask: Task<Void, Never>?
    private var lastCommittedChunk = ""

    func reset() {
        commitTask?.cancel()
        commitTask = nil
        committedTranscript = ""
        latestTranscript = ""
        latestRevision = 0
        lastCommittedChunk = ""
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
            guard normalize(committedChunk) != normalize(lastCommittedChunk) else { return }

            self.committedTranscript = self.latestTranscript
            self.lastCommittedChunk = committedChunk
            await MainActor.run {
                onCommitted(committedChunk)
            }
        }
    }

    private func shouldCommit(text: String, committedChunk: String) -> Bool {
        let normalized = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return false }

        let characterCount = normalized.count
        let tokenCount = normalized.split(whereSeparator: { $0.isWhitespace }).count
        let hasSentenceBoundary = containsSentenceBoundary(in: normalized)
        let hasTopicShift = containsTopicShiftMarker(in: normalized)
        let hasMajorParagraphMarker = containsMajorParagraphMarker(in: normalized)

        if committedChunk.isEmpty {
            return false
        }

        if !hasSentenceBoundary {
            return false
        }

        if hasMajorParagraphMarker {
            return true
        }

        if hasTopicShift {
            return true
        }

        if characterCount >= longUtteranceCharacterCount {
            return true
        }

        if tokenCount >= 18 && characterCount >= minimumStableCharacterCount {
            return true
        }

        return false
    }

    private func extractCommittedChunk() -> String {
        let normalizedCommitted = normalize(committedTranscript)
        let normalizedLatest = normalize(latestTranscript)

        if normalizedLatest.hasPrefix(normalizedCommitted) {
            let suffix = normalizedLatest.dropFirst(normalizedCommitted.count)
            return normalize(String(suffix))
        }

        return normalizedLatest
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

    private func isMeaningful(_ text: String) -> Bool {
        let compact = text.replacingOccurrences(of: " ", with: "")
        return compact.count >= minimumMeaningfulCharacterCount
    }
}

typealias SpeechChunkBuffer = UtteranceBuffer
