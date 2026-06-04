//
//  ReflectionChatViewModel.swift
//  Retrospective-Rulersalmon
//
//  Created by DevPaul on 6/2/26.
//

import Foundation
import Combine

@MainActor
final class ReflectionChatViewModel: ObservableObject {
    private enum ScrollAnchor: String {
        case responding
    }

    @Published var inputText: String = ""
    @Published var messages: [ChatMessage] = [
        ChatMessage(role: .assistant, text: "좋아, 오늘 회고를 같이 정리해보자. 이번 경험에서 제일 먼저 떠오르는 장면부터 편하게 말해줘.")
    ]
    @Published var chunks: [ReflectionChunk] = []
    @Published var analyses: [ChunkAnalysis] = []
    @Published var reflectionState: ReflectionState = .empty
    @Published var isResponding: Bool = false
    @Published var alertMessage: String?
    @Published var scrollTargetID: String?

    private let chunkAnalyzer = ReflectionChunkAnalyzer()
    private let stateTracker = ReflectionStateTracker()
    private let interventionDecider = InterventionDecider()
    private let questionGenerator = FollowUpQuestionGenerator()
    private let contextRetriever = ReflectionContextRetriever()
    private let queryBuilder = ReflectionQueryBuilder()
    private let questionPolicyService = QuestionPolicyService()
    private let fourLService: FourLService
    private let fourLTurnContextBuilder = FourLTurnContextBuilder()

    private var lastAIQuestionAt: Date = .distantPast
    private var hasDeliveredClosingMessage: Bool = false
    private var memoryEntries: [ReflectionMemoryEntry] = []

    init(fourLService: FourLService? = nil) {
        if let fourLService {
            self.fourLService = fourLService
        } else if let liveService = try? FourLService() {
            self.fourLService = liveService
        } else {
            self.fourLService = FourLService.emptyFallback
        }
    }

