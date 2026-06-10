//
//  ReflectionSummaryService.swift
//  Retrospective-Rulersalmon
//
//  Created by dlsundn on 6/3/26.
//

import Foundation

struct ReflectionSummaryResult: Equatable {
    let refinedReflection: String
    let todaySummary: String
    let actionItems: [String]
    let coreKeywords: [String]
    let emotionKeywords: [String]
}

final class ReflectionSummaryService {
    private let reflectionModelService: ReflectionFoundationModelService

    init(reflectionModelService: ReflectionFoundationModelService = ReflectionFoundationModelService()) {
        self.reflectionModelService = reflectionModelService
    }

    func summarize(
        messages: [ChatMessage],
        results: [FourLClassificationResult],
        refinedTexts: [UUID: String]
    ) async -> ReflectionSummaryResult? {
        let userOnlyText = makeUserOnlyText(from: messages)
        let longedForText = makeLongedForText(from: results, refinedTexts: refinedTexts)
        let lackedText = makeLackedText(from: results, refinedTexts: refinedTexts)

        do {
            let refinementOutput = try await reflectionModelService.generateRefinedReflection(
                userOnlyText: userOnlyText
            )
            let summaryOutput = try await reflectionModelService.generateTodaySummary(
                userOnlyText: userOnlyText
            )
            let coreKeywordOutput = try await reflectionModelService.generateCoreKeywords(
                userOnlyText: userOnlyText
            )
            let emotionKeywordOutput = try await reflectionModelService.generateEmotionKeywords(
                userOnlyText: userOnlyText
            )
            let actionItems: [String]
            if longedForText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                lackedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                actionItems = []
            } else {
                let actionItemOutput = try await reflectionModelService.generateActionItems(
                    longedForText: longedForText,
                    lackedText: lackedText
                )
                actionItems = cleanedActionItems(actionItemOutput.actionItems)
            }

            return ReflectionSummaryResult(
                refinedReflection: refinementOutput.refinedReflection.trimmingCharacters(in: .whitespacesAndNewlines),
                todaySummary: summaryOutput.todaySummary.trimmingCharacters(in: .whitespacesAndNewlines),
                actionItems: actionItems,
                coreKeywords: cleanedKeywords(coreKeywordOutput.coreKeywords),
                emotionKeywords: cleanedKeywords(emotionKeywordOutput.emotionKeywords)
            )
        } catch {
            print("🔴 ReflectionSummaryService summarize error:", error)
            return nil
        }
    }

    private func makeUserOnlyText(from messages: [ChatMessage]) -> String {
        messages
            .filter { $0.role == .user }
            .map(\.text)
            .joined(separator: "\n")
    }

    private func makeLongedForText(
        from results: [FourLClassificationResult],
        refinedTexts: [UUID: String]
    ) -> String {
        results
            .filter { $0.label == FourLService.fourLLabels[3] && $0.isFourLRelated }
            .map { result in refinedTexts[result.id] ?? result.text }
            .joined(separator: "\n")
    }

    private func makeLackedText(
        from results: [FourLClassificationResult],
        refinedTexts: [UUID: String]
    ) -> String {
        results
            .filter { $0.label == FourLService.fourLLabels[2] && $0.isFourLRelated }
            .map { result in refinedTexts[result.id] ?? result.text }
            .joined(separator: "\n")
    }

    private func cleaned(_ items: [String]) -> [String] {
        items
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private func cleanedKeywords(_ items: [String]) -> [String] {
        unique(
            cleaned(items)
                .map { $0.replacingOccurrences(of: "#", with: "") }
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .filter { wordCount($0) <= 2 }
                .filter { $0.count <= 10 }
                .filter { !containsLongEnglish($0) }
        )
        .prefix(5)
        .map { $0 }
    }

    private func cleanedActionItems(_ items: [String]) -> [String] {
        unique(
            cleaned(items)
                .map { normalizedActionItem($0) }
                .filter { !$0.isEmpty }
                .filter { $0.hasSuffix("하기") }
                .filter { $0.count <= 24 }
                .filter { !isGenericActionItem($0) }
        )
        .prefix(3)
        .map { $0 }
    }

    private func normalizedActionItem(_ item: String) -> String {
        var text = item
            .replacingOccurrences(of: "#", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if let range = text.range(of: #"^\d+[\.\)]\s*"#, options: .regularExpression) {
            text.removeSubrange(range)
        }

        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }


    private func containsLongEnglish(_ text: String) -> Bool {
        text.range(of: #"[A-Za-z]{6,}"#, options: .regularExpression) != nil
    }

    private func isGenericActionItem(_ text: String) -> Bool {
        let genericItems: Set<String> = [
            "앱 사용하기",
            "일정 확인하기",
            "업무량 관리하기",
            "업무 우선순위 정하기",
            "우선순위 정하기",
            "시간 관리하기",
            "목표 세우기",
            "열심히 하기",
            "계획 세우기"
        ]

        return genericItems.contains(text)
    }

    private func unique(_ items: [String]) -> [String] {
        var seen = Set<String>()

        return items.filter { item in
            seen.insert(item).inserted
        }
    }

    private func wordCount(_ text: String) -> Int {
        text
            .split(whereSeparator: { $0.isWhitespace })
            .count
    }
}
