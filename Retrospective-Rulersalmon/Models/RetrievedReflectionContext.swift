//
//  RetrievedReflectionContext.swift
//  Retrospective-Rulersalmon
//
//  Created by DevPaul on 6/4/26.
//

import Foundation

struct RetrievedReflectionContext: Equatable {
    let items: [RetrievedReflectionItem]

    var entries: [ReflectionMemoryEntry] {
        items.map(\.entry)
    }

    var isEmpty: Bool {
        items.isEmpty
    }

    func koreanPromptBlock() -> String {
        guard !items.isEmpty else { return "없음" }

        return items.enumerated().map { index, item in
            let entry = item.entry
            let dimensions = entry.dimensionHints.map(\.description).joined(separator: ", ")
            let keywords = entry.keywords.prefix(3).joined(separator: ", ")
            let evidence = entry.evidence.prefix(2).joined(separator: " / ")
            let matchedTerms = item.matchedTerms.prefix(3).joined(separator: ", ")

            return """
            \(index + 1). 요약: \(entry.summary)
               원문: \(entry.text)
               차원: \(dimensions.isEmpty ? "없음" : dimensions)
               키워드: \(keywords.isEmpty ? "없음" : keywords)
               근거: \(evidence.isEmpty ? "없음" : evidence)
               검색 이유: \(item.reason)
               매칭 표현: \(matchedTerms.isEmpty ? "없음" : matchedTerms)
            """
        }
        .joined(separator: "\n")
    }
}
