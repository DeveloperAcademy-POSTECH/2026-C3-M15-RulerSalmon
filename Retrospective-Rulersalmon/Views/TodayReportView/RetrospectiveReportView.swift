//
//  RetrospectiveReportView.swift
//  Retrospective-Rulersalmon
//
//  Created by Steve on 6/8/26.
//

import SwiftUI

struct RetrospectiveReportView: View {
    @StateObject private var viewModel: RetrospectiveReportViewModel
    private let onClose: (() -> Void)?

    @Environment(\.dismiss) private var dismiss

    init(
        report: RetrospectiveReport = .mock,
        displayStyle: RetrospectiveReportDisplayStyle = .today,
        onClose: (() -> Void)? = nil
    ) {
        _viewModel = StateObject(
            wrappedValue: RetrospectiveReportViewModel(
                report: report,
                displayStyle: displayStyle
            )
        )
        self.onClose = onClose
    }

    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea(.all)

            VStack(spacing: 0) {
                ReportNavigationBar(title: viewModel.navigationContent.title) {
                    if let onClose {
                        onClose()
                    } else {
                        dismiss()
                    }
                }

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {
                        SummaryCard(
                            content: viewModel.summaryCard,
                            transcriptNavigationTitle: viewModel.transcriptNavigationTitle
                        )
                        FourLCard(content: viewModel.fourLCard)
                        KeywordSection(content: viewModel.keywordSection)
                        ActionItemCard(
                            content: viewModel.actionItemCard
                        )
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, ReportLayout.screenPadding)
                    .padding(.top, 18)
                    .padding(.bottom, 40)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}

struct RetrospectiveReportView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            RetrospectiveReportView()
        }
    }
}
