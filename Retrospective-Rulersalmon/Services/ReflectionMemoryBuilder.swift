//
//  ReflectionMemoryBuilder.swift
//  Retrospective-Rulersalmon
//
//  Created by DevPaul on 6/6/26.
//

import Foundation

struct ReflectionMemoryBuilder {
    func build(
        sessionID: UUID,
        userText: String,
        validation: ReflectionSecondPassValidation,
        createdAt: Date
    ) -> ReflectionMemoryEntry {
        ReflectionMemoryEntry(
            sessionID: sessionID,
            text: userText,
            summary: validation.summary,
            topic: validation.topic,
            dimensionHints: validation.verifiedDimensions,
            keywords: validation.keywords,
            evidence: validation.evidence,
            importance: importance(for: validation),
            createdAt: createdAt
        )
    }

    private func importance(for validation: ReflectionSecondPassValidation) -> Double {
        var score = validation.confidence * 0.65
        score += min(Double(validation.evidence.count) * 0.1, 0.2)
        if validation.primaryDimension != nil {
            score += 0.1
        }
        return min(max(score, 0.2), 1.0)
    }
}
