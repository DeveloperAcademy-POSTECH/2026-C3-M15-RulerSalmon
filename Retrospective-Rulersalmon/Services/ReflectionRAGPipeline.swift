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
    private let completionEvaluator = ReflectionCompletionEvaluator()
    private let memoryBuilder = ReflectionMemoryBuilder()
    private let dataStore: AppDataStore
    private let sessionID: UUID
    private let mentor: Mentor?
    private var assistantQuestionHistory: [String] = []
    private var previousCompletionState: ReflectionCompletionState = .continueExploring
    private var isConversationClosed = false

    init(
        fourLService: FourLService? = nil,
        memoryStore: ReflectionMemoryStore? = nil,
        dataStore: AppDataStore? = nil,
        sessionID: UUID = UUID(),
        mentor: Mentor? = nil
    ) {
        if let fourLService {
            self.fourLService = fourLService
        } else if let liveService = try? FourLService() {
            self.fourLService = liveService
        } else {
            self.fourLService = FourLService.emptyFallback
        }
        self.dataStore = dataStore ?? .shared
        self.memoryStore = memoryStore ?? ReflectionMemoryStore()
        self.sessionID = sessionID
        self.mentor = mentor
        self.dataStore.createReflectionSessionIfNeeded(id: sessionID, mentorName: mentor?.name)
    }

    func handleUserInput(_ userText: String) async -> ReflectionRAGPipelineOutput {
        let createdAt = Date()
        print("[RAG][Input] \(userText)")

        if isConversationClosed {
            let validation = makeTerminalValidation(from: userText, summary: "이미 회고가 마무리된 상태에서 추가 입력이 들어옴")
            let decision = ReflectionCompletionDecision(
                state: .completed,
                coveredDimensions: [],
                sessionEntryCount: memoryStore.entries(in: sessionID).count,
                newKeywordCount: 0,
                averageConfidence: 1.0,
                reason: "이미 종료된 회고 세션"
            )

            return ReflectionRAGPipelineOutput(
                question: "오늘 회고는 이미 마무리됐어. 필요하면 새로 다시 시작해보자.",
                validation: validation,
                firstPassResults: [],
                completionDecision: decision,
                isConversationClosed: true
            )
        }

        if previousCompletionState == .askForClosure, isClosureConfirmed(userText) {
            let validation = makeTerminalValidation(from: userText, summary: "사용자가 회고 종료에 동의함")
            let decision = ReflectionCompletionDecision(
                state: .completed,
                coveredDimensions: currentCoveredDimensions(),
                sessionEntryCount: memoryStore.entries(in: sessionID).count,
                newKeywordCount: 0,
                averageConfidence: 1.0,
                reason: "사용자가 회고 종료에 명시적으로 동의함"
            )
            let closingMessage = "좋아, 오늘 회고는 여기서 마무리하자. 이야기해줘서 고마워."
            assistantQuestionHistory.append(closingMessage)
            previousCompletionState = .completed
            isConversationClosed = true
            memoryStore.clearEntries(in: sessionID)
            dataStore.updateReflectionSession(
                id: sessionID,
                firstUserMessage: nil,
                latestSummary: validation.summary,
                isClosed: true
            )
            print("[RAG][Completion] conversation closed by user confirmation")

            return ReflectionRAGPipelineOutput(
                question: closingMessage,
                validation: validation,
                firstPassResults: [],
                completionDecision: decision,
                isConversationClosed: true
            )
        }

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
        let currentSessionEntries = memoryStore.entries(in: sessionID)
        let analysisContext = contextRetriever.retrieve(
            query: contextQuery,
            entries: currentSessionEntries
        )
        let sessionContext = contextRetriever.retrieve(
            query: contextQuery,
            entries: currentSessionEntries
        )
        let completionDecision = completionEvaluator.evaluate(
            entries: currentSessionEntries,
            candidateDimensions: firstPassResults.compactMap { mapLabelToDimension($0.label) },
            candidateKeywords: contextQuery.keywords + extractKeywords(from: userText),
            candidateConfidence: firstPassResults.first?.confidence ?? 0.45,
            previousState: previousCompletionState
        )
        debugPrintCompletionDecision(completionDecision)

        let generatedTurn = await turnGenerator.generateTurn(
            userText: userText,
            firstPassResults: firstPassResults,
            analysisContext: analysisContext,
            sessionContext: sessionContext,
            recentQuestions: Array(assistantQuestionHistory.suffix(3)),
            completionState: completionDecision.state
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
        previousCompletionState = completionDecision.state
        dataStore.updateReflectionSession(
            id: sessionID,
            firstUserMessage: userText,
            latestSummary: validation.summary,
            isClosed: false
        )
        debugPrintFourLCoverage(with: validation)

        return ReflectionRAGPipelineOutput(
            question: generatedTurn.question,
            validation: validation,
            firstPassResults: firstPassResults,
            completionDecision: completionDecision,
            isConversationClosed: false
        )
    }

    func warmUpFoundationModelIfNeeded() async {
        await turnGenerator.warmUpIfNeeded()
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

    private func debugPrintCompletionDecision(_ decision: ReflectionCompletionDecision) {
        let dimensions = decision.coveredDimensions.map(\.rawValue).joined(separator: ", ")
        print("[RAG][Completion] state=\(decision.state.rawValue) covered=[\(dimensions)] entries=\(decision.sessionEntryCount) newKeywords=\(decision.newKeywordCount) avgConfidence=\(String(format: "%.2f", decision.averageConfidence))")
        print("[RAG][Completion] reason=\(decision.reason)")
    }

    private func mapLabelToDimension(_ label: String) -> ReflectionDimension? {
        switch label {
        case "Liked": return .liked
        case "Learned": return .learned
        case "Lacked": return .lacked
        case "Longed for": return .longedFor
        default: return nil
        }
    }

    private func extractKeywords(from text: String) -> [String] {
        text
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.count >= 2 }
    }

    private func isClosureConfirmed(_ text: String) -> Bool {
        let normalized = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: " ", with: "")

        let confirmations = [
            "응", "네", "좋아", "그래", "맞아", "어", "웅",
            "마무리하자", "끝내자", "정리하자", "여기까지하자", "여기서마무리하자",
            "그만하자", "이제끝내자", "오늘은여기까지", "마무리할게", "끝낼게"
        ]

        return confirmations.contains { normalized == $0.lowercased().replacingOccurrences(of: " ", with: "") }
    }

    private func currentCoveredDimensions() -> [ReflectionDimension] {
        let covered = Set(memoryStore.entries(in: sessionID).flatMap(\.dimensionHints))
        return ReflectionDimension.allCases.filter { covered.contains($0) }
    }

    private func makeTerminalValidation(from userText: String, summary: String) -> ReflectionSecondPassValidation {
        ReflectionSecondPassValidation(
            summary: summary,
            verifiedDimensions: [],
            primaryDimension: nil,
            evidence: [userText],
            keywords: extractKeywords(from: userText),
            topic: nil,
            confidence: 1.0,
            reasoning: summary
        )
    }
}

