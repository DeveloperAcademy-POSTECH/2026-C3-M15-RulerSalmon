//
//  AnalysisHomeModel.swift
//
//  Created by magic3ightball on 6/9/26.
//

import CoreGraphics
import Foundation

struct YearMonth {
    let year: Int
    let month: Int
}

struct PeriodRange {
    let start: YearMonth
    let end: YearMonth

    func contains(year: Int, month: Int) -> Bool {
        let targetValue = year * 100 + month
        return targetValue >= start.year * 100 + start.month
            && targetValue <= end.year * 100 + end.month
    }

    func canMove(to year: Int) -> Bool {
        year >= start.year && year <= end.year
    }

    func isMonthEnabled(year: Int, month: Int) -> Bool {
        contains(year: year, month: month)
    }
}

struct MonthlyAnalysisData {
    let weeklyScore: String
    let weeklyTitle: String
    let weeklyPositivePercentage: Double
    let weeklyNegativePercentage: Double
    let monthlyScore: String
    let monthlyTitle: String
    let monthlyPositivePercentage: Double
    let monthlyNegativePercentage: Double
    let weeklyEmotionKeywords: [EmotionKeyword]
    let monthlyEmotionKeywords: [EmotionKeyword]
    let weeklySatisfactionPoints: [SatisfactionPoint]
    let monthlySatisfactionPoints: [SatisfactionPoint]

    var EmotionKeywords: [EmotionKeyword] {
        monthlyEmotionKeywords
    }
}

struct AnalysisWeekOption: Identifiable, Hashable {
    let startDate: Date
    let title: String

    var id: Date {
        startDate
    }
}

struct AnalysisInsightItem: Identifiable, Equatable {
    let id: UUID
    let kind: String
    let title: String
    let description: String
    let count: Int
}

struct EmotionKeyword: Identifiable {
    let id = UUID()
    let title: String
    let count: Int
}

struct SatisfactionPoint: Identifiable {
    let id = UUID()
    let value: CGFloat?
}

struct SatisfactionAxisLabel: Identifiable {
    let id = UUID()
    let index: Int
    let title: String
}

enum SatisfactionChartMode: CaseIterable {
    case weekly
    case monthly

    var title: String {
        switch self {
        case .weekly: return "주간"
        case .monthly: return "월간"
        }
    }
}
