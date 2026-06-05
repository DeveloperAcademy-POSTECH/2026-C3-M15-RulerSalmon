//
//  SentimentStatistics.swift
//  Retrospective-Rulersalmon
//
//  Created by chaem on 6/5/26.
//

import Foundation

struct SentimentSummary {
    let positivePercentage: Double
    let negativePercentage: Double
    let satisfactionScore: Double
    
    static let empty = SentimentSummary(
        positivePercentage: 0,
        negativePercentage: 0,
        satisfactionScore: 3)
}

struct SentimentStatistics {
    static func summarize(_ records: [SentimentRecord]) -> SentimentSummary {
        
        guard !records.isEmpty else { return .empty }
        
        let positiveEvidence = records.reduce(0) {
            $0 + $1.positiveEvidence
        }
        let negativeEvidence = records.reduce(0) {
            $0 + $1.negativeEvidence
        }
        let total = positiveEvidence + negativeEvidence
        
        guard total > 0 else { return .empty }
        
        return SentimentSummary(
            positivePercentage: Double(positiveEvidence) / Double(total) * 100,
            negativePercentage: Double(negativeEvidence) / Double(total) * 100,
            satisfactionScore: 1 + (positiveEvidence / total * 4)
        )
    }
}
