//
//  AnalysisMockDataProvider.swift
//
//  Created by magic3ightball on 6/9/26.
//

import Foundation

protocol AnalysisDataProviding {
    var availableRange: PeriodRange { get }
    func data(year: Int, month: Int) -> MonthlyAnalysisData
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

    func data(year: Int, month: Int) -> MonthlyAnalysisData {
        monthly
    }

    private let monthly = MonthlyAnalysisData(
        monthlyScore: "4.1",
        monthlyTitle: "안정적인 한 달이었어요",
        strengthKeywords: [
            StrengthKeyword(title: "성장", count: 24),
            StrengthKeyword(title: "감사", count: 18),
            StrengthKeyword(title: "도전", count: 16),
            StrengthKeyword(title: "설렘", count: 14),
            StrengthKeyword(title: "불안", count: 9)
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
        ]
    )
}
