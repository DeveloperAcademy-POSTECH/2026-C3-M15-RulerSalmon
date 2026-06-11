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
        trendSummary.title
    }

    private var summaryDescription: String {
        trendSummary.description
    }

    private var trendSummary: (title: String, description: String) {
        let values = selectedPoints.compactMap(\.value).map(Double.init)

        guard let firstValue = values.first, let lastValue = values.last else {
            switch selectedMode {
            case .weekly:
                return (
                    "이번 주 만족도 흐름을 기다리고 있어요",
                    "아직 기록된 만족도 데이터가 부족해요. 회고가 쌓이면 주간 흐름을 보여드릴게요."
                )
            case .monthly:
                return (
                    "\(month)월 만족도 흐름을 기다리고 있어요",
                    "아직 기록된 만족도 데이터가 부족해요. 회고가 쌓이면 월간 흐름을 보여드릴게요."
                )
            }
        }

        let average = values.reduce(0, +) / Double(values.count)
        let delta = lastValue - firstValue
        let maxValue = values.max() ?? lastValue
        let minValue = values.min() ?? lastValue
        let range = maxValue - minValue
        let lastSegmentAverage = averageOfLastSegment(in: values)

        return (
            title: trendSummaryTitle(delta: delta, average: average),
            description: trendSummaryDescription(
                delta: delta,
                range: range,
                lastValue: lastValue,
                lastSegmentAverage: lastSegmentAverage
            )
        )
    }

    private func trendSummaryTitle(delta: Double, average: Double) -> String {
        let periodName = selectedMode == .weekly ? "이번 주" : "\(month)월"

        if delta >= 0.3 {
            return "\(periodName)은 만족도가 올라가는 흐름이에요"
        } else if delta <= -0.3 {
            return "\(periodName)은 만족도가 내려가는 흐름이에요"
        } else if average >= 3.8 {
            return "\(periodName)은 만족도가 안정적으로 높았어요"
        } else if average <= 2.4 {
            return "\(periodName)은 만족도가 낮게 머문 편이에요"
        } else {
            return "\(periodName) 만족도는 큰 변화 없이 이어졌어요"
        }
    }

    private func trendSummaryDescription(
        delta: Double,
        range: Double,
        lastValue: Double,
        lastSegmentAverage: Double
    ) -> String {
        let periodName = selectedMode == .weekly ? "주간" : "월간"
        let fluctuationText = range >= 1.2 ? "중간중간 변동은 있었지만" : "큰 흔들림은 적었고"
        let endingText: String

        if lastSegmentAverage >= 3.8 || lastValue >= 3.8 {
            endingText = "마지막 구간의 만족도가 높게 유지됐어요."
        } else if lastSegmentAverage <= 2.4 || lastValue <= 2.4 {
            endingText = "마지막 구간의 만족도는 낮은 편이었어요."
        } else {
            endingText = "마지막 구간은 보통 수준으로 마무리됐어요."
        }

        if delta >= 0.3 {
            return "\(fluctuationText) \(periodName) 만족도는 시작보다 좋아졌고, \(endingText)"
        } else if delta <= -0.3 {
            return "\(fluctuationText) \(periodName) 만족도는 시작보다 낮아졌고, \(endingText)"
        } else {
            return "\(fluctuationText) \(periodName) 만족도는 비슷한 수준을 유지했고, \(endingText)"
        }
    }

    private func averageOfLastSegment(in values: [Double]) -> Double {
        let segmentCount = min(selectedMode == .weekly ? 2 : 7, values.count)
        let segment = values.suffix(segmentCount)
        return segment.reduce(0, +) / Double(segment.count)
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
