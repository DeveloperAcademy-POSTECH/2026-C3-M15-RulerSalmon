//
//  ReflectionContextRetriever.swift
//  Retrospective-Rulersalmon
//
//  Created by DevPaul on 6/4/26.
//

import Foundation

struct ReflectionContextRetriever {
    func retrieve(
        query: ReflectionRetrievalQuery,
        entries: [ReflectionMemoryEntry],
        limit: Int = 3
    ) -> RetrievedReflectionContext {
        let historicalEntries = query.purpose == .question && entries.count > 1 ? Array(entries.dropLast()) : entries
        let queryTokens = normalizedTokens(from: query.rawText)
        let scored = scoreEntries(
            historicalEntries,
            queryTokens: queryTokens,
            preferredPhrases: query.preferredPhrases,
            targetDimension: query.targetDimension,
            limit: limit
        )

        return RetrievedReflectionContext(items: scored)
    }

    private func scoreEntries(
        _ entries: [ReflectionMemoryEntry],
        queryTokens: Set<String>,
        preferredPhrases: [String],
        targetDimension: ReflectionDimension?,
        limit: Int
    ) -> [RetrievedReflectionItem] {
        entries
            .compactMap { entry in
                let scored = score(entry: entry, queryTokens: queryTokens, preferredPhrases: preferredPhrases, targetDimension: targetDimension)
                guard scored.score > 0 else { return nil }
                return RetrievedReflectionItem(
                    entry: entry,
                    score: scored.score,
                    matchedTerms: scored.matchedTerms,
                    reason: scored.reason
                )
            }
            .sorted {
                if $0.score == $1.score {
                    return $0.entry.createdAt > $1.entry.createdAt
                }
                return $0.score > $1.score
            }
            .prefix(limit)
            .map { $0 }
    }

    private func score(
        entry: ReflectionMemoryEntry,
        queryTokens: Set<String>,
        preferredPhrases: [String],
        targetDimension: ReflectionDimension?
    ) -> (score: Double, matchedTerms: [String], reason: String) {
        let entryTokens = normalizedTokens(from: [entry.text, entry.summary, entry.keywords.joined(separator: " ")].joined(separator: " "))
        let matchedTerms = Array(queryTokens.intersection(entryTokens)).sorted()
        let overlap = matchedTerms.count

        var score = Double(overlap) * 1.4
        var reasons: [String] = []

        if overlap > 0 {
            reasons.append("같은 표현이 겹침")
        }

        if let targetDimension, entry.dimensionHints.contains(targetDimension) {
            score += 2.5
            reasons.append("같은 4L 축")
        }

        let phraseMatch = preferredPhrases.contains { phrase in
            let trimmed = phrase.trimmingCharacters(in: .whitespacesAndNewlines)
            return !trimmed.isEmpty && (entry.text.contains(trimmed) || entry.summary.contains(trimmed))
        }
        if phraseMatch {
            score += 1.2
            reasons.append("초점 문장 일치")
        }

        if !entry.evidence.isEmpty {
            score += 0.4
            reasons.append("근거 문장 보유")
        }

        let age = abs(entry.createdAt.timeIntervalSinceNow)
        let recencyBonus = max(0, 1.6 - min(age / 900, 1.6))
        score += recencyBonus
        if recencyBonus > 0.2 {
            reasons.append("최근 맥락")
        }

        return (score, matchedTerms, reasons.joined(separator: ", "))
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
