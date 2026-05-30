import Foundation

#if canImport(CosyVoiceTTS) && !targetEnvironment(simulator)
import CosyVoiceTTS

private struct VoiceEmbeddingFile: Decodable {
    let embedding: [Float]
}

actor CosyVoiceSpeechProvider {
//    private let modelId = "aufklarer/CosyVoice3-0.5B-MLX-8bit"

    private var model: CosyVoiceTTSModel?
    private var speaker: CamPlusPlusSpeaker?
    private var speakerEmbedding: [Float]?

    var isAvailable: Bool {
        true
    }

    var hasVoiceSample: Bool {
        speakerEmbedding != nil
    }

    func loadModelIfNeeded() async throws {
        if model == nil {
            model = try await CosyVoiceTTSModel.fromPretrained()
//            model = try await CosyVoiceTTSModel.fromPretrained(modelId: modelId)
        }
    }

    func loadSpeakerIfNeeded() async throws {
        if speaker == nil {
            speaker = try await CamPlusPlusSpeaker.fromPretrained()
        }
    }

    func setVoiceSample(from url: URL) async throws {
        try await loadSpeakerIfNeeded()
        let samples = try AudioSampleLoader.loadMonoFloatSamples(from: url, targetSampleRate: 16_000)
        guard !samples.isEmpty else {
            throw CocoaError(.fileReadCorruptFile)
        }
        speakerEmbedding = try speaker?.embed(audio: samples, sampleRate: 16_000)
    }

    func setVoiceSample(from url: URL, saveTo embeddingURL: URL) async throws {
        try await setVoiceSample(from: url)
        guard let speakerEmbedding else {
            throw CocoaError(.coderInvalidValue)
        }
        let data = try JSONEncoder().encode(speakerEmbedding)
        try data.write(to: embeddingURL, options: .atomic)
    }

    func loadVoiceSample(from embeddingURL: URL) async throws {
        let data = try Data(contentsOf: embeddingURL)
        let embedding: [Float]
        if let plainEmbedding = try? JSONDecoder().decode([Float].self, from: data) {
            embedding = plainEmbedding
        } else {
            embedding = try JSONDecoder().decode(VoiceEmbeddingFile.self, from: data).embedding
        }
        guard embedding.count == CamPlusPlusSpeaker.embeddingDim else {
            throw CocoaError(.coderInvalidValue)
        }
        speakerEmbedding = embedding
    }

    func clearVoiceSample() {
        speakerEmbedding = nil
    }

    func unloadModel() {
        model?.unload()
        model = nil
    }

    func synthesize(text: String) async throws -> [Float] {
        try await loadModelIfNeeded()
        guard let model else {
            throw CocoaError(.coderInvalidValue)
        }

        return model.synthesize(
            text: text,
            language: "korean",
            instruction: "Speak calmly and warmly, like a thoughtful retrospective coach.",
            speakerEmbedding: speakerEmbedding,
            verbose: false
        )
    }
}
#else
actor CosyVoiceSpeechProvider {
    var isAvailable: Bool { false }

    var hasVoiceSample: Bool { false }

    func loadModelIfNeeded() async throws {
        throw CocoaError(.featureUnsupported)
    }

    func loadSpeakerIfNeeded() async throws {
        throw CocoaError(.featureUnsupported)
    }

    func setVoiceSample(from url: URL) async throws {
        throw CocoaError(.featureUnsupported)
    }

    func setVoiceSample(from url: URL, saveTo embeddingURL: URL) async throws {
        throw CocoaError(.featureUnsupported)
    }

    func loadVoiceSample(from embeddingURL: URL) async throws {
        throw CocoaError(.featureUnsupported)
    }

    func clearVoiceSample() {}

    func unloadModel() {}

    func synthesize(text: String) async throws -> [Float] {
        throw CocoaError(.featureUnsupported)
    }
}
#endif
