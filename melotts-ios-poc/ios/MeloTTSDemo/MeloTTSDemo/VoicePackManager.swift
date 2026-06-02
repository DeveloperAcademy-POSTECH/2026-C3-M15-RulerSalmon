import Foundation

final class VoicePackManager {
    let defaultVoiceID = "custom_ko_melotts_v1"

    func loadPlaceholderVoicePack() throws -> VoicePack {
        guard let manifestURL = Bundle.module.url(
            forResource: "manifest.example",
            withExtension: "json",
            subdirectory: "voice-pack-placeholder"
        ) else {
            throw TTSServiceError.missingVoicePack
        }

        let data = try Data(contentsOf: manifestURL)
        let manifest = try JSONDecoder().decode(VoiceManifest.self, from: data)
        return VoicePack(manifest: manifest, baseURL: manifestURL.deletingLastPathComponent())
    }
}
