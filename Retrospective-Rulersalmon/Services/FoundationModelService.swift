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

    init(instructions: String? = nil, useDefaultInstructions: Bool = false) {
        #if canImport(FoundationModels)
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
        #if canImport(FoundationModels)
        guard #available(iOS 26.0, *) else {
            #if DEBUG
            print("[FoundationModelService] FoundationModels unavailable: iOS version is lower than 26.0")
            #endif
            return Self.fallbackResponse(for: prompt)
        }

        do {
            let response = try await session.respond(to: prompt)
            #if DEBUG
            print("[FoundationModelService] FoundationModels response received")
            #endif
            return response.content
        } catch {
            #if DEBUG
            print("[FoundationModelService] FoundationModels response failed: \(error)")
            #endif
            return Self.fallbackResponse(for: prompt)
        }
        #else
        #if DEBUG
        print("[FoundationModelService] FoundationModels module is not available")
        #endif
        return Self.fallbackResponse(for: prompt)
        #endif
    }

    private static func fallbackResponse(for prompt: String) -> String {
        "Unable to prepare a model response. Input: \(prompt)"
    }
}
