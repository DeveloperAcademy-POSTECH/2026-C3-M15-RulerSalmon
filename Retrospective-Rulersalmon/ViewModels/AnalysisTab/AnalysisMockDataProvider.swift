//
//  AnalysisMockDataProvider.swift
//
//  Created by magic3ightball on 6/9/26.
//

import Foundation

@MainActor
protocol AnalysisDataProviding {
    var availableRange: PeriodRange { get }
    func data(year: Int, month: Int, weekStartDate: Date?, referenceDate: Date) -> MonthlyAnalysisData
}

struct AnalysisMockDataProvider: AnalysisDataProviding {
    var availableRange: PeriodRange {
        let currentDate = Date()
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: currentDate)
        let currentMonth = calendar.component(.month, from: currentDate)

        return PeriodRange(
            start: YearMonth(year: 2026, month: 1),
            end: YearMonth(year: currentYear, month: currentMonth)
        )
    }

    func data(year: Int, month: Int, weekStartDate: Date?, referenceDate: Date) -> MonthlyAnalysisData {
        monthly
    }

    private let monthly = MonthlyAnalysisData(
        weeklyScore: "4.0",
        weeklyTitle: "이번 주도 차분히 이어가고 있어요",
        weeklyPositivePercentage: 76,
        weeklyNegativePercentage: 24,
        monthlyScore: "4.1",
        monthlyTitle: "안정적인 한 달이었어요",
        monthlyPositivePercentage: 82,
        monthlyNegativePercentage: 18,
        weeklyEmotionKeywords: [
            EmotionKeyword(title: "뿌듯함", count: 6),
            EmotionKeyword(title: "안도감", count: 5),
            EmotionKeyword(title: "아쉬움", count: 4),
            EmotionKeyword(title: "집중", count: 3),
            EmotionKeyword(title: "기대감", count: 2)
        ],
        monthlyEmotionKeywords: [
            EmotionKeyword(title: "성장", count: 24),
            EmotionKeyword(title: "감사", count: 18),
            EmotionKeyword(title: "도전", count: 16),
            EmotionKeyword(title: "설렘", count: 14),
            EmotionKeyword(title: "불안", count: 9)
        ],
        weeklySatisfactionPoints: [
            SatisfactionPoint(value: 3.4),
            SatisfactionPoint(value: 3.7),
            SatisfactionPoint(value: 4.0),
            SatisfactionPoint(value: 3.8),
            SatisfactionPoint(value: 4.1),
            SatisfactionPoint(value: 4.3),
            SatisfactionPoint(value: 4.5)
        ],
        monthlySatisfactionPoints: [
            SatisfactionPoint(value: 3.6),
            SatisfactionPoint(value: 3.8),
            SatisfactionPoint(value: nil),
            SatisfactionPoint(value: 4.1),
            SatisfactionPoint(value: 3.9),
            SatisfactionPoint(value: 4.3),
            SatisfactionPoint(value: 4.0),
            SatisfactionPoint(value: nil),
            SatisfactionPoint(value: 3.7),
            SatisfactionPoint(value: 3.8),
            SatisfactionPoint(value: 4.2),
            SatisfactionPoint(value: 4.4),
            SatisfactionPoint(value: 4.1),
            SatisfactionPoint(value: nil),
            SatisfactionPoint(value: 3.9),
            SatisfactionPoint(value: 4.0),
            SatisfactionPoint(value: 4.2),
            SatisfactionPoint(value: 4.3),
            SatisfactionPoint(value: nil),
            SatisfactionPoint(value: 4.1),
            SatisfactionPoint(value: 4.4),
            SatisfactionPoint(value: 4.2),
            SatisfactionPoint(value: 4.5),
            SatisfactionPoint(value: nil),
            SatisfactionPoint(value: 4.0),
            SatisfactionPoint(value: 4.1),
            SatisfactionPoint(value: 4.3),
            SatisfactionPoint(value: 4.4),
            SatisfactionPoint(value: 4.2),
            SatisfactionPoint(value: 4.3)
        ],
        weeklyRangeStartDate: Calendar.current.date(from: DateComponents(year: 2026, month: 6, day: 2))
    )
}