struct ReflectionCompletionEvaluator {
    func evaluate(
        entries: [ReflectionMemoryEntry],
        candidateDimensions: [ReflectionDimension],
        candidateKeywords: [String],
        candidateConfidence: Double,
        previousState: ReflectionCompletionState
    ) -> ReflectionCompletionDecision {
        let existingDimensions = Set(entries.flatMap(\.dimensionHints))
        let combinedDimensions = existingDimensions.union(candidateDimensions)
        let coveredDimensions = ReflectionDimension.allCases.filter { combinedDimensions.contains($0) }

        let existingKeywords = Set(entries.flatMap(\.keywords).map(normalizeKeyword))
        let incomingKeywords = Set(candidateKeywords.map(normalizeKeyword)).filter { !$0.isEmpty }
        let newKeywordCount = incomingKeywords.subtracting(existingKeywords).count

        let entryCount = entries.count + 1
        let confidenceValues = entries.map(\.importance) + [candidateConfidence]
        let averageConfidence = confidenceValues.reduce(0, +) / Double(max(confidenceValues.count, 1))

        let enoughDimensions = coveredDimensions.count >= 3
        let enoughEntries = entryCount >= 4
        let enoughConfidence = averageConfidence >= 0.58
        let lowNovelty = newKeywordCount <= 1

        let state: ReflectionCompletionState
        let reason: String

        if enoughDimensions && enoughEntries && enoughConfidence {
            if previousState == .readyToWrapUp || (coveredDimensions.count == 4 && lowNovelty) {
                state = .askForClosure
                reason = "4L가 충분히 채워졌고 최근 새 정보가 많지 않아 종료 여부를 물을 수 있음"
            } else {
                state = .readyToWrapUp
                reason = "4L가 어느 정도 채워져 마무리 방향으로 유도할 수 있음"
            }
        } else {
            state = .continueExploring
            reason = "아직 4L 충족도 또는 정보량이 충분하지 않아 탐색을 이어가야 함"
        }

        return ReflectionCompletionDecision(
            state: state,
            coveredDimensions: coveredDimensions,
            sessionEntryCount: entryCount,
            newKeywordCount: newKeywordCount,
            averageConfidence: averageConfidence,
            reason: reason
        )
    }

    private func normalizeKeyword(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }
}
