//
//  ReflectionQuestionGenerator.swift
//  Retrospective-Rulersalmon
//
//  Created by DevPaul on 6/6/26.
//

import Foundation

final class ReflectionQuestionGenerator {
    private let foundationModelService: FoundationModelServicing

    init(foundationModelService: FoundationModelServicing? = nil) {
        self.foundationModelService = foundationModelService ?? FoundationModelService()
    }

    func generateQuestion(
        userText: String,
        validation: ReflectionSecondPassValidation,
        questionContext: RetrievedReflectionContext
    ) async -> String {
        do {
            print("[RAG][FoundationModel] question-generation request started")
            let response = try await foundationModelService.respond(
                to: questionPrompt(
                    userText: userText,
                    validation: validation,
                    questionContext: questionContext
                )
            )
            print("[RAG][FoundationModel] question-generation response received")
            if let parsed = parseQuestion(from: response) {
                print("[RAG][FoundationModel] question-generation parsed successfully")
                return parsed
            }
            print("[RAG][FoundationModel] question-generation parse failed, using fallback")
        } catch {
            print("[RAG][FoundationModel] question-generation failed: \(error.localizedDescription)")
        }

        return fallbackQuestion(for: validation.primaryDimension)
    }

    private func questionPrompt(
        userText: String,
        validation: ReflectionSecondPassValidation,
        questionContext: RetrievedReflectionContext
    ) -> String {
        let dimensions = validation.verifiedDimensions.map(\.rawValue).joined(separator: ", ")
        return """
        너는 회고 대화를 이어가는 질문 생성기다.
        현재 사용자 발화와 2차 검증 결과, 현재 세션의 관련 회고 맥락을 참고해 다음 질문 한 문장만 만든다.

        규칙:
        - 반드시 한국어 반말 한 문장만 출력한다.
        - 질문은 한 번에 하나만 한다.
        - 회고를 평가하는 말투를 쓰지 마라.
        - 사용자의 방금 발화와 자연스럽게 이어져야 한다.
        - 관련 문맥이 있어도 현재 발화보다 앞서면 안 된다.
        - 출력은 반드시 JSON 하나만 한다.

        스키마:
        {
          "question": "string"
        }

        현재 발화:
        \(userText)

        2차 검증 결과:
        - 요약: \(validation.summary)
        - 차원: \(dimensions.isEmpty ? "없음" : dimensions)
        - 핵심 근거: \(validation.evidence.joined(separator: " / "))
        - 주제: \(validation.topic ?? "없음")

        현재 세션 관련 맥락:
        \(questionContext.koreanPromptBlock())
        """
    }

    private func parseQuestion(from response: String) -> String? {
        struct Payload: Decodable {
            let question: String
        }

        let cleaned = response.trimmingCharacters(in: .whitespacesAndNewlines)

        if let data = cleaned.data(using: .utf8),
           let payload = try? JSONDecoder().decode(Payload.self, from: data) {
            return payload.question.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        guard let start = cleaned.firstIndex(of: "{"),
              let end = cleaned.lastIndex(of: "}") else {
            return cleaned.isEmpty ? nil : cleaned
        }

        let snippet = String(cleaned[start...end])
        guard let data = snippet.data(using: .utf8),
              let payload = try? JSONDecoder().decode(Payload.self, from: data) else {
            return nil
        }

        return payload.question.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func fallbackQuestion(for dimension: ReflectionDimension?) -> String {
        switch dimension {
        case .liked:
            return "그중에서 뭐가 제일 좋았어?"
        case .learned:
            return "그 일을 겪으면서 새로 알게 된 게 뭐였어?"
        case .lacked:
            return "그때 어디서 제일 막혔어?"
        case .longedFor:
            return "그럼 다음엔 뭘 먼저 바꿔보고 싶어?"
        case nil:
            return "그때 제일 크게 남은 건 뭐였어?"
        }
    }
}