    func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        inputText = ""
        isResponding = true
        Task {
            await processUserMessage(text)
        }
    }

    private func processUserMessage(_ text: String) async {
        let now = Date()
        let chunk = chunkAnalyzer.makeChunk(from: text, startedAt: now, endedAt: now)

        guard !chunk.cleanedText.isEmpty else {
            isResponding = false
            return
        }

        hasDeliveredClosingMessage = false
        let userMessage = ChatMessage(role: .user, text: chunk.cleanedText)
        messages.append(userMessage)
        scrollTargetID = userMessage.id.uuidString

        let classificationResults = fourLService.classify(text: chunk.cleanedText, date: now)
        print("[FourLClassifier] classified \(classificationResults.count) sentence(s)")
        let turnFourLAnalysis = fourLTurnContextBuilder.build(from: classificationResults)

        let analysisQuery = queryBuilder.makeAnalysisQuery(currentText: chunk.cleanedText)
        let analysisContext = contextRetriever.retrieve(
            query: analysisQuery,
            entries: memoryEntries
        )
        let analysis = await chunkAnalyzer.analyze(
            chunk,
            turnFourLAnalysis: turnFourLAnalysis,
            retrievedContext: analysisContext
        )
        chunks.append(chunk)
        analyses.append(analysis)
        reflectionState = stateTracker.apply(analysis, to: reflectionState)
        debugPrintReflectionState(after: analysis)
        memoryEntries.append(makeMemoryEntry(from: chunk, analysis: analysis))

        await generateAssistantMessage(using: analysis, turnFourLAnalysis: turnFourLAnalysis)
    }

    private func generateAssistantMessage(
        using analysis: ChunkAnalysis?,
        turnFourLAnalysis: TurnFourLAnalysis
    ) async {
        scrollTargetID = ScrollAnchor.responding.rawValue
        let now = Date()
        let timeSinceLastQuestion = max(now.timeIntervalSince(lastAIQuestionAt), 2.0)
        let interventionDecision = interventionDecider.decide(
            state: reflectionState,
            timeSinceLastAIQuestion: timeSinceLastQuestion,
            timeSinceLastUserChunk: 2.0,
            isUserSpeaking: false,
            isTurnEnded: true
        )

        let policy = questionPolicyService.makePolicy(
            state: reflectionState,
            analysis: analysis,
            turnFourLAnalysis: turnFourLAnalysis,
            interventionDecision: interventionDecision
        )
        let questionQuery = queryBuilder.makeQuestionQuery(
            state: reflectionState,
            analysis: analysis,
            turnFourLAnalysis: turnFourLAnalysis,
            policy: policy
        )
        let retrievedContext = contextRetriever.retrieve(
            query: questionQuery,
            entries: memoryEntries
        )

        let nextMessage = await questionGenerator.generateNextMessage(
            state: reflectionState,
            analysis: analysis,
            turnFourLAnalysis: turnFourLAnalysis,
            interventionDecision: interventionDecision,
            policy: policy,
            retrievedContext: retrievedContext
        )
        defer { isResponding = false }

        switch nextMessage {
        case .none:
            return

        case .followUp(let target, let question):
            reflectionState = stateTracker.recordQuestion(for: target, in: reflectionState)
            reflectionState.askedQuestions.append(question)
            lastAIQuestionAt = .now
            let assistantMessage = ChatMessage(role: .assistant, text: question)
            messages.append(assistantMessage)
            scrollTargetID = assistantMessage.id.uuidString

        case .closing(let closingText):
            guard !hasDeliveredClosingMessage else { return }
            hasDeliveredClosingMessage = true
            lastAIQuestionAt = .now
            reflectionState.askedQuestions.append(closingText)
            let assistantMessage = ChatMessage(role: .assistant, text: closingText)
            messages.append(assistantMessage)
            scrollTargetID = assistantMessage.id.uuidString
        }
    }

    var likedProgressText: String {
        progressText(for: reflectionState.liked)
    }

    var likedFidelityText: String {
        fidelityText(for: reflectionState.liked)
    }

    var learnedProgressText: String {
        progressText(for: reflectionState.learned)
    }

    var learnedFidelityText: String {
        fidelityText(for: reflectionState.learned)
    }

    var lackedProgressText: String {
        progressText(for: reflectionState.lacked)
    }

    var lackedFidelityText: String {
        fidelityText(for: reflectionState.lacked)
    }

    var longedForProgressText: String {
        progressText(for: reflectionState.longedFor)
    }

    var longedForFidelityText: String {
        fidelityText(for: reflectionState.longedFor)
    }

    private func debugPrintReflectionState(after analysis: ChunkAnalysis) {
        print("[4LState] detected=\(analysis.detectedDimensions.map(\.rawValue)) primary=\(analysis.primaryDimension?.rawValue ?? "none")")
        print("[4LState][liked] confidence=\(likedProgressText) fidelity=\(likedFidelityText) summary=\(reflectionState.liked.summary ?? "없음") evidence=\(reflectionState.liked.evidence)")
        print("[4LState][learned] confidence=\(learnedProgressText) fidelity=\(learnedFidelityText) summary=\(reflectionState.learned.summary ?? "없음") evidence=\(reflectionState.learned.evidence)")
        print("[4LState][lacked] confidence=\(lackedProgressText) fidelity=\(lackedFidelityText) summary=\(reflectionState.lacked.summary ?? "없음") evidence=\(reflectionState.lacked.evidence)")
        print("[4LState][longedFor] confidence=\(longedForProgressText) fidelity=\(longedForFidelityText) summary=\(reflectionState.longedFor.summary ?? "없음") evidence=\(reflectionState.longedFor.evidence)")
    }

    private func progressText(for slot: ReflectionSlot) -> String {
        let percentage = Int((slot.confidence * 100).rounded())
        return "\(percentage)%"
    }

    private func fidelityText(for slot: ReflectionSlot) -> String {
        let percentage = Int((slot.fidelity * 100).rounded())
        return "\(percentage)%"
    }

    private func makeMemoryEntry(
        from chunk: ReflectionChunk,
        analysis: ChunkAnalysis
    ) -> ReflectionMemoryEntry {
        ReflectionMemoryEntry(
            text: chunk.cleanedText,
            summary: analysis.summary,
            dimensionHints: analysis.detectedDimensions,
            keywords: analysis.keywords,
            evidence: analysis.evidence,
            createdAt: chunk.endedAt
        )
    }
}
