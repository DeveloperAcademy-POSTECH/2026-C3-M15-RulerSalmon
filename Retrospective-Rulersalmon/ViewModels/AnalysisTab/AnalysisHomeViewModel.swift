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
    @Published var selectedMode: SatisfactionChartMode = .weekly
    @Published var isPeriodSheetPresented = false

    private let referenceDate: Date
    private let dataProvider: AnalysisDataProviding

    convenience init(selectedDate: Date = Date()) {
        self.init(
            selectedDate: selectedDate,
            dataProvider: AnalysisSwiftDataProvider()
        )
    }

    init(
        selectedDate: Date = Date(),
        dataProvider: AnalysisDataProviding
    ) {
        let calendar = Calendar.current
        self.referenceDate = selectedDate
        self.selectedYear = calendar.component(.year, from: selectedDate)
        self.selectedMonth = calendar.component(.month, from: selectedDate)
        self.dataProvider = dataProvider
        normalizeSelectedPeriod()
    }

    var analysisReferenceDate: Date {
        referenceDate
    }

    var selectedData: MonthlyAnalysisData {
        dataProvider.data(
            year: selectedYear,
            month: selectedMonth,
            referenceDate: referenceDate
        )
    }

    var availableRange: PeriodRange {
        dataProvider.availableRange
    }

    func availableRange(from reports: [StoredReflectionReport]) -> PeriodRange {
        reportAvailableRange(from: reports) ?? availableRange
    }

    func emotionKeywords(from reports: [StoredReflectionReport]) -> [EmotionKeyword] {
        let selectedReports: [StoredReflectionReport]

        switch selectedMode {
        case .weekly:
            selectedReports = reportsInSelectedWeek(from: reports)
        case .monthly:
            selectedReports = reportsInMonth(
                from: reports,
                year: selectedYear,
                month: selectedMonth
            )
        }

        return topEmotionKeywords(from: selectedReports)
    }

    func showPeriodSheet() {
        isPeriodSheetPresented = true
    }

    func normalizeSelectedPeriod() {
        normalizeSelectedPeriod(with: availableRange)
    }

    func normalizeSelectedPeriod(for reports: [StoredReflectionReport]) {
        normalizeSelectedPeriod(with: availableRange(from: reports))
    }

    private func normalizeSelectedPeriod(with range: PeriodRange) {
        guard !range.contains(year: selectedYear, month: selectedMonth) else {
            return
        }

        selectedYear = range.end.year
        selectedMonth = range.end.month
    }

    private func reportsInMonth(
        from reports: [StoredReflectionReport],
        year: Int,
        month: Int,
        calendar: Calendar = .current
    ) -> [StoredReflectionReport] {
        reports.filter { report in
            let components = calendar.dateComponents([.year, .month], from: report.createdAt)
            return components.year == year && components.month == month
        }
    }

    private func reportsWithinDays(
        from reports: [StoredReflectionReport],
        days: Int,
        calendar: Calendar = .current
    ) -> [StoredReflectionReport] {
        guard let cutoff = calendar.date(byAdding: .day, value: -days, to: Date()) else {
            return []
        }

        return reports.filter { $0.createdAt >= cutoff }
    }

    private func reportsInSelectedWeek(
        from reports: [StoredReflectionReport],
        calendar: Calendar = .current
    ) -> [StoredReflectionReport] {
        let startDate = weekStartDate(containing: referenceDate, calendar: calendar)
        guard let endDate = calendar.date(byAdding: .day, value: 7, to: startDate) else {
            return []
        }

        return reports.filter { $0.createdAt >= startDate && $0.createdAt < endDate }
    }

    private func weekStartDate(containing date: Date, calendar: Calendar) -> Date {
        let day = calendar.startOfDay(for: date)
        let weekday = calendar.component(.weekday, from: day)
        let daysFromMonday = (weekday + 5) % 7
        return calendar.date(byAdding: .day, value: -daysFromMonday, to: day) ?? day
    }

    private func topEmotionKeywords(from reports: [StoredReflectionReport], limit: Int = 5) -> [EmotionKeyword] {
        var counts: [String: Int] = [:]

        reports
            .flatMap { splitKeywords($0.emotionKeywordsRaw) }
            .forEach { keyword in
                counts[keyword, default: 0] += 1
            }

        return counts
            .sorted { lhs, rhs in
                if lhs.value == rhs.value {
                    return lhs.key < rhs.key
                }

                return lhs.value > rhs.value
            }
            .prefix(limit)
            .map { EmotionKeyword(title: $0.key, count: $0.value) }
    }

    private func reportAvailableRange(
        from reports: [StoredReflectionReport],
        calendar: Calendar = .current
    ) -> PeriodRange? {
        let yearMonths = reports.map { report in
            let components = calendar.dateComponents([.year, .month], from: report.createdAt)
            return YearMonth(
                year: components.year ?? calendar.component(.year, from: Date()),
                month: components.month ?? calendar.component(.month, from: Date())
            )
        }

        guard let start = yearMonths.min(by: { lhs, rhs in yearMonthValue(lhs) < yearMonthValue(rhs) }),
              let end = yearMonths.max(by: { lhs, rhs in yearMonthValue(lhs) < yearMonthValue(rhs) }) else {
            return nil
        }

        return PeriodRange(start: start, end: end)
    }

    private func splitKeywords(_ rawValue: String) -> [String] {
        rawValue
            .split(separator: "|")
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private func yearMonthValue(_ yearMonth: YearMonth) -> Int {
        yearMonth.year * 100 + yearMonth.month
    }
}
