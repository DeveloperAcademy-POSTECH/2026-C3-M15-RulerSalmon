//
//  ReflectionSecondPassValidator.swift
//  Retrospective-Rulersalmon
//
//  Created by DevPaul on 6/6/26.
//

import Foundation

final class ReflectionSecondPassValidator {
    private let foundationModelService: FoundationModelServicing

    init(foundationModelService: FoundationModelServicing? = nil) {
        self.foundationModelService = foundationModelService ?? FoundationModelService()
    }

    func validate(
        userText: String,
        firstPassResults: [FourLClassificationResult],
        analysisContext: RetrievedReflectionContext
    ) async -> ReflectionSecondPassValidation {
        do {
            print("[RAG][FoundationModel] second-pass validation request started")
            let response = try await foundationModelService.respond(
                to: validationPrompt(
                    userText: userText,
                    firstPassResults: firstPassResults,
                    analysisContext: analysisContext
                )
            )
            print("[RAG][FoundationModel] second-pass validation response received")

            if let parsed = parseValidation(from: response) {
                print("[RAG][FoundationModel] second-pass validation parsed successfully")
                return parsed
            }
            print("[RAG][FoundationModel] second-pass validation parse failed, using fallback")
        } catch {
            print("[RAG][FoundationModel] second-pass validation failed: \(error.localizedDescription)")
        }

        return fallbackValidation(userText: userText, firstPassResults: firstPassResults)
    }

    private func validationPrompt(
        userText: String,
        firstPassResults: [FourLClassificationResult],
        analysisContext: RetrievedReflectionContext
    ) -> String {
        let firstPassBlock = firstPassResults.map { result in
            let secondary = result.secondaryLabel.map { ", 보조=\($0)" } ?? ""
            return "- 문장: \(result.text)\n  1차 분류: \(result.label), 신뢰도=\(String(format: "%.2f", result.confidence))\(secondary)"
        }
        .joined(separator: "\n")

        return """
        너는 회고 발화를 2차로 검토하는 검증기다.
        아래 입력과 1차 분류 결과, 관련 회고 문맥을 참고해 현재 발화를 다시 검증하라.

        목표:
        - 1차 분류를 맹신하지 말고, 현재 발화를 우선으로 다시 판단한다.
        - 관련 문맥은 의미 보강용으로만 사용한다.
        - 현재 발화의 요약, 핵심 근거, 주제, 핵심 키워드, 최종 회고 차원을 정리한다.

        출력은 반드시 JSON 하나만 한다.
        {
          "summary": "string",
          "verifiedDimensions": ["liked" | "learned" | "lacked" | "longedFor"],
          "primaryDimension": "liked" | "learned" | "lacked" | "longedFor" | null,
          "evidence": ["string"],
          "keywords": ["string"],
          "topic": "string or null",
          "confidence": 0.0,
          "reasoning": "string"
        }

        현재 사용자 발화:
        \(userText)

        1차 분류 결과:
        \(firstPassBlock.isEmpty ? "없음" : firstPassBlock)

        관련 회고 문맥:
        \(analysisContext.koreanPromptBlock())
        """
    }

    private func parseValidation(from response: String) -> ReflectionSecondPassValidation? {
        let cleaned = response.trimmingCharacters(in: .whitespacesAndNewlines)

        if let data = cleaned.data(using: .utf8),
           let parsed = try? JSONDecoder().decode(ReflectionSecondPassValidation.self, from: data) {
            return parsed
        }

        guard let start = cleaned.firstIndex(of: "{"),
              let end = cleaned.lastIndex(of: "}") else {
            return nil
        }

        let snippet = String(cleaned[start...end])
        guard let data = snippet.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(ReflectionSecondPassValidation.self, from: data)
    }

    private func fallbackValidation(
        userText: String,
        firstPassResults: [FourLClassificationResult]
    ) -> ReflectionSecondPassValidation {
        let dimensions = firstPassResults.compactMap { mapLabelToDimension($0.label) }
        let summary = String(userText.prefix(60))
        let keywords = extractKeywords(from: userText)

        return ReflectionSecondPassValidation(
            summary: summary,
            verifiedDimensions: Array(Set(dimensions)),
            primaryDimension: dimensions.first,
            evidence: [userText].filter { !$0.isEmpty },
            keywords: keywords,
            topic: keywords.first,
            confidence: firstPassResults.first?.confidence ?? 0.45,
            reasoning: "1차 분류 결과를 기반으로 한 기본 검증"
        )
    }

    private func mapLabelToDimension(_ label: String) -> ReflectionDimension? {
        switch label {
        case "Liked": return .liked
        case "Learned": return .learned
        case "Lacked": return .lacked
        case "Longed for": return .longedFor
        default: return nil
        }
    }

    private func extractKeywords(from text: String) -> [String] {
        text
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.count >= 2 }
    }
}
