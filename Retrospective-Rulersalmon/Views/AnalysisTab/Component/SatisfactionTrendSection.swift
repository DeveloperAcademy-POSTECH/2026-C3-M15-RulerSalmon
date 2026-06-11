//
//  SatisfactionTrendSection.swift
//
//  Created by chaem on 6/11/26.
//

import SwiftUI

struct SatisfactionTrendSection: View {
    let data: MonthlyAnalysisData
    let year: Int
    let month: Int
    let referenceDate: Date

    @Binding var selectedMode: SatisfactionChartMode
    @Binding var selectedWeekStartDate: Date?
    let weekOptions: [AnalysisWeekOption]

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

    private var chartRange: String {
        switch selectedMode {
        case .weekly:
            return weeklyChartRange
        case .monthly:
            return "\(year)년 \(month)월"
        }
    }

    private var weeklyAxisLabels: [SatisfactionAxisLabel] {
        let calendar = analysisCalendar
        let startDate = currentWeekStartDate

        return (0..<7).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: startDate) else {
                return nil
            }

            return SatisfactionAxisLabel(index: offset, title: shortMonthDayString(from: date))
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

    private var weeklyChartRange: String {
        guard
            let firstLabel = weeklyAxisLabels.first?.title,
            let lastLabel = weeklyAxisLabels.last?.title
        else {
            return ""
        }

        return "\(firstLabel) ~ \(lastLabel)"
    }

    private func shortMonthDayString(from date: Date) -> String {
        let calendar = analysisCalendar
        return "\(calendar.component(.month, from: date)).\(calendar.component(.day, from: date))"
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

    private var summaryTitle: String {
        switch selectedMode {
        case .weekly:
            return "이번 주 만족도 흐름을 확인해요"
        case .monthly:
            return "6월은 후반부로 갈수록 더 안정적이었어요"
        }
    }

    private var summaryDescription: String {
        switch selectedMode {
        case .weekly:
            return "오늘에 가까워질수록 긍정 흐름이 커졌고, 6월 전체 상승 흐름의 시작점으로 보여요."
        case .monthly:
            return "일별 변동은 있었지만 전체 흐름은 완만하게 좋아졌고, 마지막 구간의 만족도가 높게 유지됐어요."
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center) {
                Text("만족도 흐름")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color.gray900)

                Spacer()

                if selectedMode == .weekly {
                    WeekSelectionPicker(
                        selectedWeekStartDate: $selectedWeekStartDate,
                        weekOptions: weekOptions
                    )
                    .frame(width: 112, height: 32, alignment: .trailing)
                } else {
                    Text(chartRange)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.gray600)
                }
            }

            SatisfactionChartModeSegmentedControl(selectedMode: $selectedMode)

            SatisfactionLineChart(
                points: selectedPoints,
                xAxisLabels: xAxisLabels,
                showsPointMarkers: selectedMode == .weekly,
                highlightsLastPoint: selectedMode == .monthly
            )
            .frame(height: AnalysisHomeLayout.chartHeight)
            .padding(.top, 14)
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(Color.gray200)
                    .frame(height: 1)
            }

            VStack(alignment: .leading, spacing: 7) {
                Text(summaryTitle)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.gray900)
                    .lineSpacing(2)

                Text(summaryDescription)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.gray600)
                    .lineSpacing(3)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, AnalysisHomeLayout.cardPadding)
            .padding(.vertical, 14)
            .background {
                RoundedRectangle(cornerRadius: AnalysisHomeLayout.cardCornerRadius)
                    .fill(Color.gray50)
            }
        }
    }
}
