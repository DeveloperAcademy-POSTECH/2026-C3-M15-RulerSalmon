//
//  ReflectionSecondPassValidation.swift
//  Retrospective-Rulersalmon
//
//  Created by DevPaul on 6/6/26.
//

import Foundation

struct ReflectionSecondPassValidation: Codable, Equatable {
    let summary: String
    let verifiedDimensions: [ReflectionDimension]
    let primaryDimension: ReflectionDimension?
    let evidence: [String]
    let keywords: [String]
    let topic: String?
    let confidence: Double
    let reasoning: String
}

struct ReflectionRAGPipelineOutput: Equatable {
    let question: String
    let validation: ReflectionSecondPassValidation
    let firstPassResults: [FourLClassificationResult]
}
