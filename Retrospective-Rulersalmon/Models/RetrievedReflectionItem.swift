//
//  RetrievedReflectionItem.swift
//  Retrospective-Rulersalmon
//
//  Created by DevPaul on 6/4/26.
//

import Foundation

struct RetrievedReflectionItem: Equatable, Identifiable {
    let id: UUID
    let entry: ReflectionMemoryEntry
    let score: Double
    let matchedTerms: [String]
    let reason: String

    init(entry: ReflectionMemoryEntry, score: Double, matchedTerms: [String], reason: String) {
        self.id = entry.id
        self.entry = entry
        self.score = score
        self.matchedTerms = matchedTerms
        self.reason = reason
    }
}
