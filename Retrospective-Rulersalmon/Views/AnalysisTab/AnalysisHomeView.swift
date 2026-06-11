//
//  AnalysisHomeView.swift
//
//  Created by magic3ightball on 6/7/26.
//

import SwiftUI
import SwiftData

struct AnalysisHomeView: View {
    @StateObject private var viewModel = AnalysisHomeViewModel()

    @Query(sort: \StoredReflectionReport.createdAt, order: .reverse)
    private var storedReports: [StoredReflectionReport]
    @Query(sort: \SentimentRecord.createdAt, order: .reverse)
    private var storedSentiments: [SentimentRecord]
    @Query(sort: \ReflectionInsightRecord.updatedAt, order: .reverse)
    private var storedInsights: [ReflectionInsightRecord]

    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea(.all)

            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 32) {
                    PeriodSelectorButton(
                        year: viewModel.selectedYear,
                        month: viewModel.selectedMonth
                    ) {
                        viewModel.showPeriodSheet()
                    }

                    MonthlySatisfactionSummaryCard(
                        label: viewModel.satisfactionLabel,
                        score: viewModel.satisfactionScore,
                        title: viewModel.satisfactionTitle
                    )

                    SatisfactionTrendSection(
                        data: viewModel.selectedData,
                        year: viewModel.selectedYear,
                        month: viewModel.selectedMonth,
                        referenceDate: viewModel.analysisReferenceDate,
                        selectedMode: $viewModel.selectedMode,
                        selectedWeekStartDate: $viewModel.selectedWeekStartDate,
                        weekOptions: viewModel.weekOptions()
                    )
                    SentimentRatioSection(
                        positivePercentage: viewModel.positivePercentage,
                        negativePercentage: viewModel.negativePercentage
                    )
                    EmotionKeywordSection(keywords: viewModel.emotionKeywordStatistics)
                    InsightListSection(insights: viewModel.insightItems)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, AnalysisHomeLayout.screenPadding)
                .padding(.top, 16)
                .padding(.bottom, 36)
            }
        }
        .onAppear {
            refreshAnalysisState()
        }
        .onChange(of: viewModel.selectedYear) { _, _ in
            refreshAnalysisState()
        }
        .onChange(of: viewModel.selectedMonth) { _, _ in
            refreshAnalysisState()
        }
        .onChange(of: viewModel.selectedMode) { _, _ in
            refreshAnalysisState()
        }
        .onChange(of: viewModel.selectedWeekStartDate) { _, _ in
            refreshAnalysisState(shouldNormalizeSelection: false)
        }
        .onChange(of: storedReports.count) { _, _ in
            refreshAnalysisState()
        }
        .onChange(of: storedSentiments.count) { _, _ in
            refreshAnalysisState()
        }
        .onChange(of: storedInsights.count) { _, _ in
            refreshAnalysisState()
        }
        .sheet(isPresented: $viewModel.isPeriodSheetPresented) {
            PeriodSelectionSheet(
                selectedYear: $viewModel.selectedYear,
                selectedMonth: $viewModel.selectedMonth,
                availableRange: viewModel.currentAvailableRange,
                isPresented: $viewModel.isPeriodSheetPresented
            )
            .presentationDetents([.height(300)])
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("회고 분석")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Color.gray900)
            }
        }
        .toolbarBackground(Color.white, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    private func refreshAnalysisState(shouldNormalizeSelection: Bool = true) {
        viewModel.refresh(
            reports: storedReports,
            sentiments: storedSentiments,
            insights: storedInsights,
            shouldNormalizeSelection: shouldNormalizeSelection
        )
    }
}

struct AnalysisHomeView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            AnalysisHomeView()
        }
    }
}
