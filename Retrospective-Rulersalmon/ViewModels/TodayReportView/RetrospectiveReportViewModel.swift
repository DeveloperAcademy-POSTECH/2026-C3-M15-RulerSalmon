//
//  RetrospectiveReportViewModel.swift
//  Retrospective-Rulersalmon
//
//  Created by dlsundn on 6/9/26.
//

import Foundation
import Combine

enum RetrospectiveReportDisplayStyle {
    case today
    case archived(navigationTitle: String)
}

@MainActor
final class RetrospectiveReportViewModel: ObservableObject {
    @Published private(set) var report: RetrospectiveReport
    private let displayStyle: RetrospectiveReportDisplayStyle

    init(
        report: RetrospectiveReport,
        displayStyle: RetrospectiveReportDisplayStyle = .today
    ) {
        self.report = report
        self.displayStyle = displayStyle
    }

    var navigationTitle: String {
        switch displayStyle {
        case .today:
            return "오늘의 회고"
        case .archived(let navigationTitle):
            return navigationTitle
        }
    }

    var summaryTitle: String {
        switch displayStyle {
        case .today:
            return "오늘 회고 요약"
        case .archived:
            return "회고 요약"
        }
    }

    var fourLTitle: String {
        switch displayStyle {
        case .today:
            return "오늘의 4L 회고"
        case .archived:
            return "4L 회고"
        }
    }

    var keywordTitle: String {
        "핵심 키워드"
    }

    var actionItemTitle: String {
        switch displayStyle {
        case .today:
            return "내일의 Action Item"
        case .archived:
            return "Action Item"
        }
    }

    var transcriptLinkTitle: String {
        "전사문 보기 >"
    }

    var emptyActionItemMessage: String {
        "추천할 Action Item이 없어요."
    }

    var summary: String {
        report.summary
    }

    var transcript: String {
        report.transcript
    }

    var fourLEntries: [FourLEntry] {
        report.fourLEntries
    }

    var keywords: [String] {
        report.keywords
    }

    var actionItems: [String] {
        report.actionItems
    }

    var hasActionItems: Bool {
        !actionItems.isEmpty
    }
}
