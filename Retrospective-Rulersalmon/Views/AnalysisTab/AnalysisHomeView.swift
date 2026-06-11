//
//  AnalysisHomeView.swift
//
//  Created by magic3ightball on 6/7/26.
//

import SwiftUI
import SwiftData

struct AnalysisHomeView: View {
    @StateObject private var viewModel = AnalysisHomeViewModel()
    @State private var isBackfillingInsights = false

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
        .onChange(of: storedInsightsFingerprint) { _, _ in
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
        backfillInsightsIfNeeded()
    }

    private var storedInsightsFingerprint: String {
        storedInsights
            .map { insight in
                [
                    insight.id.uuidString,
                    insight.scope,
                    insight.title,
                    String(insight.count),
                    String(insight.updatedAt.timeIntervalSince1970)
                ].joined(separator: ":")
            }
            .joined(separator: "|")
    }

    private func backfillInsightsIfNeeded() {
        guard !isBackfillingInsights else { return }

        let calendar = Calendar.current
        let monthlyRecords = sentimentRecordsInMonth(
            storedSentiments,
            year: viewModel.selectedYear,
            month: viewModel.selectedMonth,
            calendar: calendar
        )
        let shouldBackfillMonthly = monthlyRecords.count >= 3 &&
            !hasInsights(scope: "monthly", inMonthOf: calendar.date(from: DateComponents(year: viewModel.selectedYear, month: viewModel.selectedMonth)) ?? Date(), calendar: calendar)

        let weeklyRecords: [SentimentRecord]
        let weekStartDate = viewModel.selectedWeekStartDate
        if let weekStartDate,
           let weekEndDate = calendar.date(byAdding: .day, value: 7, to: weekStartDate) {
            weeklyRecords = storedSentiments.filter { $0.createdAt >= weekStartDate && $0.createdAt < weekEndDate }
        } else {
            weeklyRecords = []
        }
        let shouldBackfillWeekly = weeklyRecords.count >= 3 &&
            !hasInsights(scope: "weekly", inWeekStarting: weekStartDate, calendar: calendar)

        guard shouldBackfillMonthly || shouldBackfillWeekly else { return }

        isBackfillingInsights = true
        Task { @MainActor in
            let insightService = ReflectionInsightService()
            let dataStore = AppDataStore.shared

            if shouldBackfillWeekly, let weekStartDate {
                await backfillInsights(
                    records: weeklyRecords,
                    scope: "weekly",
                    periodStartDate: weekStartDate,
                    periodEndDate: calendar.date(byAdding: .day, value: 7, to: weekStartDate) ?? weekStartDate,
                    days: 7,
                    referenceDate: calendar.date(byAdding: .day, value: 6, to: weekStartDate) ?? weekStartDate,
                    insightService: insightService,
                    dataStore: dataStore
                )
            }

            if shouldBackfillMonthly,
               let monthStartDate = calendar.date(from: DateComponents(year: viewModel.selectedYear, month: viewModel.selectedMonth)),
               let monthEndDate = calendar.date(byAdding: .month, value: 1, to: monthStartDate) {
                await backfillInsights(
                    records: monthlyRecords,
                    scope: "monthly",
                    periodStartDate: monthStartDate,
                    periodEndDate: monthEndDate,
                    days: calendar.dateComponents([.day], from: monthStartDate, to: monthEndDate).day ?? 30,
                    referenceDate: calendar.date(byAdding: .day, value: -1, to: monthEndDate) ?? monthStartDate,
                    insightService: insightService,
                    dataStore: dataStore
                )
            }

            isBackfillingInsights = false
        }
    }

    private func backfillInsights(
        records: [SentimentRecord],
        scope: String,
        periodStartDate: Date,
        periodEndDate: Date,
        days: Int,
        referenceDate: Date,
        insightService: ReflectionInsightService,
        dataStore: AppDataStore
    ) async {
        do {
            let result = try await insightService.generateInsights(
                from: records.map(\.asInsightSourceRecord),
                days: days,
                minimumRepeatCount: 3,
                referenceDate: referenceDate
            )
            dataStore.replaceInsights(
                with: result,
                scope: scope,
                periodStartDate: periodStartDate,
                periodEndDate: periodEndDate,
                updatedAt: referenceDate,
                sourceRecordIDs: records.map(\.id)
            )
        } catch {
            #if DEBUG
            print("[AnalysisHomeView] \(scope) insight backfill failed: \(error)")
            #endif
        }
    }

    private func hasInsights(
        scope: String,
        inWeekStarting startDate: Date?,
        calendar: Calendar
    ) -> Bool {
        guard let startDate,
              let endDate = calendar.date(byAdding: .day, value: 7, to: startDate) else {
            return false
        }

        return storedInsights.contains {
            $0.scope == scope &&
                $0.updatedAt >= startDate &&
                $0.updatedAt < endDate
        }
    }

    private func hasInsights(
        scope: String,
        inMonthOf date: Date,
        calendar: Calendar
    ) -> Bool {
        let selectedComponents = calendar.dateComponents([.year, .month], from: date)

        return storedInsights.contains { insight in
            let components = calendar.dateComponents([.year, .month], from: insight.updatedAt)
            return insight.scope == scope &&
                components.year == selectedComponents.year &&
                components.month == selectedComponents.month
        }
    }

    private func sentimentRecordsInMonth(
        _ records: [SentimentRecord],
        year: Int,
        month: Int,
        calendar: Calendar
    ) -> [SentimentRecord] {
        records.filter { record in
            let components = calendar.dateComponents([.year, .month], from: record.createdAt)
            return components.year == year && components.month == month
        }
    }
}

private extension SentimentRecord {
    var asInsightSourceRecord: ReflectionInsightSourceRecord {
        ReflectionInsightSourceRecord(
            id: id,
            createdAt: createdAt,
            transcript: transcript,
            positivePercentage: positivePercentage,
            negativePercentage: negativePercentage,
            satisfactionScore: satisfactionScore
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
