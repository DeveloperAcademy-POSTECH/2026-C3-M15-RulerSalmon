//
//  RetrospectiveAnalysisView.swift
//  Retrospective-Rulersalmon
//
//  Created by dlsundn on 6/9/26.
//

import SwiftUI

struct RetrospectiveAnalysisView: View {
    @StateObject private var viewModel: FourLResultViewModel
    @State private var completedReport: RetrospectiveReport?
    @State private var isShowingReport = false
    private let onExitToMain: (() -> Void)?

    init(messages: [ChatMessage], onExitToMain: (() -> Void)? = nil) {
        _viewModel = StateObject(wrappedValue: FourLResultViewModel(messages: messages))
        self.onExitToMain = onExitToMain
    }

    var body: some View {
        ZStack {
            Color.gray50
                .ignoresSafeArea(.all)

            if let errorMessage = viewModel.errorMessage {
                ContentUnavailableView(
                    "회고 분석 실패",
                    systemImage: "exclamationmark.triangle",
                    description: Text(errorMessage)
                )
            } else {
                RetrospectiveProcessingView(progress: .constant(progress))
            }
        }
        .task {
            viewModel.generateResults()
        }
        .onChange(of: isReportReady) { _, newValue in
            guard newValue, let report else { return }
            completedReport = report
            isShowingReport = true
        }
        .navigationDestination(isPresented: $isShowingReport) {
            if let completedReport {
                RetrospectiveReportView(
                    report: completedReport,
                    onClose: onExitToMain
                )
            }
        }
    }

    private var isReportReady: Bool {
        report != nil
    }

    private var report: RetrospectiveReport? {
        guard let summaryResult = viewModel.summaryResult,
              !viewModel.isRefining,
              !viewModel.isGeneratingSummary else {
            return nil
        }

        return RetrospectiveReport(
            summary: summaryResult.todaySummary,
            transcript: summaryResult.refinedReflection,
            fourLEntries: fourLEntries,
            keywords: summaryResult.coreKeywords,
            actionItems: summaryResult.actionItems
        )
    }

    private var progress: Double {
        if viewModel.isGeneratingSummary {
            return 0.88
        }

        if viewModel.isRefining {
            return 0.64
        }

        if !viewModel.results.isEmpty {
            return 0.42
        }

        return 0.18
    }

    private var fourLEntries: [FourLEntry] {
        let order = ["Liked", "Longed for", "Lacked", "Learned"]
        let groupedResults = viewModel.topResultsByFourL()

        return order.map { label in
            let result = groupedResults[label]?.first
            let content = result.flatMap { viewModel.refinedTexts[$0.id] } ?? result?.text ?? emptyMessage(for: label)

            return FourLEntry(
                title: label,
                icon: icon(for: label),
                tintColor: tintColor(for: label),
                content: content
            )
        }
    }

    private func emptyMessage(for label: String) -> String {
        switch label {
        case "Liked":
            return "오늘은 좋았던 점이 뚜렷하게 기록되지 않았어요."
        case "Longed for":
            return "오늘은 더 바랐던 점이 뚜렷하게 기록되지 않았어요."
        case "Lacked":
            return "오늘은 아쉬웠던 점이 뚜렷하게 기록되지 않았어요."
        case "Learned":
            return "오늘은 새롭게 배운 점이 뚜렷하게 기록되지 않았어요."
        default:
            return "해당 회고 문장이 기록되지 않았어요."
        }
    }

    private func icon(for label: String) -> String {
        switch label {
        case "Liked":
            return "😀"
        case "Longed for":
            return "☘️"
        case "Lacked":
            return "📉"
        case "Learned":
            return "📘"
        default:
            return "•"
        }
    }

    private func tintColor(for label: String) -> Color {
        switch label {
        case "Liked":
            return Color.yellow.opacity(0.18)
        case "Longed for":
            return Color.green.opacity(0.12)
        case "Lacked":
            return Color.blue50
        case "Learned":
            return Color.purple.opacity(0.12)
        default:
            return Color.gray50
        }
    }
}

struct RetrospectiveAnalysisView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            RetrospectiveAnalysisView(messages: [
                ChatMessage(role: .assistant, text: "오늘 회고를 같이 정리해볼까요?"),
                ChatMessage(role: .user, text: "오늘은 회의 준비를 잘해서 좋았고, 일정 관리는 조금 부족했어요. 내일은 작업 순서를 먼저 정하고 싶어요.")
            ])
        }
    }
}
