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

    func loadMockConversation() {
        messages = [
            ChatMessage(role: .assistant, text: "텍스트를 입력하거나 마이크 버튼을 눌러 대화를 시작해보세요."),
            ChatMessage(role: .user, text: "오늘 C3 챌린지에서 내가 만든 4L 분류 모델을 실제 앱 흐름에 붙여볼 수 있어서 뿌듯했어"),
            ChatMessage(role: .user, text: "처음에는 시뮬레이터에서 모델 예측이 계속 실패해서 당황했지만, 실기기에서는 정상적으로 동작한다는 걸 확인해서 안심했어"),
            ChatMessage(role: .user, text: "Create ML 모델의 label만 보는 것보다 confidence를 함께 확인해야 결과를 더 믿고 사용할 수 있다는 걸 배웠어"),
            ChatMessage(role: .user, text: "4L 결과 화면에서 원본 문장과 Foundation Model로 정제한 문장을 비교해보니 사용자가 읽기 좋은 표현이 중요하다는 걸 느꼈어"),
            ChatMessage(role: .user, text: "프로젝트를 진행하면서 팀원들과 소통이 잘되어 좋았고, Action Item 기준을 같이 논의할 수 있어서 든든했어"),
            ChatMessage(role: .user, text: "아직 온보딩 뷰와 홈뷰가 완성되지 않아서 전체 앱 경험이 자연스럽게 이어지지 않는 점은 아쉬웠어"),
            ChatMessage(role: .user, text: "오늘 기능을 많이 붙였지만 코드가 빠르게 늘어나서 PR을 작게 나누는 방법도 고민해야겠다고 느꼈"),
            ChatMessage(role: .user, text: "내일은 온보딩 뷰와 홈뷰를 완성하고, Longed for 문장을 기반으로 Action Item을 더 안정적으로 보여주고 싶어"),
            ChatMessage(role: .user, text: "내일 팀원들과 회의할 때 Action Item을 Longed for에서 도출하는 기준이 적절한지 논의해볼 거예"),
            ChatMessage(role: .user, text: "과연 제가 이 흐름을 끝까지 잘 완성할 수 있을지 걱정이 되지만, 오늘 확인한 결과를 바탕으로 계속 다듬어보고 싶어"),
            ChatMessage(role: .user, text: "점심에는 도시락을 먹었고 오후에는 조금 피곤했어"),
            ChatMessage(role: .user, text:
                        """
                        오늘은 4L 분류 결과 화면을 보면서 생각보다 흐름이 잘 이어져서 조금 안심했다
                        근데 문장이 길어지면 어디까지가 하나의 생각인지 나도 헷갈렸고, 모델이 그걸 잘 나눠줄지도 아직 확신이 없다
                        Foundation Model로 정제된 문장은 읽기 편했지만, 가끔 내가 말하지 않은 느낌까지 들어가는 것 같아서 조심해야겠다고 느꼈다
                        내일은 온보딩 뷰를 끝까지 연결하고, 홈뷰에서 회고로 넘어가는 흐름도 자연스럽게 만들고 싶다
                        Action Item은 Longed for에서만 뽑는 방식이 더 정확해 보였는데, 그래도 너무 적게 나오면 사용자 입장에서 아쉬울 수도 있을 것 같다
                        오늘 PR에 넣을 범위를 정리하면서 기능을 작게 나누는 게 생각보다 중요하다는 걸 배웠다
                        아직 결과 화면의 디자인은 조금 딱딱해 보여서, 사용자가 회고를 읽을 때 부담이 덜한 형태로 다듬고 싶다.
                        """)
        ]
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
