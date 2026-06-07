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
    @available(iOS 26.0, *)
    private let session: LanguageModelSession
    #endif

    init() {
        #if canImport(FoundationModels)
        self.session = LanguageModelSession(instructions: Self.instructions)
        #endif
    }

    func generateTurn(
        userText: String,
        firstPassResults: [FourLClassificationResult],
        analysisContext: RetrievedReflectionContext,
        sessionContext: RetrievedReflectionContext,
        recentQuestions: [String],
        completionState: ReflectionCompletionState
    ) async -> ReflectionGeneratedTurn {
        print("[RAG][FoundationModel] turn-generation request started")

        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            do {
                let response = try await session.respond(
                    to: prompt(
                        userText: userText,
                        firstPassResults: firstPassResults,
                        analysisContext: analysisContext,
                        sessionContext: sessionContext,
                        recentQuestions: recentQuestions,
                        completionState: completionState
                    ),
                    generating: ReflectionGeneratedTurnPayload.self
                )
                print("[RAG][FoundationModel] turn-generation response received")
                return normalize(
                    response.content,
                    userText: userText,
                    firstPassResults: firstPassResults,
                    recentQuestions: recentQuestions,
                    completionState: completionState
                )
            } catch {
                print("[RAG][FoundationModel] turn-generation failed: \(error.localizedDescription)")
            }
        }
        #endif

        print("[RAG][FoundationModel] turn-generation fallback used")
        return fallbackTurn(
            userText: userText,
            firstPassResults: firstPassResults,
            recentQuestions: recentQuestions,
            completionState: completionState
        )
    }

    private func prompt(
        userText: String,
        firstPassResults: [FourLClassificationResult],
        analysisContext: RetrievedReflectionContext,
        sessionContext: RetrievedReflectionContext,
        recentQuestions: [String],
        completionState: ReflectionCompletionState
    ) -> String {
        let firstPassBlock = firstPassResults.map { result in
            let secondary = result.secondaryLabel.map { ", 보조=\($0)" } ?? ""
            return "- 문장: \(result.text)\n  1차 분류: \(result.label), 신뢰도=\(String(format: "%.2f", result.confidence))\(secondary)"
        }
        .joined(separator: "\n")
        let recentQuestionsBlock = recentQuestions.isEmpty
            ? "없음"
            : recentQuestions.enumerated().map { index, question in
                "\(index + 1). \(question)"
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
        - 최근에 했던 질문과 같은 표현이나 같은 초점을 반복하지 마라.
        - 이미 물은 질문을 다른 말로만 바꿔서 반복하지 마라.
        - 질문은 현재 발화에서 아직 더 구체화되지 않은 부분 하나만 파고들어라.
        - 현재 종료 상태 지침을 따른다: \(completionState.promptGuide)
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

        최근에 이미 한 질문:
        \(recentQuestionsBlock)
        """
    }

    #if canImport(FoundationModels)
    @available(iOS 26.0, *)
    private func normalize(
        _ payload: ReflectionGeneratedTurnPayload,
        userText: String,
        firstPassResults: [FourLClassificationResult],
        recentQuestions: [String],
        completionState: ReflectionCompletionState
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
        if isUsableQuestion(question, summary: validation.summary)
            && !isRepeatedQuestion(question, recentQuestions: recentQuestions) {
            resolvedQuestion = question
        } else {
            resolvedQuestion = fallbackQuestion(
                for: primaryDimension,
                recentQuestions: recentQuestions,
                userText: userText,
                completionState: completionState
            )
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
        firstPassResults: [FourLClassificationResult],
        recentQuestions: [String],
        completionState: ReflectionCompletionState
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
            question: fallbackQuestion(
                for: primaryDimension,
                recentQuestions: recentQuestions,
                userText: userText,
                completionState: completionState
            )
        )
    }

    nonisolated private static func mapDimension(from rawValue: String) -> ReflectionDimension? {
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

    nonisolated private static func mapLabelToDimension(_ label: String) -> ReflectionDimension? {
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

    private func fallbackQuestion(
        for dimension: ReflectionDimension?,
        recentQuestions: [String],
        userText: String,
        completionState: ReflectionCompletionState
    ) -> String {
        if completionState == .askForClosure {
            return "이 정도면 오늘 회고를 여기서 정리해도 괜찮을 것 같은데, 마무리할까?"
        }

        if completionState == .readyToWrapUp {
            return "지금까지 이야기한 걸 보면 꽤 정리된 것 같은데, 이번 회고에서 제일 크게 남는 한 가지는 뭐야?"
        }

        let candidates: [String]
        switch dimension {
        case .liked:
            candidates = [
                "그중에서 제일 인상 깊었던 순간이 뭐였어?",
                "그때 특히 좋다고 느낀 포인트는 뭐였어?",
                "그 장면이 왜 좋게 남았는지 말해줄래?"
            ]
        case .learned:
            candidates = [
                "그 일을 겪으면서 새로 알게 된 게 뭐였어?",
                "이번에 해보면서 배운 점이 있다면 뭐야?",
                "다음에도 써먹을 수 있겠다 싶은 깨달음이 있었어?"
            ]
        case .lacked:
            candidates = [
                "그때 어디서 제일 막혔어?",
                "가장 아쉽거나 부족하다고 느낀 부분은 뭐였어?",
                "흐름이 꼬이기 시작한 지점이 어디였어?"
            ]
        case .longedFor:
            candidates = [
                "그럼 다음엔 뭘 먼저 바꿔보고 싶어?",
                "다시 한다면 가장 먼저 손대고 싶은 건 뭐야?",
                "앞으로는 어떤 방향으로 풀어가고 싶어?"
            ]
        case nil:
            candidates = [
                "그때 제일 크게 남은 건 뭐였어?",
                "지금 돌아보면 가장 먼저 떠오르는 포인트가 뭐야?",
                "그 이야기에서 조금 더 풀어보고 싶은 부분이 있어?"
            ]
        }

        let recentNormalized = Set(recentQuestions.map(normalizeQuestion))
        if let fresh = candidates.first(where: { !recentNormalized.contains(normalizeQuestion($0)) }) {
            return fresh
        }

        let offset = abs(userText.hashValue) % candidates.count
        return candidates[offset]
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

    private func isRepeatedQuestion(_ question: String, recentQuestions: [String]) -> Bool {
        let normalized = normalizeQuestion(question)
        guard !normalized.isEmpty else { return true }
        return recentQuestions.map(normalizeQuestion).contains(normalized)
    }

    private func normalizeQuestion(_ text: String) -> String {
        text
            .lowercased()
            .replacingOccurrences(of: "?", with: "")
            .replacingOccurrences(of: "？", with: "")
            .replacingOccurrences(of: " ", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
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
