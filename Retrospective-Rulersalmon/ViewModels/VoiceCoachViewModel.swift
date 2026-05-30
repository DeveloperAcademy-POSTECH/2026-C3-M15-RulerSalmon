import AVFoundation
import Combine
import Foundation
import UIKit

enum VoiceSlot: Int, CaseIterable, Identifiable {
    case one = 1
    case two = 2
    case three = 3

    var id: Int { rawValue }
    var title: String {
        switch self {
        case .one:
            "chaem"
        case .two:
            "cindy"
        case .three:
            "friday"
        }
    }
    var savedFileName: String { "voice-embedding-\(rawValue).json" }
    var bundledResourceName: String { "\(title).embedding" }
}

struct LatencyMetric: Identifiable {
    let id = UUID()
    let voiceName: String
    let characterCount: Int
    let synthesisTime: TimeInterval
    let firstPlaybackTime: TimeInterval
    let totalTime: TimeInterval
}

@MainActor
final class VoiceCoachViewModel: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    @Published var ttsText = ""
    @Published var statusText = "대기 중"
    @Published var voiceSampleStatus = "목소리 샘플 확인 중"
    @Published var selectedSlot: VoiceSlot = .one
    @Published var savedSlots: Set<VoiceSlot> = []
    @Published var isSpeaking = false
    @Published var isVoiceCloningAvailable = false
    @Published var latencyMetrics: [LatencyMetric] = []

    private var isAppActive = true

    private let synthesizer = AVSpeechSynthesizer()
    private let cosyVoice = CosyVoiceSpeechProvider()
    private let floatAudioPlayer = FloatAudioPlayer()
    private let maxInputCharacters = 80

    private var applicationSupportDirectory: URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return baseURL.appendingPathComponent("FourLVoiceCoach", isDirectory: true)
    }

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func prepare() {
        configureAudioSessionForPlayback()
        Task {
            isVoiceCloningAvailable = await cosyVoice.isAvailable
            reloadSavedSlots()

            guard isVoiceCloningAvailable else {
                voiceSampleStatus = "현재 빌드에서는 목소리 복제가 꺼져 있음"
                return
            }

            await loadSelectedSlot()
        }
    }

    func selectSlot(_ slot: VoiceSlot) {
        selectedSlot = slot
        Task {
            await loadSelectedSlot()
        }
    }

    func name(for slot: VoiceSlot) -> String {
        slot.title
    }

    var effectiveInputCharacterCount: Int {
        min(ttsText.trimmingCharacters(in: .whitespacesAndNewlines).count, maxInputCharacters)
    }

    func speakInputText() async {
        let text = ttsText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        await speak(String(text.prefix(maxInputCharacters)))
    }

    func stopSpeaking() {
        synthesizer.stopSpeaking(at: .immediate)
        floatAudioPlayer.stop()
        finishSpeaking(status: "대기 중")
    }

    func setAppActive(_ isActive: Bool) {
        isAppActive = isActive

        if !isActive {
            synthesizer.stopSpeaking(at: .immediate)
            floatAudioPlayer.stop()
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }

    private func loadSelectedSlot() async {
        await cosyVoice.clearVoiceSample()

        guard isVoiceCloningAvailable else {
            voiceSampleStatus = "현재 빌드에서는 목소리 복제가 꺼져 있음"
            return
        }

        do {
            guard let selectedEmbeddingURL = embeddingSourceURL(for: selectedSlot) else {
                throw CocoaError(.fileNoSuchFile)
            }
            try await cosyVoice.loadVoiceSample(from: selectedEmbeddingURL)
            voiceSampleStatus = "\(name(for: selectedSlot)) 사용 중"
        } catch {
            voiceSampleStatus = "\(name(for: selectedSlot))에 저장된 샘플 없음"
        }
    }

    private func speak(_ text: String) async {
        guard isAppActive && UIApplication.shared.applicationState == .active else {
            statusText = "앱이 활성화된 상태에서 다시 시도해 주세요"
            return
        }

        configureAudioSessionForPlayback()
        synthesizer.stopSpeaking(at: .immediate)
        floatAudioPlayer.stop()
        isSpeaking = true
        UIApplication.shared.isIdleTimerDisabled = true

        let voiceName = name(for: selectedSlot)
        statusText = "\(voiceName) 모델 로딩 중"

        do {
            guard await cosyVoice.hasVoiceSample else {
                statusText = "시스템 음성 응답 중"
                speakWithSystemVoice(text)
                return
            }

            let startedAt = Date()
            let samples = try await cosyVoice.synthesize(text: text)
            let synthesizedAt = Date()
            await cosyVoice.unloadModel()

            guard isAppActive && UIApplication.shared.applicationState == .active else {
                finishSpeaking(status: "대기 중")
                return
            }

            guard !samples.isEmpty else {
                throw CocoaError(.coderInvalidValue)
            }

            statusText = "\(voiceName)로 재생 중"
            let playbackStartedAt = Date()
            try floatAudioPlayer.play(samples: samples, sampleRate: 24_000) { [weak self] in
                self?.recordLatencyMetric(
                    voiceName: voiceName,
                    characterCount: text.count,
                    startedAt: startedAt,
                    synthesizedAt: synthesizedAt,
                    playbackStartedAt: playbackStartedAt,
                    completedAt: Date()
                )
                self?.finishSpeaking(status: "대기 중")
            }
        } catch {
            await cosyVoice.unloadModel()
            statusText = "시스템 음성 응답 중"
            speakWithSystemVoice(text)
        }
    }

    private func speakWithSystemVoice(_ text: String) {
        configureAudioSessionForPlayback()
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "ko-KR")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.92
        synthesizer.speak(utterance)
    }

    private func reloadSavedSlots() {
        savedSlots = Set(
            VoiceSlot.allCases.filter { embeddingSourceURL(for: $0) != nil }
        )
    }

    private func embeddingSourceURL(for slot: VoiceSlot) -> URL? {
        if let bundledURL = bundledEmbeddingURL(for: slot) {
            return bundledURL
        }

        let savedURL = savedEmbeddingURL(for: slot)
        if FileManager.default.fileExists(atPath: savedURL.path) {
            return savedURL
        }

        return nil
    }

    private func bundledEmbeddingURL(for slot: VoiceSlot) -> URL? {
        Bundle.main.url(
            forResource: slot.bundledResourceName,
            withExtension: "json",
            subdirectory: "Voices"
        )
    }

    private func savedEmbeddingURL(for slot: VoiceSlot) -> URL {
        applicationSupportDirectory.appendingPathComponent(slot.savedFileName)
    }

    private func configureAudioSessionForPlayback() {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    private func finishSpeaking(status: String) {
        floatAudioPlayer.stop()
        isSpeaking = false
        statusText = status
        UIApplication.shared.isIdleTimerDisabled = false
    }

    private func recordLatencyMetric(
        voiceName: String,
        characterCount: Int,
        startedAt: Date,
        synthesizedAt: Date,
        playbackStartedAt: Date,
        completedAt: Date
    ) {
        let metric = LatencyMetric(
            voiceName: voiceName,
            characterCount: characterCount,
            synthesisTime: synthesizedAt.timeIntervalSince(startedAt),
            firstPlaybackTime: playbackStartedAt.timeIntervalSince(startedAt),
            totalTime: completedAt.timeIntervalSince(startedAt)
        )
        latencyMetrics.insert(metric, at: 0)
        latencyMetrics = Array(latencyMetrics.prefix(8))
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor [weak self] in
            self?.finishSpeaking(status: "대기 중")
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor [weak self] in
            self?.finishSpeaking(status: "대기 중")
        }
    }
}
