import AudioCommon
import CosyVoiceTTS
import Foundation

private struct VoiceEmbeddingFile: Decodable {
    let embedding: [Float]
}

@main
struct MacLocalTTS {
    static func main() async throws {
        let arguments = CommandLine.arguments.dropFirst()
        if arguments.contains("--loop") {
            try await runLoop(arguments: arguments)
            return
        }

        let text = value(for: "--text", in: arguments) ?? "안녕하세요. 맥 로컬에서 음성 합성을 테스트합니다."
        let voice = value(for: "--voice", in: arguments) ?? "chaem"
        let output = value(for: "--output", in: arguments) ?? "mac-local-output.wav"
        let modelId = value(for: "--model", in: arguments) ?? "aufklarer/CosyVoice3-0.5B-MLX-4bit"
        let splitSentences = !arguments.contains("--no-split")
        let embeddingPath = value(for: "--embedding", in: arguments)
            ?? defaultVoicesDirectory().appendingPathComponent("\(voice).embedding.json").path

        let embeddingURL = URL(fileURLWithPath: embeddingPath)
        let outputURL = URL(fileURLWithPath: output)

        print("Text: \(text)")
        print("Voice: \(voice)")
        print("Embedding: \(embeddingURL.path)")
        print("Model: \(modelId)")
        print("Output: \(outputURL.path)")

        let embedding = try loadEmbedding(from: embeddingURL)
        print("Loaded speaker embedding: \(embedding.count) dims")

        let startedAt = Date()
        let model = try await CosyVoiceTTSModel.fromPretrained(
            modelId: modelId
        ) { progress, status in
            print(String(format: "Model %.0f%% - %@", progress * 100, status))
        }
        let loadedAt = Date()

        let samples = synthesize(
            model: model,
            text: text,
            speakerEmbedding: embedding,
            splitSentences: splitSentences
        )
        let synthesizedAt = Date()

        guard !samples.isEmpty else {
            throw CocoaError(.coderInvalidValue)
        }

        try WAVWriter.write(samples: samples, sampleRate: 24_000, to: outputURL)
        let completedAt = Date()

        print(String(format: "Load time: %.2fs", loadedAt.timeIntervalSince(startedAt)))
        print(String(format: "Synthesis time: %.2fs", synthesizedAt.timeIntervalSince(loadedAt)))
        print(String(format: "Total time: %.2fs", completedAt.timeIntervalSince(startedAt)))
        print(String(format: "Audio duration: %.2fs", Double(samples.count) / 24_000.0))
        print("Saved: \(outputURL.path)")

        model.unload()
    }

    private static func runLoop(arguments: ArraySlice<String>) async throws {
        let modelId = value(for: "--model", in: arguments) ?? "aufklarer/CosyVoice3-0.5B-MLX-4bit"
        let voicesDirectory = value(for: "--voices-dir", in: arguments)
            ?? defaultVoicesDirectory().path

        print("MacLocalTTS loop mode")
        print("Model: \(modelId)")
        print("Voices: \(voicesDirectory)")
        print("Input format: voice|text|output.wav")
        print("Example: friday|안녕하세요|friday.wav")
        print("Type q to quit.")

        let modelLoadStartedAt = Date()
        let model = try await CosyVoiceTTSModel.fromPretrained(
            modelId: modelId
        ) { progress, status in
            print(String(format: "Model %.0f%% - %@", progress * 100, status))
        }
        print(String(format: "Model ready in %.2fs", Date().timeIntervalSince(modelLoadStartedAt)))

        var embeddings: [String: [Float]] = [:]
        for voice in ["chaem", "cindy", "friday"] {
            let url = URL(fileURLWithPath: voicesDirectory).appendingPathComponent("\(voice).embedding.json")
            embeddings[voice] = try loadEmbedding(from: url)
            print("Loaded \(voice): \(embeddings[voice]?.count ?? 0) dims")
        }

        while true {
            print("\ntts> ", terminator: "")
            guard let line = readLine() else { break }
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed == "q" || trimmed == "quit" || trimmed == "exit" {
                break
            }

            let parts = trimmed.split(separator: "|", maxSplits: 2).map(String.init)
            guard parts.count == 3 else {
                print("Invalid input. Use: voice|text|output.wav")
                continue
            }

            let voice = parts[0]
            let text = parts[1]
            let output = parts[2]

            guard let embedding = embeddings[voice] else {
                print("Unknown voice: \(voice)")
                continue
            }

            let startedAt = Date()
            let samples = synthesize(
                model: model,
                text: text,
                speakerEmbedding: embedding,
                splitSentences: true
            )
            let synthesizedAt = Date()

            guard !samples.isEmpty else {
                print("No audio generated.")
                continue
            }

            let outputURL = URL(fileURLWithPath: output)
            try WAVWriter.write(samples: samples, sampleRate: 24_000, to: outputURL)
            let completedAt = Date()

            print(String(format: "Synthesis time: %.2fs", synthesizedAt.timeIntervalSince(startedAt)))
            print(String(format: "Total time: %.2fs", completedAt.timeIntervalSince(startedAt)))
            print(String(format: "Audio duration: %.2fs", Double(samples.count) / 24_000.0))
            print("Saved: \(outputURL.path)")
        }

        model.unload()
    }

