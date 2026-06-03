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
    @Published var inputText: String = ""
    @Published var messages: [ChatMessage] = [
        ChatMessage(role: .assistant, text: "좋아, 오늘 회고를 같이 정리해보자. 이번 경험에서 제일 먼저 떠오르는 장면부터 편하게 말해줘.")
    ]
    @Published var chunks: [ReflectionChunk] = []
    @Published var analyses: [ChunkAnalysis] = []
    @Published var reflectionState: ReflectionState = .empty
    @Published var isResponding: Bool = false
    @Published var alertMessage: String?

    private let chunkAnalyzer = ReflectionChunkAnalyzer()
    private let stateTracker = ReflectionStateTracker()
    private let interventionDecider = InterventionDecider()
    private let questionGenerator = FollowUpQuestionGenerator()
    private let contextRetriever = ReflectionContextRetriever()

    private var lastAIQuestionAt: Date = .distantPast
    private var hasDeliveredClosingMessage: Bool = false
    private var memoryEntries: [ReflectionMemoryEntry] = []

    func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        inputText = ""
        Task {
            await processUserMessage(text)
        }
    }

    private func processUserMessage(_ text: String) async {
        let now = Date()
        let chunk = chunkAnalyzer.makeChunk(from: text, startedAt: now, endedAt: now)

        guard !chunk.cleanedText.isEmpty else { return }

        hasDeliveredClosingMessage = false
        messages.append(ChatMessage(role: .user, text: chunk.cleanedText))

        let analysisContext = contextRetriever.retrieveForAnalysis(
            currentText: chunk.cleanedText,
            entries: memoryEntries
        )
        let analysis = await chunkAnalyzer.analyze(
            chunk,
            retrievedContext: analysisContext
        )
        chunks.append(chunk)
        analyses.append(analysis)
        reflectionState = stateTracker.apply(analysis, to: reflectionState)
        memoryEntries.append(makeMemoryEntry(from: chunk, analysis: analysis))

        await generateAssistantMessage(using: analysis)
    }

    private func generateAssistantMessage(using analysis: ChunkAnalysis?) async {
        let now = Date()
        let timeSinceLastQuestion = max(now.timeIntervalSince(lastAIQuestionAt), 2.0)
        let interventionDecision = interventionDecider.decide(
            state: reflectionState,
            timeSinceLastAIQuestion: timeSinceLastQuestion,
            timeSinceLastUserChunk: 2.0,
            isUserSpeaking: false,
            isTurnEnded: true
        )

        let retrievedContext = contextRetriever.retrieveForQuestion(
            targetDimension: interventionDecision.targetDimension,
            state: reflectionState,
            analysis: analysis,
            entries: memoryEntries
        )

        isResponding = true
        let nextMessage = await questionGenerator.generateNextMessage(
            state: reflectionState,
            analysis: analysis,
            interventionDecision: interventionDecision,
            retrievedContext: retrievedContext
        )
        isResponding = false

        switch nextMessage {
        case .none:
            return

        case .followUp(let target, let question):
            reflectionState = stateTracker.recordQuestion(for: target, in: reflectionState)
            reflectionState.askedQuestions.append(question)
            lastAIQuestionAt = .now
            messages.append(ChatMessage(role: .assistant, text: question))

        case .closing(let closingText):
            guard !hasDeliveredClosingMessage else { return }
            hasDeliveredClosingMessage = true
            lastAIQuestionAt = .now
            reflectionState.askedQuestions.append(closingText)
            messages.append(ChatMessage(role: .assistant, text: closingText))
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
