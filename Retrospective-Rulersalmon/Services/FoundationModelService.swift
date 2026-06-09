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
    private static let defaultInstructions = """
    너는 30대 한국의 회고 전문가이다.
    사용자의 회고에 맞게 간단한 질문으로 자연스러운 한국어 답변을 한다.
    """

    init(instructions: String? = nil, useDefaultInstructions: Bool = false) {
        #if canImport(FoundationModels) && !targetEnvironment(simulator)
        let resolvedInstructions: String
        if let instructions {
            resolvedInstructions = instructions
        } else if useDefaultInstructions {
            resolvedInstructions = Self.defaultInstructions
        } else {
            resolvedInstructions = ""
        }

        session = LanguageModelSession(instructions: resolvedInstructions)
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
