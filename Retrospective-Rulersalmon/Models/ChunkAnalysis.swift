//
//  ChunkAnalysis.swift
//  Retrospective-Rulersalmon
//
//  Created by DevPaul on 5/27/26.
//

import Foundation

struct ChunkAnalysis: Codable, Equatable {
    let originalText: String
    let cleanedText: String
    let chunkType: ChunkType
    let summary: String
    let dimensionSummaries: [String: String]
    let detectedDimensions: [ReflectionDimension]
    let primaryDimension: ReflectionDimension?
    let emotions: [String]
    let keywords: [String]
    let clauses: [String]
    let evidence: [String]
    let missingFollowUpHints: [ReflectionDimension]
    let hasSentenceBoundary: Bool
    let hasTopicShift: Bool
    let isMeaningful: Bool
    let confidence: Double
}
