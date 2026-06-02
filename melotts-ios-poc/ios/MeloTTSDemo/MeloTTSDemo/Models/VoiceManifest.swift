import Foundation

struct VoiceManifest: Codable {
    let id: String
    let name: String
    let engine: String
    let language: String
    let sampleRate: Int
    let model: String
    let config: String
    let version: String
    let trainingDataMinutes: Int
    let quality: String
    let requires: VoiceManifestRequirements
}

struct VoiceManifestRequirements: Codable {
    let runtime: String
    let textNormalizer: Bool
    let phonemizer: Bool?
}
