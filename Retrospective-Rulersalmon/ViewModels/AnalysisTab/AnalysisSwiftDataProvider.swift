//
//  AnalysisSwiftDataProvider.swift
//  Retrospective-Rulersalmon
//
//  Created by chaem on 6/9/26.
//

import Foundation
import SwiftData
import CoreGraphics

@MainActor
struct AnalysisSwiftDataProvider: AnalysisDataProviding {
    private let store: AppDataStore
    
    init() {
        self.store = AppDataStore.shared
    }

    init(store: AppDataStore) {
        self.store = store
    }
    
    var availableRange: PeriodRange {
        //TODO: 일단 현재 목업 range와 동일하게 두고, 나중에 실제 저장된 record의 min/max 날짜로 바꾸면 됨
        AnalysisMockDataProvider().availableRange
    }
    
    func data(year: Int, month: Int, weekStartDate: Date?, referenceDate: Date) -> MonthlyAnalysisData {
        let monthlyRecords = store.sentimentRecords(year: year, month: month)
        let weeklyStartDate = weekStartDate
            ?? selectedWeekStartDate(from: monthlyRecords, year: year, month: month)
            ?? self.weekStartDate(containing: referenceDate)
        let weeklyRecords = store.sentimentRecords(
            startDate: weeklyStartDate,
            endDate: analysisCalendar.date(byAdding: .day, value: 7, to: weeklyStartDate) ?? weeklyStartDate
        )
        let weeklySummary = SentimentStatistics.summarize(weeklyRecords)
        let monthlySummary = SentimentStatistics.summarize(monthlyRecords)
        
        return MonthlyAnalysisData(
            weeklyScore: String(format: "%.1f", weeklySummary.satisfactionScore),
            weeklyTitle: weeklyTitle(for: weeklySummary.satisfactionScore, isEmpty: weeklyRecords.isEmpty),
            weeklyPositivePercentage: weeklySummary.positivePercentage,
            weeklyNegativePercentage: weeklySummary.negativePercentage,
            monthlyScore: String(format: "%.1f", monthlySummary.satisfactionScore),
            monthlyTitle: monthlyTitle(for: monthlySummary.satisfactionScore, isEmpty: monthlyRecords.isEmpty),
            monthlyPositivePercentage: monthlySummary.positivePercentage,
            monthlyNegativePercentage: monthlySummary.negativePercentage,
            weeklyEmotionKeywords: [],
            monthlyEmotionKeywords: [],
            weeklySatisfactionPoints: weeklySatisfactionPoints(from: weeklyRecords, startDate: weeklyStartDate),
            monthlySatisfactionPoints: monthlySatisfactionPoints(from: monthlyRecords, year: year, month: month),
            weeklyRangeStartDate: weeklyStartDate
        )
    }

    private func weeklySatisfactionPoints(
        from records: [SentimentRecord],
        startDate: Date?
    ) -> [SatisfactionPoint] {
        guard let startDate else {
            return Array(repeating: SatisfactionPoint(value: nil), count: 7)
        }

        let calendar = analysisCalendar

        return (0..<7).map { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: startDate) else {
                return SatisfactionPoint(value: nil)
            }

            let dayRecords = records.filter { calendar.isDate($0.createdAt, inSameDayAs: date) }
            return SatisfactionPoint(value: averageSatisfactionScore(from: dayRecords))
        }
    }

    private func monthlySatisfactionPoints(
        from records: [SentimentRecord],
        year: Int,
        month: Int
    ) -> [SatisfactionPoint] {
        let calendar = Calendar.current
        let components = DateComponents(year: year, month: month)
        guard
            let startDate = calendar.date(from: components),
            let dayRange = calendar.range(of: .day, in: .month, for: startDate)
        else {
            return Array(repeating: SatisfactionPoint(value: nil), count: 30)
        }

        return dayRange.map { day in
            guard let date = calendar.date(from: DateComponents(year: year, month: month, day: day)) else {
                return SatisfactionPoint(value: nil)
            }

            let dayRecords = records.filter { calendar.isDate($0.createdAt, inSameDayAs: date) }
            return SatisfactionPoint(value: averageSatisfactionScore(from: dayRecords))
        }
    }

    private func averageSatisfactionScore(from records: [SentimentRecord]) -> CGFloat? {
        guard !records.isEmpty else { return nil }
        let totalScore = records.reduce(0) { $0 + $1.satisfactionScore }
        return CGFloat(totalScore / Double(records.count))
    }

    private func selectedWeekStartDate(
        from records: [SentimentRecord],
        year: Int,
        month: Int
    ) -> Date? {
        let calendar = analysisCalendar
        let referenceDate = records.map(\.createdAt).max()
            ?? calendar.date(from: DateComponents(year: year, month: month, day: 1))

        guard let referenceDate else {
            return nil
        }

        return weekStartDate(containing: referenceDate)
    }

    private func weekStartDate(containing date: Date) -> Date {
        let calendar = analysisCalendar
        let day = calendar.startOfDay(for: date)
        let weekday = calendar.component(.weekday, from: day)
        let daysFromMonday = (weekday + 5) % 7
        return calendar.date(byAdding: .day, value: -daysFromMonday, to: day) ?? day
    }

    private var analysisCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        calendar.firstWeekday = 2
        return calendar
    }

    private func weeklyTitle(for score: Double, isEmpty: Bool) -> String {
        if isEmpty {
            return "이번 주 기록이 아직 없어요"
        }

        switch score {
        case 4.3...:
            return "만족스러운 한 주였어요"
        case 3.6..<4.3:
            return "안정적인 한 주였어요"
        case 2.8..<3.6:
            return "무난하게 지나간 한 주예요"
        default:
            return "돌봄이 필요한 한 주였어요"
        }
    }

    private func monthlyTitle(for score: Double, isEmpty: Bool) -> String {
        if isEmpty {
            return "아직 기록이 없어요"
        }

        switch score {
        case 4.3...:
            return "만족스러운 한 달이었어요"
        case 3.6..<4.3:
            return "안정적인 한 달이었어요"
        case 2.8..<3.6:
            return "무난하게 지나간 한 달이에요"
        default:
            return "돌봄이 필요한 한 달이었어요"
        }
    }

}