    private static func synthesize(
        model: CosyVoiceTTSModel,
        text: String,
        speakerEmbedding: [Float],
        splitSentences: Bool
    ) -> [Float] {
        let chunks = splitSentences ? sentenceChunks(from: text) : [text]
        let silence = [Float](repeating: 0, count: Int(24_000 * 0.18))
        var allSamples: [Float] = []

        for (index, chunk) in chunks.enumerated() {
            print("Chunk \(index + 1)/\(chunks.count): \(chunk)")
            let samples = model.synthesize(
                text: chunk,
                language: "korean",
                instruction: "Speak naturally in Korean with a clear, steady voice and minimal emotion. Read every word exactly once.",
                speakerEmbedding: speakerEmbedding,
                verbose: true
            )

            if !samples.isEmpty {
                if !allSamples.isEmpty {
                    allSamples.append(contentsOf: silence)
                }
                allSamples.append(contentsOf: samples)
            }
        }

        return allSamples
    }

    private static func sentenceChunks(from text: String) -> [String] {
        var chunks: [String] = []
        var current = ""
        let punctuation = Set<Character>([".", "?", "!", "。", "？", "！", "\n"])

        for character in text {
            current.append(character)
            if punctuation.contains(character) {
                let chunk = current.trimmingCharacters(in: .whitespacesAndNewlines)
                if !chunk.isEmpty {
                    chunks.append(chunk)
                }
                current = ""
            }
        }

        let remaining = current.trimmingCharacters(in: .whitespacesAndNewlines)
        if !remaining.isEmpty {
            chunks.append(remaining)
        }

        return chunks.isEmpty ? [text] : chunks
    }

    private static func value(for option: String, in arguments: ArraySlice<String>) -> String? {
        let values = Array(arguments)
        guard let index = values.firstIndex(of: option), values.indices.contains(index + 1) else {
            return nil
        }
        return values[index + 1]
    }

    private static func defaultVoicesDirectory() -> URL {
        let currentDirectory = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let relativeVoicesPath = "Retrospective-Rulersalmon/Resources/Voices"
        let candidates = [
            currentDirectory.appendingPathComponent(relativeVoicesPath),
            currentDirectory.deletingLastPathComponent().appendingPathComponent(relativeVoicesPath)
        ]

        return candidates.first { FileManager.default.fileExists(atPath: $0.path) } ?? candidates[0]
    }

    private static func loadEmbedding(from url: URL) throws -> [Float] {
        let data = try Data(contentsOf: url)
        if let embedding = try? JSONDecoder().decode([Float].self, from: data) {
            return embedding
        }
        return try JSONDecoder().decode(VoiceEmbeddingFile.self, from: data).embedding
    }
}
