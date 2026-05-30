import AVFoundation
import Foundation

@MainActor
final class FloatAudioPlayer: NSObject, AVAudioPlayerDelegate {
    private let engine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private var isConnected = false
    private var dataPlayer: AVAudioPlayer?
    private var dataPlaybackCompletion: (@MainActor () -> Void)?

    override init() {
        super.init()
        engine.attach(playerNode)
    }

    func play(samples: [Float], sampleRate: Double, onComplete: @escaping @MainActor () -> Void = {}) throws {
        stop()

        guard
            let format = AVAudioFormat(
                commonFormat: .pcmFormatFloat32,
                sampleRate: sampleRate,
                channels: 1,
                interleaved: false
            ),
            let buffer = AVAudioPCMBuffer(
                pcmFormat: format,
                frameCapacity: AVAudioFrameCount(samples.count)
            )
        else {
            throw CocoaError(.coderInvalidValue)
        }

        buffer.frameLength = AVAudioFrameCount(samples.count)
        samples.withUnsafeBufferPointer { source in
            buffer.floatChannelData?[0].update(from: source.baseAddress!, count: samples.count)
        }

        if !isConnected {
            engine.connect(playerNode, to: engine.mainMixerNode, format: format)
            isConnected = true
        }

        if !engine.isRunning {
            try engine.start()
        }

        playerNode.scheduleBuffer(buffer, completionCallbackType: .dataPlayedBack) { _ in
            Task { @MainActor in
                onComplete()
            }
        }
        playerNode.play()
    }

    func play(wavData: Data, onComplete: @escaping @MainActor () -> Void = {}) throws {
        stop()

        dataPlaybackCompletion = onComplete
        dataPlayer = try AVAudioPlayer(data: wavData)
        dataPlayer?.delegate = self
        dataPlayer?.prepareToPlay()
        dataPlayer?.play()
    }

    func stop() {
        dataPlayer?.stop()
        dataPlayer = nil
        dataPlaybackCompletion = nil

        if playerNode.isPlaying {
            playerNode.stop()
        }
        if engine.isRunning {
            engine.stop()
        }
        engine.reset()
    }

    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor [weak self] in
            let completion = self?.dataPlaybackCompletion
            self?.dataPlayer = nil
            self?.dataPlaybackCompletion = nil
            completion?()
        }
    }
}
