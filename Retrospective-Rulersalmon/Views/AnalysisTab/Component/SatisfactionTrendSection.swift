//
//  SatisfactionTrendSection.swift
//
//  Created by chaem on 6/11/26.
//

import SwiftUI

struct SatisfactionTrendSection: View {
    let data: MonthlyAnalysisData
    let referenceDate: Date
    let selectedMode: SatisfactionChartMode
    @Binding var selectedWeekStartDate: Date?

    private var selectedPoints: [SatisfactionPoint] {
        switch selectedMode {
        case .weekly:
            return data.weeklySatisfactionPoints
        case .monthly:
            return data.monthlySatisfactionPoints
        }
    }

    private var xAxisLabels: [SatisfactionAxisLabel] {
        switch selectedMode {
        case .weekly:
            return weeklyAxisLabels
        case .monthly:
            return monthlyAxisLabels
        }
    }

    private var weeklyAxisLabels: [SatisfactionAxisLabel] {
        let calendar = analysisCalendar
        let startDate = currentWeekStartDate

        return (0..<7).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: startDate) else {
                return nil
            }

            return SatisfactionAxisLabel(index: offset, title: weekdayString(from: date))
        }
    }

    private var monthlyAxisLabels: [SatisfactionAxisLabel] {
        let dayCount = max(data.monthlySatisfactionPoints.count, 1)
        let labelDays = [1, 8, 15, 22, dayCount]

        return labelDays
            .reduce(into: [Int]()) { days, day in
                guard !days.contains(day), day <= dayCount else { return }
                days.append(day)
            }
            .map { day in
                SatisfactionAxisLabel(index: day - 1, title: "\(day)일")
            }
    }

    private var currentWeekStartDate: Date {
        let calendar = analysisCalendar
        if let selectedWeekStartDate {
            return calendar.startOfDay(for: selectedWeekStartDate)
        }

        let today = calendar.startOfDay(for: referenceDate)
        let weekday = calendar.component(.weekday, from: today)
        let daysFromMonday = (weekday + 5) % 7
        return calendar.date(byAdding: .day, value: -daysFromMonday, to: today) ?? today
    }

    private var analysisCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        calendar.firstWeekday = 2
        return calendar
    }

    private func weekdayString(from date: Date) -> String {
        let calendar = analysisCalendar
        let weekdaySymbols = ["일", "월", "화", "수", "목", "금", "토"]
        let weekdayIndex = calendar.component(.weekday, from: date) - 1
        return weekdaySymbols.indices.contains(weekdayIndex) ? weekdaySymbols[weekdayIndex] : ""
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("만족도 흐름")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Color.gray900)

            SatisfactionLineChart(
                points: selectedPoints,
                xAxisLabels: xAxisLabels,
                showsPointMarkers: selectedMode == .weekly,
                highlightsLastPoint: selectedMode == .monthly
            )
            .frame(height: AnalysisHomeLayout.chartHeight)
            .padding(.top, 14)
        }
    }
}
