//
//  AnalysisHomeViewModel.swift
//
//  Created by magic3ightball on 6/9/26.
//

import Combine
import Foundation

@MainActor
final class AnalysisHomeViewModel: ObservableObject {
    @Published var selectedYear: Int
    @Published var selectedMonth: Int
    @Published var isPeriodSheetPresented = false

    private let dataProvider: AnalysisDataProviding

    init(
        selectedDate: Date = Date(),
        dataProvider: AnalysisDataProviding = AnalysisMockDataProvider()
    ) {
        let calendar = Calendar.current
        self.selectedYear = calendar.component(.year, from: selectedDate)
        self.selectedMonth = calendar.component(.month, from: selectedDate)
        self.dataProvider = dataProvider
        normalizeSelectedPeriod()
    }

    var selectedData: MonthlyAnalysisData {
        dataProvider.data(
            year: selectedYear,
            month: selectedMonth
        )
    }

    var availableRange: PeriodRange {
        dataProvider.availableRange
    }

    func showPeriodSheet() {
        isPeriodSheetPresented = true
    }

    func normalizeSelectedPeriod() {
        guard !availableRange.contains(year: selectedYear, month: selectedMonth) else {
            return
        }

        selectedYear = availableRange.end.year
        selectedMonth = availableRange.end.month
    }
}
