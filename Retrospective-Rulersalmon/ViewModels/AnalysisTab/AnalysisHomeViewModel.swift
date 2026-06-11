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
    @Published private(set) var currentAvailableRange: PeriodRange
    @Published private(set) var savedDateRange: ClosedRange<Date>?
    @Published private(set) var emotionKeywordStatistics: [EmotionKeyword] = []
    @Published private(set) var insightItems: [AnalysisInsightItem] = []

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
        self.currentAvailableRange = dataProvider.availableRange
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

    var satisfactionLabel: String {
        switch selectedMode {
        case .weekly:
            return "이번 주 만족도"
        case .monthly:
            return "\(selectedMonth)월 만족도"
        }
    }

    var satisfactionScore: String {
        switch selectedMode {
        case .weekly:
            return selectedData.weeklyScore
        case .monthly:
            return selectedData.monthlyScore
        }
    }

    var satisfactionTitle: String {
        switch selectedMode {
        case .weekly:
            return selectedData.weeklyTitle
        case .monthly:
            return selectedData.monthlyTitle
        }
    }

    var canMoveToPreviousPeriod: Bool {
        switch selectedMode {
        case .weekly:
            guard let currentWeekStartDate = currentWeekStartDate,
                  let earliestWeekStartDate = earliestSelectableWeekStartDate else {
                return false
            }

            return currentWeekStartDate > earliestWeekStartDate
        case .monthly:
            return yearMonthValue(YearMonth(year: selectedYear, month: selectedMonth)) >
                yearMonthValue(currentAvailableRange.start)
        }
    }

    var canMoveToNextPeriod: Bool {
        switch selectedMode {
        case .weekly:
            guard let currentWeekStartDate = currentWeekStartDate,
                  let latestWeekStartDate = latestSelectableWeekStartDate else {
                return false
            }

            return currentWeekStartDate < latestWeekStartDate
        case .monthly:
            return yearMonthValue(YearMonth(year: selectedYear, month: selectedMonth)) <
                yearMonthValue(currentAvailableRange.end)
        }
    }

    var positivePercentage: Double {
        switch selectedMode {
        case .weekly:
            return selectedData.weeklyPositivePercentage
        case .monthly:
            return selectedData.monthlyPositivePercentage
        }
    }

    var negativePercentage: Double {
        switch selectedMode {
        case .weekly:
            return selectedData.weeklyNegativePercentage
        case .monthly:
            return selectedData.monthlyNegativePercentage
        }
    }

    func refresh(
        reports: [StoredReflectionReport],
        sentiments: [SentimentRecord],
        insights: [ReflectionInsightRecord],
        shouldNormalizeSelection: Bool = true
    ) {
        currentAvailableRange = availableRange(from: reports)
        savedDateRange = makeSavedDateRange(from: reports)
        if shouldNormalizeSelection {
            normalizeSelectedPeriod(with: currentAvailableRange)
            normalizeSelectedWeek(from: sentiments)
        }

        emotionKeywordStatistics = emotionKeywords(from: reports)
        insightItems = shouldShowInsights(from: sentiments) ? self.insights(from: insights, sentiments: sentiments) : []
    }

    func availableRange(from reports: [StoredReflectionReport]) -> PeriodRange {
        reportAvailableRange(from: reports) ?? availableRange
    }

    func makeSavedDateRange(from reports: [StoredReflectionReport]) -> ClosedRange<Date>? {
        guard let startDate = reports.map(\.createdAt).min(),
              let endDate = reports.map(\.createdAt).max() else {
            return nil
        }

        return startDate...endDate
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

    func insights(
        from records: [ReflectionInsightRecord],
        sentiments: [SentimentRecord]? = nil
    ) -> [AnalysisInsightItem] {
        let filteredRecords = sentiments.map {
            filteredInsights(from: records, sentiments: $0)
        } ?? filteredInsights(from: records)
        let selectedInsights: [ReflectionInsightRecord]
        if selectedMode == .monthly {
            let fallbackRecords = sentiments.map {
                weeklyFallbackInsights(from: records, sentiments: $0)
            } ?? weeklyFallbackInsights(from: records)
            selectedInsights = monthlyInsightsWithWeeklyFallback(
                monthlyRecords: filteredRecords,
                weeklyRecords: fallbackRecords
            )
        } else {
            selectedInsights = topInsightRecords(from: filteredRecords)
        }

        var fallbackTemplatePositions: [String: Int] = [:]
        return selectedInsights
            .map { record in
                let templatePosition = fallbackTemplatePositions[record.kind, default: 0]
                fallbackTemplatePositions[record.kind] = templatePosition + 1

                return AnalysisInsightItem(
                    id: record.id,
                    kind: record.kind,
                    title: record.title,
                    description: displayDescription(
                        for: record,
                        templatePosition: templatePosition
                    ),
                    count: record.count
                )
            }
    }

    func weekOptions() -> [AnalysisWeekOption] {
        let calendar = analysisCalendar
        guard let monthStartDate = calendar.date(from: DateComponents(year: selectedYear, month: selectedMonth, day: 1)),
              let nextMonthDate = calendar.date(byAdding: .month, value: 1, to: monthStartDate) else {
            return []
        }

        var startDate = weekStartDate(containing: monthStartDate, calendar: calendar)
        var options: [AnalysisWeekOption] = []

        let latestSelectableWeekStartDate = weekStartDate(containing: referenceDate, calendar: calendar)

        while weekIntersectsMonth(
            startDate: startDate,
            monthStartDate: monthStartDate,
            nextMonthDate: nextMonthDate,
            calendar: calendar
        ) && startDate <= latestSelectableWeekStartDate {
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
        let calendar = analysisCalendar
        let options = weekOptions()
        guard !options.isEmpty else {
            selectedWeekStartDate = nil
            return
        }

        if let selectedWeekStartDate,
           options.contains(where: { calendar.isDate($0.startDate, inSameDayAs: selectedWeekStartDate) }),
           !sentimentRecordsInWeek(records, startDate: selectedWeekStartDate, calendar: calendar).isEmpty {
            return
        }

        selectedWeekStartDate = defaultWeekStartDate(from: records, options: options, calendar: calendar)
            ?? referenceWeekStartDate(in: options, calendar: calendar)
            ?? options.last?.startDate
    }

    func showPeriodSheet() {
        isPeriodSheetPresented = true
    }

    func moveToPreviousPeriod() {
        moveSelectedPeriod(by: -1)
    }

    func moveToNextPeriod() {
        moveSelectedPeriod(by: 1)
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

    private func moveSelectedPeriod(by value: Int) {
        switch selectedMode {
        case .weekly:
            moveSelectedWeek(by: value)
        case .monthly:
            moveSelectedMonth(by: value)
        }
    }

    private func moveSelectedWeek(by value: Int) {
        let calendar = analysisCalendar
        guard let currentWeekStartDate,
              let targetWeekStartDate = calendar.date(byAdding: .day, value: value * 7, to: currentWeekStartDate),
              isWeekStartDateSelectable(targetWeekStartDate, calendar: calendar) else {
            return
        }

        selectedWeekStartDate = targetWeekStartDate
        updateSelectedMonth(containing: targetWeekStartDate, calendar: calendar)
    }

    private func moveSelectedMonth(by value: Int) {
        let calendar = analysisCalendar
        guard let currentMonthDate = calendar.date(from: DateComponents(year: selectedYear, month: selectedMonth, day: 1)),
              let targetMonthDate = calendar.date(byAdding: .month, value: value, to: currentMonthDate) else {
            return
        }

        let components = calendar.dateComponents([.year, .month], from: targetMonthDate)
        guard let targetYear = components.year,
              let targetMonth = components.month,
              currentAvailableRange.contains(year: targetYear, month: targetMonth) else {
            return
        }

        selectedYear = targetYear
        selectedMonth = targetMonth
    }

    private func updateSelectedMonth(containing weekStartDate: Date, calendar: Calendar) {
        let components = calendar.dateComponents([.year, .month], from: weekStartDate)
        guard let year = components.year,
              let month = components.month,
              currentAvailableRange.contains(year: year, month: month) else {
            return
        }

        selectedYear = year
        selectedMonth = month
    }

    private func isWeekStartDateSelectable(_ weekStartDate: Date, calendar: Calendar) -> Bool {
        guard let earliestSelectableWeekStartDate,
              let latestSelectableWeekStartDate else {
            return false
        }

        return weekStartDate >= earliestSelectableWeekStartDate &&
            weekStartDate <= latestSelectableWeekStartDate
    }

    private var currentWeekStartDate: Date? {
        if let selectedWeekStartDate {
            return analysisCalendar.startOfDay(for: selectedWeekStartDate)
        }

        return weekOptions().last?.startDate
    }

    private var earliestSelectableWeekStartDate: Date? {
        let calendar = analysisCalendar
        if let firstSavedDate = savedDateRange?.lowerBound {
            return weekStartDate(containing: firstSavedDate, calendar: calendar)
        }

        guard let startMonthDate = calendar.date(from: DateComponents(
            year: currentAvailableRange.start.year,
            month: currentAvailableRange.start.month,
            day: 1
        )) else {
            return nil
        }

        return weekStartDate(containing: startMonthDate, calendar: calendar)
    }

    private var latestSelectableWeekStartDate: Date? {
        let calendar = analysisCalendar
        if let lastSavedDate = savedDateRange?.upperBound {
            return weekStartDate(containing: lastSavedDate, calendar: calendar)
        }

        guard let endMonthDate = calendar.date(from: DateComponents(
            year: currentAvailableRange.end.year,
            month: currentAvailableRange.end.month,
            day: 1
        )),
              let nextMonthDate = calendar.date(byAdding: .month, value: 1, to: endMonthDate),
              let lastDayOfEndMonth = calendar.date(byAdding: .day, value: -1, to: nextMonthDate) else {
            return nil
        }

        return weekStartDate(containing: lastDayOfEndMonth, calendar: calendar)
    }

    private func selectedSentimentCount(from records: [SentimentRecord]) -> Int {
        switch selectedMode {
        case .weekly:
            guard let startDate = selectedWeekStartDate else { return 0 }
            return sentimentRecordsInWeek(records, startDate: startDate, calendar: analysisCalendar).count
        case .monthly:
            return recordsInMonth(from: records, year: selectedYear, month: selectedMonth).count
        }
    }

    private func shouldShowInsights(from records: [SentimentRecord]) -> Bool {
        selectedSentimentCount(from: records) >= 3
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

    private func topInsightRecords(
        from records: [ReflectionInsightRecord]
    ) -> [ReflectionInsightRecord] {
        selectInsightRecords(
            primaryRecords: records,
            fallbackRecords: []
        )
    }

    private func monthlyInsightsWithWeeklyFallback(
        monthlyRecords: [ReflectionInsightRecord],
        weeklyRecords: [ReflectionInsightRecord]
    ) -> [ReflectionInsightRecord] {
        selectInsightRecords(
            primaryRecords: monthlyRecords,
            fallbackRecords: weeklyRecords
        )
    }

    private func selectInsightRecords(
        primaryRecords: [ReflectionInsightRecord],
        fallbackRecords: [ReflectionInsightRecord]
    ) -> [ReflectionInsightRecord] {
        var selectedRecords: [ReflectionInsightRecord] = []
        var selectedTopicKeys = Set<String>()
        var selectedCounts: [String: Int] = [:]

        appendInsightRecords(
            from: primaryRecords,
            to: &selectedRecords,
            selectedTopicKeys: &selectedTopicKeys,
            selectedCounts: &selectedCounts
        )
        appendInsightRecords(
            from: fallbackRecords,
            to: &selectedRecords,
            selectedTopicKeys: &selectedTopicKeys,
            selectedCounts: &selectedCounts
        )

        return selectedRecords.filter { $0.kind == "reflection" } +
            selectedRecords.filter { $0.kind == "strength" }
    }

    private func appendInsightRecords(
        from records: [ReflectionInsightRecord],
        to selectedRecords: inout [ReflectionInsightRecord],
        selectedTopicKeys: inout Set<String>,
        selectedCounts: inout [String: Int]
    ) {
        let candidates = uniqueInsightsByTitle(records)
            .filter(isDisplayableInsight)
            .filter { $0.kind == "reflection" || $0.kind == "strength" }
            .sorted(by: insightSort)

        for record in candidates {
            guard selectedCounts[record.kind, default: 0] < 2 else { continue }

            let topicKey = normalizedInsightTopicKey(record)
            guard !selectedTopicKeys.contains(topicKey) else { continue }

            selectedRecords.append(record)
            selectedTopicKeys.insert(topicKey)
            selectedCounts[record.kind, default: 0] += 1
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

    private func displayDescription(
        for record: ReflectionInsightRecord,
        templatePosition: Int
    ) -> String {
        guard isInformalToneDescription(record.insightDescription) else {
            return record.insightDescription
        }

        switch record.kind {
        case "reflection":
            return reflectionFallbackDescription(
                for: record,
                templatePosition: templatePosition
            )
        case "strength":
            return strengthFallbackDescription(
                for: record,
                templatePosition: templatePosition
            )
        default:
            return record.insightDescription
        }
    }

    private func isInformalToneDescription(_ description: String) -> Bool {
        let informalFragments = [
            "필요해",
            "중요해",
            "거야",
            "돼",
            "해.",
            "좋아.",
            "있어.",
            "없어."
        ]

        return informalFragments.contains { description.contains($0) }
    }

    private func reflectionFallbackDescription(
        for record: ReflectionInsightRecord,
        templatePosition: Int
    ) -> String {
        let templates = [
            "\(record.title)이 반복해서 나타나고 있어요. 다음에는 이 흐름을 조금 더 가볍게 조정할 방법을 하나 정해보면 좋겠어요.",
            "\(record.title)과 관련된 아쉬움이 여러 번 보였어요. 다음 회고에서는 부담을 줄일 작은 기준을 먼저 세워보세요.",
            "\(record.title)이 계속 신경 쓰이는 주제로 드러나고 있어요. 다음에는 시작하기 쉬운 방식으로 한 단계만 낮춰보는 것도 좋겠습니다."
        ]

        return templates[templatePosition % templates.count]
    }

    private func strengthFallbackDescription(
        for record: ReflectionInsightRecord,
        templatePosition: Int
    ) -> String {
        let templates = [
            "\(record.title)이 반복해서 드러나고 있어요. 그 흐름을 꾸준히 만들어가고 계신 점이 참 좋아요.",
            "\(record.title)에서 좋은 습관이 계속 보이고 있어요. 이미 잘 쌓아가고 계신 강점입니다.",
            "\(record.title)이 여러 회고에서 자연스럽게 이어지고 있어요. 스스로의 리듬을 잘 만들어가고 계세요."
        ]

        return templates[templatePosition % templates.count]
    }

    private func normalizedInsightTitle(_ title: String) -> String {
        title
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }

    private func normalizedInsightTopicKey(_ record: ReflectionInsightRecord) -> String {
        let normalizedTopicKey = normalizedInsightTitle(record.topicKey)
            .filter { !$0.isWhitespace && !$0.isPunctuation }

        if normalizedTopicKey != normalizedInsightTitle(record.title)
            .filter({ !$0.isWhitespace && !$0.isPunctuation }) {
            return normalizedTopicKey
        }

        return legacyCoreInsightTopicKey(record.title)
    }

    private func legacyCoreInsightTopicKey(_ title: String) -> String {
        let normalizedTitle = normalizedInsightTitle(title)
            .filter { !$0.isWhitespace && !$0.isPunctuation }
        let possessiveParts = normalizedTitle.split(separator: "의", maxSplits: 1).map(String.init)
        if possessiveParts.count > 1,
           let firstPart = possessiveParts.first,
           firstPart.count >= 2 {
            return firstPart
        }

        let prefixes = [
            "꾸준한",
            "꾸준히",
            "지속적인",
            "반복적인",
            "긍정적인"
        ]
        let suffixes = [
            "긍정적인효과",
            "꾸준함",
            "열정",
            "중요성",
            "필요성",
            "효과",
            "향상",
            "관리",
            "습관",
            "노력",
            "반복",
            "유지",
            "개선",
            "조정"
        ]

        let prefixTrimmedTopic = prefixes.reduce(normalizedTitle) { partialResult, prefix in
            partialResult.hasPrefix(prefix)
                ? String(partialResult.dropFirst(prefix.count))
                : partialResult
        }
        let trimmedTopic = suffixes.reduce(prefixTrimmedTopic) { partialResult, suffix in
            partialResult.hasSuffix(suffix)
                ? String(partialResult.dropLast(suffix.count))
                : partialResult
        }
        return trimmedTopic.isEmpty ? normalizedTitle : trimmedTopic
    }

    private func isDisplayableInsight(_ record: ReflectionInsightRecord) -> Bool {
        let normalizedTitle = normalizedInsightTitle(record.title)
            .filter { !$0.isWhitespace && !$0.isPunctuation }
        let blockedTitles = [
            "date",
            "날짜",
            "일자",
            "satisfaction",
            "satisfactionscore",
            "score",
            "만족도",
            "count",
            "횟수",
            "반복횟수",
            "positive",
            "negative",
            "긍정",
            "부정",
            "percentage",
            "percent",
            "비율",
            "index",
            "id",
            "kind",
            "title",
            "description",
            "matchedkeywords",
            "keywords",
            "candidate",
            "candidates",
            "reflection",
            "strength"
        ]

        return !blockedTitles.contains(normalizedTitle)
    }

    private func weeklyFallbackInsights(
        from records: [ReflectionInsightRecord],
        sentiments: [SentimentRecord] = [],
        calendar: Calendar = .current
    ) -> [ReflectionInsightRecord] {
        let selectedMonthRecords = recordsInMonth(
            from: sentiments,
            year: selectedYear,
            month: selectedMonth,
            calendar: calendar
        )
        guard sentiments.isEmpty || selectedMonthRecords.count >= 3 else {
            return []
        }

        let selectedMonthSourceIDs = Set(selectedMonthRecords.map { $0.id.uuidString })
        return records.filter { record in
            guard record.scope == "weekly" else { return false }

            if !selectedMonthSourceIDs.isEmpty,
               !record.sourceIDs.isDisjoint(with: selectedMonthSourceIDs) {
                return true
            }

            let components = calendar.dateComponents([.year, .month], from: record.updatedAt)
            return components.year == selectedYear && components.month == selectedMonth
        }
    }

    private func filteredInsights(
        from records: [ReflectionInsightRecord],
        calendar: Calendar = .current
    ) -> [ReflectionInsightRecord] {
        filteredInsights(from: records, sentiments: [], calendar: calendar)
    }

    private func filteredInsights(
        from records: [ReflectionInsightRecord],
        sentiments: [SentimentRecord],
        calendar: Calendar = .current
    ) -> [ReflectionInsightRecord] {
        switch selectedMode {
        case .weekly:
            guard let selectedWeekStartDate,
                  let endDate = calendar.date(byAdding: .day, value: 7, to: selectedWeekStartDate) else {
                return []
            }

            let selectedWeekRecords = sentimentRecordsInWeek(
                sentiments,
                startDate: selectedWeekStartDate,
                calendar: calendar
            )
            guard sentiments.isEmpty || selectedWeekRecords.count >= 3 else {
                return []
            }

            let selectedWeekSourceIDs = Set(selectedWeekRecords.map { $0.id.uuidString })
            return records.filter {
                $0.scope == "weekly" &&
                    (
                        ($0.updatedAt >= selectedWeekStartDate && $0.updatedAt < endDate) ||
                        !$0.sourceIDs.isDisjoint(with: selectedWeekSourceIDs)
                    )
            }
        case .monthly:
            let selectedMonthRecords = recordsInMonth(
                from: sentiments,
                year: selectedYear,
                month: selectedMonth,
                calendar: calendar
            )
            guard sentiments.isEmpty || selectedMonthRecords.count >= 3 else {
                return []
            }

            let selectedMonthSourceIDs = Set(selectedMonthRecords.map { $0.id.uuidString })
            return records.filter { record in
                let components = calendar.dateComponents([.year, .month], from: record.updatedAt)
                let isUpdatedInSelectedMonth = components.year == selectedYear && components.month == selectedMonth
                let usesSelectedMonthRecords = !record.sourceIDs.isDisjoint(with: selectedMonthSourceIDs)

                return record.scope == "monthly" &&
                    (isUpdatedInSelectedMonth || usesSelectedMonthRecords)
            }
        }
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
        guard let startDate = weekStartDate,
              let endDate = calendar.date(byAdding: .day, value: 7, to: startDate) else {
            return []
        }

        return reports.filter { $0.createdAt >= startDate && $0.createdAt < endDate }
    }

    private func recordsInMonth(
        from records: [SentimentRecord],
        year: Int,
        month: Int,
        calendar: Calendar = .current
    ) -> [SentimentRecord] {
        records.filter { record in
            let components = calendar.dateComponents([.year, .month], from: record.createdAt)
            return components.year == year && components.month == month
        }
    }

    private func sentimentRecordsInWeek(
        _ records: [SentimentRecord],
        startDate: Date,
        calendar: Calendar
    ) -> [SentimentRecord] {
        guard let endDate = calendar.date(byAdding: .day, value: 7, to: startDate) else {
            return []
        }

        return records.filter { $0.createdAt >= startDate && $0.createdAt < endDate }
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
        options: [AnalysisWeekOption],
        calendar: Calendar = .current
    ) -> Date? {
        let monthlyRecords = recordsInMonth(
            from: records,
            year: selectedYear,
            month: selectedMonth,
            calendar: calendar
        )

        return options
            .last { option in
                !sentimentRecordsInWeek(monthlyRecords, startDate: option.startDate, calendar: calendar).isEmpty
            }?
            .startDate
    }

    private func referenceWeekStartDate(
        in options: [AnalysisWeekOption],
        calendar: Calendar = .current
    ) -> Date? {
        let referenceComponents = calendar.dateComponents([.year, .month], from: referenceDate)
        guard referenceComponents.year == selectedYear,
              referenceComponents.month == selectedMonth else {
            return nil
        }

        let startDate = weekStartDate(containing: referenceDate, calendar: calendar)
        return options.first {
            calendar.isDate($0.startDate, inSameDayAs: startDate)
        }?.startDate
    }

    private func weekTitle(startDate: Date, endDate: Date, calendar: Calendar) -> String {
        "\(shortMonthDayString(from: startDate, calendar: calendar)) ~ \(shortMonthDayString(from: endDate, calendar: calendar))"
    }

    private func weekIntersectsMonth(
        startDate: Date,
        monthStartDate: Date,
        nextMonthDate: Date,
        calendar: Calendar
    ) -> Bool {
        guard let nextWeekStartDate = calendar.date(byAdding: .day, value: 7, to: startDate) else {
            return false
        }

        return startDate < nextMonthDate && nextWeekStartDate > monthStartDate
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
