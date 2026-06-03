//
//  ReflectionContextRetriever.swift
//  Retrospective-Rulersalmon
//
//  Created by DevPaul on 6/4/26.
//

import Foundation

struct ReflectionContextRetriever {
    func retrieveForAnalysis(
        currentText: String,
        entries: [ReflectionMemoryEntry],
        limit: Int = 3
    ) -> RetrievedReflectionContext {
        let queryTokens = normalizedTokens(from: currentText)
        let scored = scoreEntries(
            entries,
            queryTokens: queryTokens,
            targetDimension: nil
        )

        return RetrievedReflectionContext(entries: Array(scored.prefix(limit)))
    }

    func retrieveForQuestion(
        targetDimension: ReflectionDimension?,
        state: ReflectionState,
        analysis: ChunkAnalysis?,
        entries: [ReflectionMemoryEntry],
        limit: Int = 3
    ) -> RetrievedReflectionContext {
        let baseText = [
            analysis?.cleanedText,
            analysis?.summary,
            state.currentTopic,
            state.lastUserChunk
        ]
        .compactMap { $0 }
        .joined(separator: " ")

        let queryTokens = normalizedTokens(from: baseText)
        let historicalEntries = entries.count > 1 ? Array(entries.dropLast()) : entries
        let scored = scoreEntries(
            historicalEntries,
            queryTokens: queryTokens,
            targetDimension: targetDimension
        )

        return RetrievedReflectionContext(entries: Array(scored.prefix(limit)))
    }

    private func scoreEntries(
        _ entries: [ReflectionMemoryEntry],
        queryTokens: Set<String>,
        targetDimension: ReflectionDimension?
    ) -> [ReflectionMemoryEntry] {
        entries
            .map { entry in
                (entry: entry, score: score(entry: entry, queryTokens: queryTokens, targetDimension: targetDimension))
            }
            .filter { $0.score > 0 }
            .sorted {
                if $0.score == $1.score {
                    return $0.entry.createdAt > $1.entry.createdAt
                }
                return $0.score > $1.score
            }
            .map(\.entry)
    }

    private func score(
        entry: ReflectionMemoryEntry,
        queryTokens: Set<String>,
        targetDimension: ReflectionDimension?
    ) -> Double {
        let entryTokens = normalizedTokens(from: [entry.text, entry.summary, entry.keywords.joined(separator: " ")].joined(separator: " "))
        let overlap = queryTokens.intersection(entryTokens).count

        var score = Double(overlap) * 1.4

        if let targetDimension, entry.dimensionHints.contains(targetDimension) {
            score += 2.5
        }

        if !entry.evidence.isEmpty {
            score += 0.4
        }

        let age = abs(entry.createdAt.timeIntervalSinceNow)
        let recencyBonus = max(0, 1.6 - min(age / 900, 1.6))
        score += recencyBonus

        return score
    }

    private func normalizedTokens(from text: String) -> Set<String> {
        let separators = CharacterSet.alphanumerics.inverted
        let rawTokens = text
            .lowercased()
            .components(separatedBy: separators)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.count >= 2 }

        let stopWords: Set<String> = [
            "그냥", "이번", "저번", "정도", "조금", "되게", "진짜",
            "하고", "해서", "에서", "이건", "그건", "그리고", "근데"
        ]

        return Set(rawTokens.filter { !stopWords.contains($0) })
    }
}
