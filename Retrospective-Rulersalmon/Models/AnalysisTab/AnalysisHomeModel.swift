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
    let monthlyScore: String
    let monthlyTitle: String
    let strengthKeywords: [StrengthKeyword]
    let weeklySatisfactionPoints: [SatisfactionPoint]
    let monthlySatisfactionPoints: [SatisfactionPoint]
}

struct StrengthKeyword: Identifiable {
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
