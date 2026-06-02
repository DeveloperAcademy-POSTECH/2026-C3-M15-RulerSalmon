import Foundation
import SwiftUI

@MainActor
final class TTSViewModel: ObservableObject {
    @Published var inputText: String = "안녕하세요. 이것은 MeloTTS 커스텀 보이스 데모야."
    @Published var mode: TTSMode = .remote
    @Published var isSynthesizing: Bool = false
    @Published var statusMessage: String?
    @Published var errorMessage: String?

    private let remoteService = RemoteTTSService()
    private let localService = LocalONNXTTSService()
    private let audioPlayer = AudioPlayer()
    private let voicePackManager = VoicePackManager()

    func synthesize() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        errorMessage = nil
        statusMessage = "음성을 준비하는 중이야."
        isSynthesizing = true

        Task {
            do {
                let url: URL
                switch mode {
                case .remote:
                    url = try await remoteService.synthesize(text: text, voiceId: voicePackManager.defaultVoiceID)
                case .local:
                    let voicePack = try voicePackManager.loadPlaceholderVoicePack()
                    url = try await localService.synthesize(text: text, voicePack: voicePack)
                }

                try audioPlayer.play(fileURL: url)
                statusMessage = "재생을 시작했어."
            } catch {
                errorMessage = error.localizedDescription
                statusMessage = nil
            }
            isSynthesizing = false
        }
    }
}

enum TTSMode {
    case remote
    case local
}
