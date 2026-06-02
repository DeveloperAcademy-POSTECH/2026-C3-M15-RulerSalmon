import Foundation

final class RemoteTTSService: TTSService {
    private let endpoint = URL(string: "http://127.0.0.1:8000/synthesize")!

    func synthesize(text: String, voiceId: String) async throws -> URL {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "text": text,
            "voiceId": voiceId,
        ])

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw TTSServiceError.invalidServerResponse
        }

        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent("remote-tts.wav")
        do {
            try data.write(to: outputURL, options: .atomic)
            return outputURL
        } catch {
            throw TTSServiceError.writeFailed
        }
    }
}
