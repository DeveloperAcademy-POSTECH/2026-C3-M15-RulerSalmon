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
    let summary: String
    let detectedDimensions: [ReflectionDimension]
    let emotions: [String]
    let evidence: [String]
    let missingFollowUpHints: [ReflectionDimension]
    let confidence: Double
}
