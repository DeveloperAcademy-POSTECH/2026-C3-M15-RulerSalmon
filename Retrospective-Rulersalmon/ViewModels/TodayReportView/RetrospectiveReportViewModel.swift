//
//  RetrospectiveReportViewModel.swift
//  Retrospective-Rulersalmon
//
//  Created by dlsundn on 6/9/26.
//

import Foundation
import Combine

@MainActor
final class RetrospectiveReportViewModel: ObservableObject {
    @Published private(set) var report: RetrospectiveReport

    let navigationTitle = "오늘의 회고"
    let summaryTitle = "오늘 회고 요약"
    let fourLTitle = "오늘의 4L 회고"
    let keywordTitle = "핵심 키워드"
    let actionItemTitle = "내일의 Action Item"
    let transcriptLinkTitle = "전사문 보기 >"
    let emptyActionItemMessage = "추천할 Action Item이 없어요."

    init(report: RetrospectiveReport) {
        self.report = report
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
