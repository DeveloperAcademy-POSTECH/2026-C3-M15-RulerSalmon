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

private extension String {
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
