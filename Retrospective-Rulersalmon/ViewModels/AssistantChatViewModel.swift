//
//  AssistantChatViewModel.swift
//  Retrospective-Rulersalmon
//
//  Created by DevPaul on 5/21/26.
//

import Foundation
import Combine
import Speech

@MainActor
final class AssistantChatViewModel: ObservableObject {
    @Published var inputText: String = ""
    @Published var messages: [ChatMessage] = [
        ChatMessage(role: .assistant, text: "텍스트를 입력하거나 마이크 버튼을 눌러 대화를 시작해보세요.")
    ]
    @Published var isRecording: Bool = false
    @Published var isResponding: Bool = false
    @Published var alertMessage: String?

    private let foundationModelService: FoundationModelServicing
    private let speechRecognitionService: SpeechRecognitionService

    init(
        foundationModelService: FoundationModelServicing? = nil,
        speechRecognitionService: SpeechRecognitionService? = nil
    ) {
        self.foundationModelService = foundationModelService ?? FoundationModelService()
        self.speechRecognitionService = speechRecognitionService ?? SpeechRecognitionService()
    }

    func sendCurrentText() {
        let prompt = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty else { return }

        inputText = ""
        messages.append(ChatMessage(role: .user, text: prompt))
        Task {
            await respond(to: prompt)
        }
    }

    func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            Task {
                await startRecording()
            }
        }
    }

    private func startRecording() async {
        do {
            let status = await speechRecognitionService.requestAuthorization()
            guard status == .authorized else {
                alertMessage = "음성 인식 권한이 필요합니다."
                return
            }

            try await speechRecognitionService.startRecording { [weak self] partialText in
                self?.inputText = partialText
            }
            isRecording = true
        } catch {
            alertMessage = error.localizedDescription
        }
    }

    private func stopRecording() {
        speechRecognitionService.stopRecording()
        isRecording = false
    }

    private func respond(to prompt: String) async {
        isResponding = true
        defer { isResponding = false }

        do {
            let response = try await foundationModelService.respond(to: prompt)
            messages.append(ChatMessage(role: .assistant, text: response))
        } catch {
            let fallback = "응답을 생성하지 못했어요. 다시 시도해 주세요."
            messages.append(ChatMessage(role: .assistant, text: fallback))
            alertMessage = error.localizedDescription
        }
    }
}
