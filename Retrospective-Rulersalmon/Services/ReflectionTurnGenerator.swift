//
//  ReflectionTurnGenerator.swift
//  Retrospective-Rulersalmon
//
//  Created by DevPaul on 6/6/26.
//

import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

final class ReflectionTurnGenerator {
    #if canImport(FoundationModels)
    private static let instructions = """
    너는 회고 대화를 돕는 온디바이스 검토자다.
    현재 사용자 발화를 가장 우선해서 이해한다.
    필요한 정보만 짧게 정리하고, 질문은 자연스러운 한국어 반말 한 문장으로 만든다.
    질문은 평가하지 말고, 현재 발화와 현재 세션 맥락에만 이어져야 한다.
    """
    #endif

    func generateTurn(
        userText: String,
        firstPassResults: [FourLClassificationResult],
        analysisContext: RetrievedReflectionContext,
        sessionContext: RetrievedReflectionContext
    ) async -> ReflectionGeneratedTurn {
        print("[RAG][FoundationModel] turn-generation request started")

        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            do {
                let session = LanguageModelSession(instructions: Self.instructions)
                let response = try await session.respond(
                    to: prompt(
                        userText: userText,
                        firstPassResults: firstPassResults,
                        analysisContext: analysisContext,
                        sessionContext: sessionContext
                    ),
                    generating: ReflectionGeneratedTurnPayload.self
                )
                print("[RAG][FoundationModel] turn-generation response received")
                return normalize(response.content, userText: userText, firstPassResults: firstPassResults)
            } catch {
                print("[RAG][FoundationModel] turn-generation failed: \(error.localizedDescription)")
            }
        }
        #endif

        print("[RAG][FoundationModel] turn-generation fallback used")
        return fallbackTurn(userText: userText, firstPassResults: firstPassResults)
    }

    private func prompt(
        userText: String,
        firstPassResults: [FourLClassificationResult],
        analysisContext: RetrievedReflectionContext,
        sessionContext: RetrievedReflectionContext
    ) -> String {
        let firstPassBlock = firstPassResults.map { result in
            let secondary = result.secondaryLabel.map { ", 보조=\($0)" } ?? ""
            return "- 문장: \(result.text)\n  1차 분류: \(result.label), 신뢰도=\(String(format: "%.2f", result.confidence))\(secondary)"
        }
        .joined(separator: "\n")

        return """
        작업:
        1. 현재 사용자 발화를 4L 관점에서 다시 검토한다.
        2. 검토 결과를 구조화해서 정리한다.
        3. 다음 질문은 현재 발화와 현재 세션 맥락만 참고해 한 문장으로 만든다.

        규칙:
        - 1차 분류를 참고하되 맹신하지 마라.
        - 과거 전체 회고 문맥은 검토와 해석 보강에만 사용한다.
        - 질문은 과거 전체 회고 문맥에 기대지 말고 현재 발화와 현재 세션 맥락에만 이어져야 한다.
        - verifiedDimensions와 primaryDimension에는 liked, learned, lacked, longedFor만 사용한다.
        - question은 한국어 반말 한 문장으로만 작성한다.

        현재 사용자 발화:
        \(userText)

        1차 분류 결과:
        \(firstPassBlock.isEmpty ? "없음" : firstPassBlock)

        검토 참고용 과거 회고 문맥:
        \(analysisContext.koreanPromptBlock())

        질문 연결용 현재 세션 맥락:
        \(sessionContext.koreanPromptBlock())
        """
    }

    #if canImport(FoundationModels)
    @available(iOS 26.0, *)
    private func normalize(
        _ payload: ReflectionGeneratedTurnPayload,
        userText: String,
        firstPassResults: [FourLClassificationResult]
    ) -> ReflectionGeneratedTurn {
        let fallbackDimensions = firstPassResults.compactMap { Self.mapLabelToDimension($0.label) }
        let dimensions = {
            let generated = payload.verifiedDimensions.compactMap(Self.mapDimension(from:))
            return generated.isEmpty ? Array(Set(fallbackDimensions)) : generated
        }()
        let primaryDimension = payload.primaryDimension.flatMap(Self.mapDimension(from:)) ?? dimensions.first ?? fallbackDimensions.first
        let question = payload.question.trimmingCharacters(in: .whitespacesAndNewlines)

        let validation = ReflectionSecondPassValidation(
            summary: payload.summary.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty ?? String(userText.prefix(60)),
            verifiedDimensions: dimensions,
            primaryDimension: primaryDimension,
            evidence: payload.evidence.nonEmptyOrFallback([userText]),
            keywords: payload.keywords,
            topic: payload.topic?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
            confidence: min(max(payload.confidence, 0), 1),
            reasoning: payload.reasoning.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty ?? "Foundation Model 검토 결과"
        )

        let resolvedQuestion: String
        if isUsableQuestion(question, summary: validation.summary) {
            resolvedQuestion = question
        } else {
            resolvedQuestion = fallbackQuestion(for: primaryDimension)
        }

        print("[RAG][FoundationModel] generated question=\(question)")
        print("[RAG][FoundationModel] resolved question=\(resolvedQuestion)")

        return ReflectionGeneratedTurn(
            validation: validation,
            question: resolvedQuestion
        )
    }
    #endif

    private func fallbackTurn(
        userText: String,
        firstPassResults: [FourLClassificationResult]
    ) -> ReflectionGeneratedTurn {
        let dimensions = firstPassResults.compactMap { Self.mapLabelToDimension($0.label) }
        let keywords = extractKeywords(from: userText)
        let primaryDimension = dimensions.first

        let validation = ReflectionSecondPassValidation(
            summary: String(userText.prefix(60)),
            verifiedDimensions: Array(Set(dimensions)),
            primaryDimension: primaryDimension,
            evidence: [userText].filter { !$0.isEmpty },
            keywords: keywords,
            topic: keywords.first,
            confidence: firstPassResults.first?.confidence ?? 0.45,
            reasoning: "1차 분류 결과를 기반으로 한 기본 검토"
        )

        return ReflectionGeneratedTurn(
            validation: validation,
            question: fallbackQuestion(for: primaryDimension)
        )
    }

    private static func mapDimension(from rawValue: String) -> ReflectionDimension? {
        let normalized = rawValue
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "_", with: "")
            .replacingOccurrences(of: " ", with: "")
            .lowercased()

        switch normalized {
        case "liked": return .liked
        case "learned": return .learned
        case "lacked": return .lacked
        case "longedfor": return .longedFor
        default: return nil
        }
    }

    private static func mapLabelToDimension(_ label: String) -> ReflectionDimension? {
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

    private func isUsableQuestion(_ question: String, summary: String) -> Bool {
        let trimmedQuestion = question.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedSummary = summary.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedQuestion.isEmpty else { return false }
        guard trimmedQuestion != trimmedSummary else { return false }
        guard trimmedQuestion.count <= 80 else { return false }

        if trimmedQuestion.contains("?") || trimmedQuestion.contains("？") {
            return true
        }

        let lowered = trimmedQuestion.lowercased()
        let questionEndings = [
            "어", "어?", "까", "까?", "니", "니?", "지", "지?",
            "래", "래?", "해", "해?", "볼래", "볼래?", "싶어", "싶어?"
        ]

        return questionEndings.contains { lowered.hasSuffix($0) }
    }
}

private extension Array where Element == String {
    func nonEmptyOrFallback(_ fallback: [String]) -> [String] {
        let filtered = map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return filtered.isEmpty ? fallback : filtered
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
