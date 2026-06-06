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
        
        let count = records.count
        
        let positivePercentage = records.reduce(0) {
            $0 + $1.positivePercentage
        }
        let negativePercentage = records.reduce(0) {
            $0 + $1.negativePercentage
        }
        let satisfactionScore = records.reduce(0) {
            $0 + $1.satisfactionScore
        }
        
        guard count > 0 else { return .empty }
        
        return SentimentSummary(
            positivePercentage: Double(positivePercentage) / Double(count),
            negativePercentage: Double(negativePercentage) / Double(count),
            satisfactionScore: Double(satisfactionScore) / Double(count)
        )
    }
}
