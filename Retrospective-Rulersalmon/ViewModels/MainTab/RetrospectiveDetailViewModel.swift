//
//  RetrospectiveDetailViewModel.swift
//  Retrospective-Rulersalmon
//
//  Created by DevPaul on 6/11/26.
//

import Combine
import Foundation
import SwiftUI

@MainActor
final class RetrospectiveDetailViewModel: ObservableObject {
    @Published private(set) var report: RetrospectiveReport?

    let item: RetrospectiveItem
    private let dataStore: AppDataStore

    init(item: RetrospectiveItem, dataStore: AppDataStore? = nil) {
        self.item = item
        self.dataStore = dataStore ?? .shared
        loadReport()
    }

    func loadReport() {
        guard let storedReport = dataStore.loadStoredReport(id: item.id) else {
            report = nil
            return
        }

        report = RetrospectiveReport(storedReport: storedReport)
    }
}

private extension RetrospectiveReport {
    init(storedReport: StoredReflectionReport) {
        summary = storedReport.todaySummary
        transcript = storedReport.refinedReflection
        transcriptMessages = storedReport.decodedConversationMessages
        fourLEntries = storedReport.fourLItemsRaw
            .split(separator: "|")
            .compactMap { segment -> FourLEntry? in
                let parts = segment.split(separator: ":", maxSplits: 1).map(String.init)
                guard parts.count == 2 else { return nil }
                let title = parts[0]
                return FourLEntry(
                    title: title,
                    icon: title.fourLIcon,
                    tintColor: title.fourLTintColor,
                    content: parts[1]
                )
            }
        keywords = storedReport.coreKeywordsRaw.components(separatedBy: "|").filter(\.isNotEmpty)
        emotionKeywords = storedReport.emotionKeywordsRaw.components(separatedBy: "|").filter(\.isNotEmpty)
        actionItems = storedReport.actionItemsRaw.components(separatedBy: "|").filter(\.isNotEmpty)
    }
}

private extension StoredReflectionReport {
    var decodedConversationMessages: [ChatMessage] {
        guard let data = conversationMessagesRaw.data(using: .utf8),
              let messages = try? JSONDecoder().decode([ChatMessage].self, from: data) else {
            return fallbackConversationMessages
        }

        let visibleMessages = messages.filter { $0.text.trimmingCharacters(in: .whitespacesAndNewlines).isNotEmpty }
        return visibleMessages.isEmpty ? fallbackConversationMessages : visibleMessages
    }

    var fallbackConversationMessages: [ChatMessage] {
        let paragraphs = refinedReflection.reflectionParagraphs

        guard !paragraphs.isEmpty else { return [] }

        return paragraphs.enumerated().flatMap { index, paragraph in
            [
                ChatMessage(role: .assistant, text: fallbackQuestion(at: index), date: createdAt),
                ChatMessage(role: .user, text: paragraph, date: createdAt)
            ]
        }
    }

    func fallbackQuestion(at index: Int) -> String {
        let questions = [
            "이 날 가장 먼저 떠오른 장면은 무엇이었나요?",
            "그 과정에서 좋았거나 배운 점은 무엇이었나요?",
            "조금 아쉬웠거나 부족하게 느낀 부분은 무엇이었나요?",
            "다음에는 어떤 방향으로 해보고 싶나요?"
        ]

        return questions[min(index, questions.count - 1)]
    }
}

private extension String {
    var reflectionParagraphs: [String] {
        components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter(\.isNotEmpty)
    }

    var fourLIcon: String {
        switch lowercased() {
        case "liked":
            return "😀"
        case "learned":
            return "📘"
        case "lacked":
            return "📉"
        case "longed for":
            return "☘️"
        default:
            return "📝"
        }
    }

    var fourLTintColor: Color {
        switch lowercased() {
        case "liked":
            return Color.blue50
        case "learned":
            return Color.purple.opacity(0.12)
        case "lacked":
            return Color.yellow.opacity(0.18)
        case "longed for":
            return Color.green.opacity(0.12)
        default:
            return Color.gray100
        }
    }

    var isNotEmpty: Bool {
        !trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
