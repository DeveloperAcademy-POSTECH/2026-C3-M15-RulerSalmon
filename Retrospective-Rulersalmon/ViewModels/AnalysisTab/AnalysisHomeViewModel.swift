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
    @Published var selectedWeekStartDate: Date?
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
            weekStartDate: selectedWeekStartDate,
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
            selectedReports = reportsInSelectedWeek(from: reports, weekStartDate: selectedWeekStartDate)
        case .monthly:
            selectedReports = reportsInMonth(
                from: reports,
                year: selectedYear,
                month: selectedMonth
            )
        }

        return topEmotionKeywords(from: selectedReports)
    }

    func insights(from records: [ReflectionInsightRecord]) -> [AnalysisInsightItem] {
        let uniqueInsights = uniqueInsightsByTitle(filteredInsights(from: records))
        let reflectionInsights = uniqueInsights
            .filter { $0.kind == "reflection" }
            .sorted(by: insightSort)
            .prefix(2)
        let strengthInsights = uniqueInsights
            .filter { $0.kind == "strength" }
            .sorted(by: insightSort)
            .prefix(2)

        return (Array(reflectionInsights) + Array(strengthInsights))
            .map { record in
                AnalysisInsightItem(
                    id: record.id,
                    kind: record.kind,
                    title: record.title,
                    description: record.insightDescription,
                    count: record.count
                )
            }
    }

    private func uniqueInsightsByTitle(
        _ records: [ReflectionInsightRecord]
    ) -> [ReflectionInsightRecord] {
        var seenTitles = Set<String>()

        return records.filter { record in
            let key = normalizedInsightTitle(record.title)
            guard !seenTitles.contains(key) else { return false }

            seenTitles.insert(key)
            return true
        }
    }

    private func insightSort(
        _ lhs: ReflectionInsightRecord,
        _ rhs: ReflectionInsightRecord
    ) -> Bool {
        if lhs.count == rhs.count {
            return lhs.title < rhs.title
        }

        return lhs.count > rhs.count
    }

    private func normalizedInsightTitle(_ title: String) -> String {
        title
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }

    func weekOptions() -> [AnalysisWeekOption] {
        let calendar = analysisCalendar
        guard let monthStartDate = calendar.date(from: DateComponents(year: selectedYear, month: selectedMonth, day: 1)),
              let nextMonthDate = calendar.date(byAdding: .month, value: 1, to: monthStartDate) else {
            return []
        }

        var startDate = weekStartDate(containing: monthStartDate, calendar: calendar)
        var options: [AnalysisWeekOption] = []

        while startDate < nextMonthDate {
            let endDate = calendar.date(byAdding: .day, value: 6, to: startDate) ?? startDate
            options.append(
                AnalysisWeekOption(
                    startDate: startDate,
                    title: weekTitle(startDate: startDate, endDate: endDate, calendar: calendar)
                )
            )

            guard let nextWeek = calendar.date(byAdding: .day, value: 7, to: startDate) else {
                break
            }
            startDate = nextWeek
        }

        return options
    }

    func normalizeSelectedWeek(from records: [SentimentRecord]) {
        let options = weekOptions()
        guard !options.isEmpty else {
            selectedWeekStartDate = nil
            return
        }

        if let selectedWeekStartDate,
           options.contains(where: { Calendar.current.isDate($0.startDate, inSameDayAs: selectedWeekStartDate) }) {
            return
        }

        selectedWeekStartDate = defaultWeekStartDate(from: records) ?? options.first?.startDate
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

    private func reportsInSelectedWeek(
        from reports: [StoredReflectionReport],
        weekStartDate: Date?,
        calendar: Calendar = .current
    ) -> [StoredReflectionReport] {
        guard let startDate = weekStartDate else { return [] }
        guard let endDate = calendar.date(byAdding: .day, value: 7, to: startDate) else {
            return []
        }

        return reports.filter { $0.createdAt >= startDate && $0.createdAt < endDate }
    }

    private func filteredInsights(
        from records: [ReflectionInsightRecord],
        calendar: Calendar = .current
    ) -> [ReflectionInsightRecord] {
        switch selectedMode {
        case .weekly:
            guard let selectedWeekStartDate,
                  let endDate = calendar.date(byAdding: .day, value: 7, to: selectedWeekStartDate) else {
                return []
            }

            return records.filter {
                $0.scope == "weekly" &&
                    $0.updatedAt >= selectedWeekStartDate &&
                    $0.updatedAt < endDate
            }
        case .monthly:
            return records.filter { record in
                let components = calendar.dateComponents([.year, .month], from: record.updatedAt)
                return record.scope == "monthly" &&
                    components.year == selectedYear &&
                    components.month == selectedMonth
            }
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

    private func defaultWeekStartDate(
        from records: [SentimentRecord],
        calendar: Calendar = .current
    ) -> Date? {
        let monthlyRecords = records.filter { record in
            let components = calendar.dateComponents([.year, .month], from: record.createdAt)
            return components.year == selectedYear && components.month == selectedMonth
        }

        guard let latestRecordDate = monthlyRecords.map(\.createdAt).max() else {
            return nil
        }

        return weekStartDate(containing: latestRecordDate, calendar: calendar)
    }

    private func weekTitle(startDate: Date, endDate: Date, calendar: Calendar) -> String {
        "\(shortMonthDayString(from: startDate, calendar: calendar)) ~ \(shortMonthDayString(from: endDate, calendar: calendar))"
    }

    private func shortMonthDayString(from date: Date, calendar: Calendar) -> String {
        "\(calendar.component(.month, from: date)).\(calendar.component(.day, from: date))"
    }

    private var analysisCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        calendar.firstWeekday = 2
        return calendar
    }
}
