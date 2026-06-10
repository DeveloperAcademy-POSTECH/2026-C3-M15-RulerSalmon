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

struct ReportNavigationContent {
    let title: String
}

struct ReportSummaryCardContent {
    let title: String
    let summary: String
    let transcript: String
    let transcriptLinkTitle: String
}

struct ReportFourLCardContent {
    let title: String
    let entries: [FourLEntry]
}

struct ReportKeywordSectionContent {
    let title: String
    let keywords: [String]
}

struct ReportActionItemRowContent: Identifiable {
    let id: Int
    let number: Int
    let text: String
}

struct ReportActionItemCardContent {
    let title: String
    let rows: [ReportActionItemRowContent]
    let emptyMessage: String
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

    var navigationContent: ReportNavigationContent {
        ReportNavigationContent(title: navigationTitle)
    }

    var summaryCard: ReportSummaryCardContent {
        ReportSummaryCardContent(
            title: summaryTitle,
            summary: report.summary,
            transcript: report.transcript,
            transcriptLinkTitle: transcriptLinkTitle
        )
    }

    var fourLCard: ReportFourLCardContent {
        ReportFourLCardContent(
            title: fourLTitle,
            entries: report.fourLEntries
        )
    }

    var keywordSection: ReportKeywordSectionContent {
        ReportKeywordSectionContent(
            title: keywordTitle,
            keywords: report.keywords
        )
    }

    var actionItemCard: ReportActionItemCardContent {
        ReportActionItemCardContent(
            title: actionItemTitle,
            rows: report.actionItems.enumerated().map {
                ReportActionItemRowContent(
                    id: $0.offset,
                    number: $0.offset + 1,
                    text: $0.element
                )
            },
            emptyMessage: emptyActionItemMessage
        )
    }

    var transcriptNavigationTitle: String {
        "전사문"
    }

    private var navigationTitle: String {
        switch displayStyle {
        case .today:
            return "오늘의 회고"
        case .archived(let navigationTitle):
            return navigationTitle
        }
    }

    private var summaryTitle: String {
        switch displayStyle {
        case .today:
            return "오늘 회고 요약"
        case .archived:
            return "회고 요약"
        }
    }

    private var fourLTitle: String {
        switch displayStyle {
        case .today:
            return "오늘의 4L 회고"
        case .archived:
            return "4L 회고"
        }
    }

    private var keywordTitle: String {
        "핵심 키워드"
    }

    private var actionItemTitle: String {
        switch displayStyle {
        case .today:
            return "내일의 Action Item"
        case .archived:
            return "Action Item"
        }
    }

    private var transcriptLinkTitle: String {
        "전사문 보기"
    }

    private var emptyActionItemMessage: String {
        "추천할 Action Item이 없어요."
    }
}
