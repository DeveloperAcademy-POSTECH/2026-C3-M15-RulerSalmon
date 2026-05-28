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
        ChatMessage(role: .assistant, text: "회고를 말하거나 아래 입력창에 직접 적어주세요.")
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

    private var lastAIQuestionAt: Date = .distantPast

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
        commitChunk(text)
    }

    private func handlePartialText(_ partialText: String) {
        liveTranscript = partialText
        utteranceBuffer.update(partialText: partialText) { [weak self] committedChunk in
            self?.commitChunk(committedChunk)
        }
    }

    private func commitChunk(_ text: String) {
        let now = Date()
        let chunk = chunkAnalyzer.makeChunk(from: text, startedAt: now, endedAt: now)
        let analysis = chunkAnalyzer.analyze(chunk)

        chunks.append(chunk)
        analyses.append(analysis)
        messages.append(ChatMessage(role: .user, text: chunk.cleanedText))

        reflectionState = stateTracker.apply(analysis, to: reflectionState)

        let decision = interventionDecider.decide(
            state: reflectionState,
            timeSinceLastAIQuestion: Date().timeIntervalSince(lastAIQuestionAt)
        )

        guard decision.shouldIntervene, let target = decision.targetDimension else {
            liveTranscript = ""
            return
        }

        let question = questionGenerator.generateQuestion(for: target, state: reflectionState)
        reflectionState.askedQuestions.append(question)
        lastAIQuestionAt = .now
        activeQuestion = question
        messages.append(ChatMessage(role: .assistant, text: question))
        liveTranscript = ""
    }

    var likedProgressText: String {
        progressText(for: reflectionState.liked)
    }

    var learnedProgressText: String {
        progressText(for: reflectionState.learned)
    }

    var lackedProgressText: String {
        progressText(for: reflectionState.lacked)
    }

    var longedForProgressText: String {
        progressText(for: reflectionState.longedFor)
    }

    private func progressText(for slot: ReflectionSlot) -> String {
        let percentage = Int((slot.confidence * 100).rounded())
        return "\(percentage)%"
    }
}
