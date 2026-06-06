//
//  ReflectionMemoryEntry.swift
//  Retrospective-Rulersalmon
//
//  Created by DevPaul on 6/4/26.
//

import Foundation

struct ReflectionMemoryEntry: Identifiable, Equatable {
    let id: UUID
    let sessionID: UUID
    let text: String
    let summary: String
    let topic: String?
    let dimensionHints: [ReflectionDimension]
    let keywords: [String]
    let evidence: [String]
    let importance: Double
    let createdAt: Date

    init(
        id: UUID = UUID(),
        sessionID: UUID,
        text: String,
        summary: String,
        topic: String? = nil,
        dimensionHints: [ReflectionDimension],
        keywords: [String],
        evidence: [String],
        importance: Double = 0.5,
        createdAt: Date
    ) {
        self.id = id
        self.sessionID = sessionID
        self.text = text
        self.summary = summary
        self.topic = topic
        self.dimensionHints = dimensionHints
        self.keywords = keywords
        self.evidence = evidence
        self.importance = importance
        self.createdAt = createdAt
    }
}
