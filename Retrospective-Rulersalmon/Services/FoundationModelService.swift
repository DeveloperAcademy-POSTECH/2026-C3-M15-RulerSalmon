//
//  FoundationModelService.swift
//  Retrospective-Rulersalmon
//
//  Created by DevPaul on 5/21/26.
//

import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

protocol FoundationModelServicing {
    func respond(to prompt: String) async throws -> String
}

enum FoundationModelServiceError: LocalizedError {
    case unavailableOnSimulator
    case unsupportedOS
    case unavailable

    var errorDescription: String? {
        switch self {
        case .unavailableOnSimulator:
            "Foundation Model은 시뮬레이터에서 사용할 수 없어요. 지원되는 실기기에서 다시 시도해 주세요."
        case .unsupportedOS:
            "Foundation Model을 사용하려면 iOS 26 이상이 필요해요."
        case .unavailable:
            "Foundation Model 응답을 생성하지 못했어요."
        }
    }
}

final class FoundationModelService: FoundationModelServicing {
    #if canImport(FoundationModels) && !targetEnvironment(simulator)
    private let session: LanguageModelSession
    #endif

    init() {
        #if canImport(FoundationModels) && !targetEnvironment(simulator)
        let instructions = """
        You are a concise, helpful Korean assistant.
        Reply naturally in Korean.
        Keep answers short unless the user asks for detail.
        """
        session = LanguageModelSession(instructions: instructions)
        #endif
    }

    func respond(to prompt: String) async throws -> String {
        #if targetEnvironment(simulator)
        throw FoundationModelServiceError.unavailableOnSimulator
        #elseif canImport(FoundationModels)
        guard #available(iOS 26.0, *) else {
            throw FoundationModelServiceError.unsupportedOS
        }

        do {
            let response = try await session.respond(to: prompt)
            return response.content
        } catch {
            throw FoundationModelServiceError.unavailable
        }
        #else
        throw FoundationModelServiceError.unavailable
        #endif
    }
}
