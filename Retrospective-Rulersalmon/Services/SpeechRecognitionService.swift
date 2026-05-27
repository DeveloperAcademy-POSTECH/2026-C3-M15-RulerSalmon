//
//  SpeechRecognitionService.swift
//  Retrospective-Rulersalmon
//
//  Created by DevPaul on 5/21/26.
//

import AVFoundation
import Speech

final class SpeechRecognitionService: NSObject {
    private let audioEngine = AVAudioEngine()
    private let legacyRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ko-KR"))
    private var legacyRecognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var legacyRecognitionTask: SFSpeechRecognitionTask?
    @available(iOS 26.0, *)
    private var analyzerSession: AnalyzerSession?

    var isRecording: Bool {
        audioEngine.isRunning
    }

    func requestAuthorization() async -> SFSpeechRecognizerAuthorizationStatus {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
    }

    func startRecording(onPartialResult: @escaping @MainActor (String) -> Void) async throws {
        stopRecording()

        if #available(iOS 26.0, *),
           let analyzerError = await startSpeechAnalyzerRecording(onPartialResult: onPartialResult) {
            print("SpeechAnalyzer fallback: \(analyzerError.localizedDescription)")
            try startLegacyRecording(onPartialResult: onPartialResult)
        } else if !isRecording {
            try startLegacyRecording(onPartialResult: onPartialResult)
        }
    }

    func stopRecording() {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }

        if #available(iOS 26.0, *), let analyzerSession {
            analyzerSession.finish()
            self.analyzerSession = nil
        }

        legacyRecognitionRequest?.endAudio()
        legacyRecognitionTask?.cancel()
        legacyRecognitionTask = nil
        legacyRecognitionRequest = nil

        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    @available(iOS 26.0, *)
    private func startSpeechAnalyzerRecording(
        onPartialResult: @escaping @MainActor (String) -> Void
    ) async -> Error? {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

            guard SpeechTranscriber.isAvailable else {
                throw SpeechRecognitionError.unavailableOnThisDevice
            }

            let locale = Locale(identifier: "ko-KR")
            guard let supportedLocale = await SpeechTranscriber.supportedLocale(equivalentTo: locale) else {
                throw SpeechRecognitionError.unsupportedLocale
            }

            let transcriber = SpeechTranscriber(
                locale: supportedLocale,
                preset: .progressiveTranscription
            )

            let analyzer = SpeechAnalyzer(modules: [transcriber])
            guard let audioFormat = await SpeechAnalyzer.bestAvailableAudioFormat(compatibleWith: [transcriber]) else {
                throw SpeechRecognitionError.audioConversionFailed
            }

            if let installationRequest = try await AssetInventory.assetInstallationRequest(supporting: [transcriber]) {
                try await installationRequest.downloadAndInstall()
            }

            let (inputSequence, inputBuilder) = AsyncStream.makeStream(of: AnalyzerInput.self)
            try await analyzer.start(inputSequence: inputSequence)

            let session = AnalyzerSession(
                analyzer: analyzer,
                transcriber: transcriber,
                inputBuilder: inputBuilder,
                audioFormat: audioFormat
            )
            analyzerSession = session
            session.startResultsTask(onPartialResult: onPartialResult)

            let inputNode = audioEngine.inputNode
            let recordingFormat = inputNode.outputFormat(forBus: 0)

            inputNode.removeTap(onBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
                guard let self else { return }
                guard let analyzerSession = self.analyzerSession else { return }

                do {
                    let convertedBuffer = try self.convert(buffer: buffer, to: analyzerSession.audioFormat)
                    analyzerSession.inputBuilder.yield(AnalyzerInput(buffer: convertedBuffer))
                } catch {
                    Task { @MainActor in
                        self.stopRecording()
                    }
                }
            }

            audioEngine.prepare()
            try audioEngine.start()
            return nil
        } catch {
            stopRecording()
            return error
        }
    }

    private func startLegacyRecording(onPartialResult: @escaping @MainActor (String) -> Void) throws {
        guard let legacyRecognizer, legacyRecognizer.isAvailable else {
            throw SpeechRecognitionError.recognizerUnavailable
        }

        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        legacyRecognitionRequest = request

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.legacyRecognitionRequest?.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()

        legacyRecognitionTask = legacyRecognizer.recognitionTask(with: request) { result, error in
            if let result {
                Task { @MainActor in
                    onPartialResult(result.bestTranscription.formattedString)
                }
            }

            if error != nil || result?.isFinal == true {
                Task { @MainActor in
                    self.stopRecording()
                }
            }
        }
    }

    private func convert(buffer: AVAudioPCMBuffer, to format: AVAudioFormat) throws -> AVAudioPCMBuffer {
        if buffer.format == format {
            return buffer
        }

        guard let converter = AVAudioConverter(from: buffer.format, to: format) else {
            throw SpeechRecognitionError.audioConversionFailed
        }

        let ratio = format.sampleRate / buffer.format.sampleRate
        let frameCapacity = AVAudioFrameCount(Double(buffer.frameLength) * ratio) + 1
        guard let convertedBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCapacity) else {
            throw SpeechRecognitionError.audioConversionFailed
        }

        var didSupplyInput = false
        var conversionError: NSError?
        let status = converter.convert(to: convertedBuffer, error: &conversionError) { _, outputStatus in
            if didSupplyInput {
                outputStatus.pointee = .noDataNow
                return nil
            }

            didSupplyInput = true
            outputStatus.pointee = .haveData
            return buffer
        }

        if status == .error {
            throw conversionError ?? SpeechRecognitionError.audioConversionFailed
        }

        return convertedBuffer
    }
}

enum SpeechRecognitionError: LocalizedError {
    case recognizerUnavailable
    case unavailableOnThisDevice
    case unsupportedLocale
    case audioConversionFailed

    var errorDescription: String? {
        switch self {
        case .recognizerUnavailable:
            return "Speech recognizer is unavailable."
        case .unavailableOnThisDevice:
            return "Speech transcriber is unavailable on this device."
        case .unsupportedLocale:
            return "The selected locale is not supported."
        case .audioConversionFailed:
            return "Failed to convert audio for speech analysis."
        }
    }
}

@available(iOS 26.0, *)
private final class AnalyzerSession {
    let analyzer: SpeechAnalyzer
    let transcriber: SpeechTranscriber
    let inputBuilder: AsyncStream<AnalyzerInput>.Continuation
    let audioFormat: AVAudioFormat
    private var resultsTask: Task<Void, Never>?

    init(
        analyzer: SpeechAnalyzer,
        transcriber: SpeechTranscriber,
        inputBuilder: AsyncStream<AnalyzerInput>.Continuation,
        audioFormat: AVAudioFormat
    ) {
        self.analyzer = analyzer
        self.transcriber = transcriber
        self.inputBuilder = inputBuilder
        self.audioFormat = audioFormat
    }

    func startResultsTask(onPartialResult: @escaping @MainActor (String) -> Void) {
        resultsTask = Task {
            do {
                for try await result in transcriber.results {
                    let text = String(result.text.characters)
                    guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { continue }

                    await MainActor.run {
                        onPartialResult(text)
                    }
                }
            } catch {
                return
            }
        }
    }

    func finish() {
        inputBuilder.finish()
        resultsTask?.cancel()
        resultsTask = nil
    }
}
