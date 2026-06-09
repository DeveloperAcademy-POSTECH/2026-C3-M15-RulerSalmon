//
//  FourLService.swift
//  Retrospective-Rulersalmon
//
//  Created by dlsundn on 6/3/26.
//

import Foundation
import NaturalLanguage

struct FourLClassificationResult: Identifiable, Equatable {
    let id = UUID()
    let messageId: UUID
    let text: String
    let label: String
    let confidence: Double
    let fourLConfidence: Double
    let secondaryLabel: String?
    let secondaryConfidence: Double?
    let isFourLRelated: Bool
    let date: Date
}

final class FourLService {
    static let fourLLabels = ["Liked", "Learned", "Lacked", "Longed for"]
    static let unclearLabel = "Unclear"
    static let extraLabel = "Extra"
    static let emptyFallback = FourLService(model: nil)

    private let model: NLModel?
    private let chunker: SentenceChunkerService
    private let fourLThreshold: Double
    private let secondaryThreshold: Double
    private let secondaryMargin: Double

    init(
        fourLThreshold: Double = 0.8,
        secondaryThreshold: Double = 0.2,
        secondaryMargin: Double = 0.15,
        chunker: SentenceChunkerService = SentenceChunkerService()
    ) throws {
        guard let modelURL = Bundle.main.url(forResource: "FourLClassifier", withExtension: "mlmodelc") else {
            throw FourLServiceError.modelNotFound
        }

        self.model = try NLModel(contentsOf: modelURL)
        self.chunker = chunker
        self.fourLThreshold = fourLThreshold
        self.secondaryThreshold = secondaryThreshold
        self.secondaryMargin = secondaryMargin
    }

    private init(model: NLModel?) {
        self.model = model
        self.chunker = SentenceChunkerService()
        self.fourLThreshold = 0.8
        self.secondaryThreshold = 0.2
        self.secondaryMargin = 0.15
    }

    func classify(messages: [ChatMessage]) async -> [FourLClassificationResult] {
        let chunks = await chunker.semanticChunks(from: messages)

        return chunks.map { chunk in
            classify(chunk: chunk)
        }
    }

    func classify(
        text: String,
        messageId: UUID = UUID(),
        date: Date = .now
    ) async -> [FourLClassificationResult] {
        let message = ChatMessage(role: .user, text: text)
        let chunks = await chunker.semanticChunks(from: [message])

        return chunks.map { chunk in
            classify(chunk: SentenceChunk(messageId: messageId, text: chunk.text, date: date))
        }
    }

    func topResultsByFourL(from results: [FourLClassificationResult], limit: Int = 2) -> [String: [FourLClassificationResult]] {
        Dictionary(grouping: results.filter(\.isFourLRelated), by: \.label)
            .mapValues { items in
                Array(items.sorted { $0.confidence > $1.confidence }.prefix(limit))
            }
    }

    private func classify(chunk: SentenceChunk) -> FourLClassificationResult {
        let hypotheses = model?.predictedLabelHypotheses(for: chunk.text, maximumCount: 5) ?? [:]
        let fourLScores = Self.fourLLabels.map { label in
            (label: label, confidence: hypotheses[label] ?? 0)
        }
        .sorted { $0.confidence > $1.confidence }

        let fourLConfidence = fourLScores.reduce(0) { $0 + $1.confidence }
        let primary = fourLScores.first ?? (label: Self.unclearLabel, confidence: 0)
        let secondary = fourLScores.dropFirst().first
        let isFourLRelated = fourLConfidence >= fourLThreshold
        let shouldShowSecondary = isFourLRelated
            && (secondary?.confidence ?? 0) >= secondaryThreshold
            && primary.confidence - (secondary?.confidence ?? 0) <= secondaryMargin

        return FourLClassificationResult(
            messageId: chunk.messageId,
            text: chunk.text,
            label: isFourLRelated ? primary.label : Self.unclearLabel,
            confidence: isFourLRelated ? primary.confidence : (hypotheses[Self.extraLabel] ?? max(0, 1 - fourLConfidence)),
            fourLConfidence: fourLConfidence,
            secondaryLabel: shouldShowSecondary ? secondary?.label : nil,
            secondaryConfidence: shouldShowSecondary ? secondary?.confidence : nil,
            isFourLRelated: isFourLRelated,
            date: chunk.date
        )
    }
}

enum FourLServiceError: LocalizedError {
    case modelNotFound

    var errorDescription: String? {
        switch self {
        case .modelNotFound:
            return "FourLClassifier 모델을 찾을 수 없습니다."
        }
    }
}
