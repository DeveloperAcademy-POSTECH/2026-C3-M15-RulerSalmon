//
//  ReflectionMemoryEntry.swift
//  Retrospective-Rulersalmon
//
//  Created by DevPaul on 6/4/26.
//

import Foundation

struct ReflectionMemoryEntry: Identifiable, Equatable {
    let id: UUID
    let text: String
    let summary: String
    let dimensionHints: [ReflectionDimension]
    let keywords: [String]
    let evidence: [String]
    let createdAt: Date

    init(
        id: UUID = UUID(),
        text: String,
        summary: String,
        dimensionHints: [ReflectionDimension],
        keywords: [String],
        evidence: [String],
        createdAt: Date
    ) {
        self.id = id
        self.text = text
        self.summary = summary
        self.dimensionHints = dimensionHints
        self.keywords = keywords
        self.evidence = evidence
        self.createdAt = createdAt
    }
}
