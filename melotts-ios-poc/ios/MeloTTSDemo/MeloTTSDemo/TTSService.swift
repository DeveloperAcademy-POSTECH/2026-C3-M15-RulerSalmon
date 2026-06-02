import Foundation

protocol TTSService {
    func synthesize(text: String, voiceId: String) async throws -> URL
}

enum TTSServiceError: LocalizedError {
    case invalidServerResponse
    case localRuntimeNotImplemented
    case missingVoicePack
    case writeFailed

    var errorDescription: String? {
        switch self {
        case .invalidServerResponse:
            return "서버에서 올바른 오디오 응답을 받지 못했어."
        case .localRuntimeNotImplemented:
            return "로컬 ONNX 추론은 아직 실제 런타임 연동 전이야."
        case .missingVoicePack:
            return "보이스 팩을 찾지 못했어."
        case .writeFailed:
            return "오디오 파일 저장에 실패했어."
        }
    }
}
