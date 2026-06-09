//
//  RetrospectiveAnalysisView.swift
//  Retrospective-Rulersalmon
//
//  Created by dlsundn on 6/9/26.
//

import SwiftUI

struct RetrospectiveAnalysisView: View {
    @StateObject private var viewModel: RetrospectiveAnalysisViewModel
    private let onExitToMain: (() -> Void)?

    init(messages: [ChatMessage], onExitToMain: (() -> Void)? = nil) {
        _viewModel = StateObject(wrappedValue: RetrospectiveAnalysisViewModel(messages: messages))
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
                RetrospectiveProcessingView(progress: .constant(viewModel.progress))
            }
        }
        .task {
            viewModel.generateResults()
        }
        .navigationDestination(isPresented: $viewModel.isShowingReport) {
            if let completedReport = viewModel.completedReport {
                RetrospectiveReportView(
                    report: completedReport,
                    onClose: onExitToMain
                )
            }
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
