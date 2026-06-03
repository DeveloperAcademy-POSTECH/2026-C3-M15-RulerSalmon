//
//  FoundationModelService.swift
//  Retrospective-Rulersalmon
//
//  Created by DevPaul on 5/21/26.
//

import Foundation
import FoundationModels


protocol FoundationModelServicing {
    func respond(to prompt: String) async throws -> String
}

final class FoundationModelService: FoundationModelServicing {
    private let session: LanguageModelSession
    
    init() {
        let instructions = """
        You are a concise, helpful Korean assistant.
        Reply naturally in Korean.
        Keep answers short unless the user asks for detail.
        """
        session = LanguageModelSession(instructions: instructions)
    }

    func respond(to prompt: String) async throws -> String {
        guard #available(iOS 26.0, *) else {
            return Self.fallbackResponse(for: prompt)
        }

        do {
            let response = try await session.respond(to: prompt)
            return response.content
        } catch {
            return Self.fallbackResponse(for: prompt)
        }
        
        // return Self.fallbackResponse(for: prompt)
        
    }

    private static func fallbackResponse(for prompt: String) -> String {
        "모델 응답을 준비할 수 없어서 임시 답변을 보여드려요. 입력: \(prompt)"
    }
}
