//
//  ReflectionCallViewModel.swift
//  Retrospective-Rulersalmon
//
//  Created by DevPaul on 5/27/26.
//

import Foundation
import Combine
import Speech

@MainActor
final class ReflectionCallViewModel: ObservableObject {
    @Published var inputText: String = ""
    @Published var liveTranscript: String = ""
    @Published var messages: [ChatMessage] = [
        ChatMessage(role: .assistant, text: "좋아, 오늘 회고를 같이 해보자. 이번 경험에서 가장 기억에 남는 장면부터 편하게 말해줄래?")
    ]
    @Published var chunks: [SpeechChunk] = []
    @Published var analyses: [ChunkAnalysis] = []
    @Published var reflectionState: ReflectionState = .empty
    @Published var isRecording: Bool = false
    @Published var isResponding: Bool = false
    @Published var activeQuestion: String?
    @Published var alertMessage: String?

    private let speechRecognitionService: SpeechRecognitionService
    private let utteranceBuffer = UtteranceBuffer()
    private let chunkAnalyzer = ReflectionChunkAnalyzer()
    private let stateTracker = ReflectionStateTracker()
    private let interventionDecider = InterventionDecider()
    private let questionGenerator = FollowUpQuestionGenerator()
    private let turnEndDetector = TurnEndDetector()

    private var lastAIQuestionAt: Date = .distantPast
    private var lastUserChunkAt: Date = .distantPast
    private var lastPartialAt: Date = .distantPast
    private var turnEndRevision: Int = 0
    private var turnEndTask: Task<Void, Never>?
    private var hasDeliveredClosingMessage: Bool = false

    init(speechRecognitionService: SpeechRecognitionService? = nil) {
        self.speechRecognitionService = speechRecognitionService ?? SpeechRecognitionService()
    }

    func startSession() {
        Task {
            do {
                let status = await speechRecognitionService.requestAuthorization()
                guard status == .authorized else {
                    alertMessage = "음성 인식 권한이 필요합니다."
                    return
                }

                try await speechRecognitionService.startRecording { [weak self] partialText in
                    self?.handlePartialText(partialText)
                }

                isRecording = true
            } catch {
                alertMessage = error.localizedDescription
            }
        }
    }

    func stopSession() {
        speechRecognitionService.stopRecording()
        utteranceBuffer.reset()
        cancelTurnEndMonitor()
        isRecording = false
    }

    func toggleRecording() {
        if isRecording {
            stopSession()
        } else {
            startSession()
        }
    }

    func sendManualText() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        inputText = ""
        activeQuestion = nil
        Task {
            await commitChunk(text)
            await completeTurnIfNeeded(force: true)
        }
    }

    private func handlePartialText(_ partialText: String) {
        let now = Date()
        liveTranscript = partialText
        activeQuestion = nil
        lastPartialAt = now
        lastUserChunkAt = now
        scheduleTurnEndMonitor()
        utteranceBuffer.update(partialText: partialText) { [weak self] committedChunk in
            guard let self else { return }
            Task {
                await self.commitChunk(committedChunk)
            }
        }
    }

    private func commitChunk(_ text: String) async {
        let now = Date()
        let chunk = chunkAnalyzer.makeChunk(from: text, startedAt: now, endedAt: now)

        guard !chunk.cleanedText.isEmpty else {
            liveTranscript = ""
            return
        }

        hasDeliveredClosingMessage = false

        let analysis = await chunkAnalyzer.analyze(chunk)

        chunks.append(chunk)
        analyses.append(analysis)
        messages.append(ChatMessage(role: .user, text: chunk.cleanedText))

        reflectionState = stateTracker.apply(analysis, to: reflectionState)
        liveTranscript = ""
    }

    private func scheduleTurnEndMonitor() {
        turnEndRevision += 1
        let revision = turnEndRevision

        turnEndTask?.cancel()
        turnEndTask = Task { [weak self] in
            guard let self else { return }

            while !Task.isCancelled {
                do {
                    try await Task.sleep(nanoseconds: 350_000_000)
                } catch {
                    return
                }

                guard revision == self.turnEndRevision else {
                    return
                }

                let silence = Date().timeIntervalSince(self.lastPartialAt)
                let analysis = self.latestRelevantAnalysis()
                let transcript = self.currentTurnTranscript()
                let decision = self.turnEndDetector.decide(
                    transcript: transcript,
                    analysis: analysis,
                    silence: silence
                )

                guard decision.shouldEnd else {
                    continue
                }

                await self.completeTurnIfNeeded(force: false, decision: decision)
                return
            }
        }
    }

    private func cancelTurnEndMonitor() {
        turnEndRevision += 1
        turnEndTask?.cancel()
        turnEndTask = nil
    }

    private func completeTurnIfNeeded(
        force: Bool,
        decision: TurnEndDecision? = nil
    ) async {
        cancelTurnEndMonitor()

        let now = Date()
        let analysis = latestRelevantAnalysis()
        let transcript = currentTurnTranscript()
        let effectiveDecision = decision ?? turnEndDetector.decide(
            transcript: transcript,
            analysis: analysis,
            silence: now.timeIntervalSince(lastPartialAt)
        )

        guard force || effectiveDecision.shouldEnd else { return }

        let timeSinceLastUserChunk = now.timeIntervalSince(lastUserChunkAt)
        let interventionDecision = interventionDecider.decide(
            state: reflectionState,
            timeSinceLastAIQuestion: now.timeIntervalSince(lastAIQuestionAt),
            timeSinceLastUserChunk: timeSinceLastUserChunk,
            isUserSpeaking: false,
            isTurnEnded: true
        )

        isResponding = true
        let nextMessage = await questionGenerator.generateNextMessage(
            state: reflectionState,
            analysis: analysis,
            interventionDecision: interventionDecision
        )
        isResponding = false

        switch nextMessage {
        case .none:
            activeQuestion = nil
            liveTranscript = ""
            return

        case .followUp(let target, let question):
            reflectionState = stateTracker.recordQuestion(for: target, in: reflectionState)
            reflectionState.askedQuestions.append(question)
            lastAIQuestionAt = .now
            updateActiveQuestion(question)

        case .closing(let closingText):
            guard !hasDeliveredClosingMessage else {
                liveTranscript = ""
                return
            }

            hasDeliveredClosingMessage = true
            lastAIQuestionAt = .now
            updateActiveQuestion(closingText)
            reflectionState.askedQuestions.append(closingText)
        }

        liveTranscript = ""
    }

    private func latestRelevantAnalysis() -> ChunkAnalysis? {
        analyses.last(where: {
            $0.isMeaningful || !$0.detectedDimensions.isEmpty || !$0.summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }) ?? analyses.last
    }

    private func currentTurnTranscript() -> String {
        let currentTranscript = liveTranscript.trimmingCharacters(in: .whitespacesAndNewlines)
        if !currentTranscript.isEmpty {
            return currentTranscript
        }

        if let latestAnalysis = latestRelevantAnalysis() {
            return latestAnalysis.cleanedText
        }

        return reflectionState.lastUserChunk ?? ""
    }

    private func updateActiveQuestion(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            activeQuestion = nil
            return
        }

        if activeQuestion == trimmed {
            activeQuestion = nil
        }

        activeQuestion = trimmed
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
}
