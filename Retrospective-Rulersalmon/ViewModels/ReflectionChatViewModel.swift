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
        ChatMessage(role: .assistant, text: "좋아, 오늘 회고를 같이 정리해보자. 먼저 떠오르는 장면부터 편하게 말해줘.")
    ]
    @Published var isResponding: Bool = false
    @Published var alertMessage: String?
    @Published var scrollTargetID: String?

    private let ragPipeline: ReflectionRAGPipeline
    private var hasRequestedWarmUp = false

    init(ragPipeline: ReflectionRAGPipeline) {
        self.ragPipeline = ragPipeline
    }

    convenience init() {
        self.init(ragPipeline: ReflectionRAGPipeline())
    }

    func prepareFoundationModelIfNeeded() {
        guard !hasRequestedWarmUp else { return }
        hasRequestedWarmUp = true

        Task {
            await ragPipeline.warmUpFoundationModelIfNeeded()
        }
    }

    func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        inputText = ""
        isResponding = true

        let userMessage = ChatMessage(role: .user, text: text)
        messages.append(userMessage)
        scrollTargetID = userMessage.id.uuidString

        Task {
            await processUserMessage(text)
        }
    }

    private func processUserMessage(_ text: String) async {
        defer { isResponding = false }
        scrollTargetID = ScrollAnchor.responding.rawValue

        do {
            let output = await ragPipeline.handleUserInput(text)
            let assistantMessage = ChatMessage(role: .assistant, text: output.question)
            messages.append(assistantMessage)
            scrollTargetID = assistantMessage.id.uuidString
        } catch {
            alertMessage = "질문을 준비하는 중 문제가 생겼어요. 잠시 후 다시 시도해주세요."
        }
    }
}
