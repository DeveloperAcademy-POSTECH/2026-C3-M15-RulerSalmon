//
//  ReflectionRAGPipeline.swift
//  Retrospective-Rulersalmon
//
//  Created by DevPaul on 6/6/26.
//

import Foundation

@MainActor
final class ReflectionRAGPipeline {
    private let fourLService: FourLService
    private let memoryStore: ReflectionMemoryStore
    private let queryBuilder = ReflectionQueryBuilder()
    private let contextRetriever = ReflectionContextRetriever()
    private let turnGenerator = ReflectionTurnGenerator()
    private let memoryBuilder = ReflectionMemoryBuilder()
    private let sessionID = UUID()
    private var assistantQuestionHistory: [String] = []

    init(
        fourLService: FourLService? = nil,
        memoryStore: ReflectionMemoryStore = ReflectionMemoryStore()
    ) {
        if let fourLService {
            self.fourLService = fourLService
        } else if let liveService = try? FourLService() {
            self.fourLService = liveService
        } else {
            self.fourLService = FourLService.emptyFallback
        }
        self.memoryStore = memoryStore
    }

    func handleUserInput(_ userText: String) async -> ReflectionRAGPipelineOutput {
        let createdAt = Date()
        print("[RAG][Input] \(userText)")

        let firstPassResults = fourLService.classify(
            text: userText,
            messageId: UUID(),
            date: createdAt
        )
        debugPrintFirstPassResults(firstPassResults)

        let contextQuery = queryBuilder.makeContextQuery(
            currentText: userText,
            firstPassResults: firstPassResults
        )
        let analysisContext = contextRetriever.retrieve(
            query: contextQuery,
            entries: memoryStore.allEntries()
        )
        let sessionContext = contextRetriever.retrieve(
            query: contextQuery,
            entries: memoryStore.entries(in: sessionID)
        )

        let generatedTurn = await turnGenerator.generateTurn(
            userText: userText,
            firstPassResults: firstPassResults,
            analysisContext: analysisContext,
            sessionContext: sessionContext,
            recentQuestions: Array(assistantQuestionHistory.suffix(3))
        )
        let validation = generatedTurn.validation
        debugPrintValidation(validation)

        let memoryEntry = memoryBuilder.build(
            sessionID: sessionID,
            userText: userText,
            validation: validation,
            createdAt: createdAt
        )
        memoryStore.append(memoryEntry)
        assistantQuestionHistory.append(generatedTurn.question)
        debugPrintFourLCoverage(with: validation)

        return ReflectionRAGPipelineOutput(
            question: generatedTurn.question,
            validation: validation,
            firstPassResults: firstPassResults
        )
    }

    private func debugPrintFirstPassResults(_ results: [FourLClassificationResult]) {
        if results.isEmpty {
            print("[RAG][FourL][FirstPass] no sentence chunks classified")
            return
        }

        print("[RAG][FourL][FirstPass] classified \(results.count) chunk(s)")
        for result in results {
            let secondary = result.secondaryLabel.map { " secondary=\($0)@\(String(format: "%.2f", result.secondaryConfidence ?? 0))" } ?? ""
            print(
                "[RAG][FourL][FirstPass] text=\"\(result.text)\" primary=\(result.label) confidence=\(String(format: "%.2f", result.confidence)) fourLTotal=\(String(format: "%.2f", result.fourLConfidence))\(secondary)"
            )
        }
    }

    private func debugPrintValidation(_ validation: ReflectionSecondPassValidation) {
        let dimensions = validation.verifiedDimensions.map(\.rawValue).joined(separator: ", ")
        print("[RAG][FourL][SecondPass] primary=\(validation.primaryDimension?.rawValue ?? "none") dimensions=[\(dimensions)] confidence=\(String(format: "%.2f", validation.confidence))")
        print("[RAG][FourL][SecondPass] summary=\(validation.summary)")
        print("[RAG][FourL][SecondPass] evidence=\(validation.evidence)")
    }

    private func debugPrintFourLCoverage(with validation: ReflectionSecondPassValidation) {
        let currentEntries = memoryStore.entries(in: sessionID)
        var counts: [ReflectionDimension: Int] = [:]

        for dimension in ReflectionDimension.allCases {
            counts[dimension] = 0
        }

        for entry in currentEntries {
            for dimension in entry.dimensionHints {
                counts[dimension, default: 0] += 1
            }
        }

        let coverage = ReflectionDimension.allCases.map { dimension in
            "\(dimension.rawValue)=\(counts[dimension, default: 0])"
        }
        .joined(separator: " ")

        print("[RAG][FourL][Coverage] sessionEntries=\(currentEntries.count) latestPrimary=\(validation.primaryDimension?.rawValue ?? "none") \(coverage)")
    }
}
