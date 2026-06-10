//
//  SentimentRecord.swift
//  Retrospective-Rulersalmon
//
//  Created by chaem on 6/5/26.
//

import Foundation
import SwiftData

@Model
final class SentimentRecord {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var transcript: String
    var positivePercentage: Double
    var negativePercentage: Double
    var satisfactionScore: Double

    init(
        id: UUID = UUID(),
        createdAt: Date,
        transcript: String,
        result: RetrospectiveSentimentResult
    ) {
        self.id = id
        self.createdAt = createdAt
        self.transcript = transcript
        self.positivePercentage = result.positivePercentage
        self.negativePercentage = result.negativePercentage
        self.satisfactionScore = result.satisfactionScore
    }
}
