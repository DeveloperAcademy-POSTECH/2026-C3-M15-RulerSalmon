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

final class FoundationModelService: FoundationModelServicing {
    #if canImport(FoundationModels)
    private let session: LanguageModelSession
    #endif
    private static let defaultInstructions = """
    너는 30대 한국의 회고 전문가이다.
    사용자의 회고에 맞게 간단한 질문으로 자연스러운 한국어 답변을 한다.
    """

    init(instructions: String? = nil) {
        #if canImport(FoundationModels)
        session = LanguageModelSession(instructions: instructions ?? Self.defaultInstructions)
        #endif
    }

    func respond(to prompt: String) async throws -> String {
        #if canImport(FoundationModels)
        guard #available(iOS 26.0, *) else {
            return Self.fallbackResponse(for: prompt)
        }

        do {
            let response = try await session.respond(to: prompt)
            return response.content
        } catch {
            return Self.fallbackResponse(for: prompt)
        }
        #else
        return Self.fallbackResponse(for: prompt)
        #endif
    }

    private static func fallbackResponse(for prompt: String) -> String {
        "Unable to prepare a model response. Input: \(prompt)"
    }
}
