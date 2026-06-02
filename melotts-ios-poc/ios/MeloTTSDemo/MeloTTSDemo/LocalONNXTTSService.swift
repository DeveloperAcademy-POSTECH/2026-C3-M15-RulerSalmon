import Foundation

struct VoicePack {
    let manifest: VoiceManifest
    let baseURL: URL
}

final class LocalONNXTTSService {
    func synthesize(text: String, voicePack: VoicePack) async throws -> URL {
        _ = text
        _ = voicePack

        // TODO: Integrate ONNX Runtime Mobile or sherpa-onnx here.
        // Expected local inference flow:
        // 1. normalize text
        // 2. tokenize or phonemize consistently with the Python pipeline
        // 3. load custom_ko_melotts.onnx
        // 4. run inference
        // 5. write wav to a temporary file and return its URL
        throw TTSServiceError.localRuntimeNotImplemented
    }
}
