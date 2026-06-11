//
//  SatisfactionPeriodSummaryCard.swift
//
//  Created by chaem on 6/11/26.
//

import SwiftUI

struct SatisfactionPeriodSummaryCard: View {
    let score: String
    let summary: SatisfactionTrendSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .center, spacing: 14) {
                Text(summary.title)
                    .font(.system(size: 21, weight: .bold))
                    .foregroundStyle(Color.blue500)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(alignment: .lastTextBaseline, spacing: 0) {
                    Text(score)
                        .font(.system(size: 21, weight: .heavy))
                        .foregroundStyle(Color.blue500)
                    
                    Text(" / 5 ")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.gray600)
                }
                .layoutPriority(1)
            }

            Text(summary.description)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.gray600)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(AnalysisHomeLayout.cardPadding)
        .background {
            RoundedRectangle(cornerRadius: AnalysisHomeLayout.cardCornerRadius)
                .fill(Color.blue50)
        }
    }
}

struct SatisfactionTrendSummary {
    let title: String
    let description: String

    static func make(
        data: MonthlyAnalysisData,
        selectedMode: SatisfactionChartMode,
        month: Int
    ) -> SatisfactionTrendSummary {
        let points: [SatisfactionPoint]
        switch selectedMode {
        case .weekly:
            points = data.weeklySatisfactionPoints
        case .monthly:
            points = data.monthlySatisfactionPoints
        }

        let values = points.compactMap(\.value).map(Double.init)

        guard let firstValue = values.first, let lastValue = values.last else {
            switch selectedMode {
            case .weekly:
                return SatisfactionTrendSummary(
                    title: "이번 주 만족도 흐름을 기다리고 있어요",
                    description: "아직 기록된 만족도 데이터가 부족해요. 회고가 쌓이면 주간 흐름을 보여드릴게요."
                )
            case .monthly:
                return SatisfactionTrendSummary(
                    title: "\(month)월 만족도 흐름을 기다리고 있어요",
                    description: "아직 기록된 만족도 데이터가 부족해요. 회고가 쌓이면 월간 흐름을 보여드릴게요."
                )
            }
        }

        let average = values.reduce(0, +) / Double(values.count)
        let delta = lastValue - firstValue
        let maxValue = values.max() ?? lastValue
        let minValue = values.min() ?? lastValue
        let range = maxValue - minValue
        let lastSegmentAverage = averageOfLastSegment(in: values, selectedMode: selectedMode)

        return SatisfactionTrendSummary(
            title: title(delta: delta, average: average, selectedMode: selectedMode, month: month),
            description: description(
                delta: delta,
                range: range,
                lastValue: lastValue,
                lastSegmentAverage: lastSegmentAverage,
                selectedMode: selectedMode
            )
        )
    }

    private static func title(
        delta: Double,
        average: Double,
        selectedMode: SatisfactionChartMode,
        month: Int
    ) -> String {
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
            return "\(periodName) 만족도는 \n큰 변화 없이 이어졌어요"
        }
    }

    private static func description(
        delta: Double,
        range: Double,
        lastValue: Double,
        lastSegmentAverage: Double,
        selectedMode: SatisfactionChartMode
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

    private static func averageOfLastSegment(
        in values: [Double],
        selectedMode: SatisfactionChartMode
    ) -> Double {
        let segmentCount = min(selectedMode == .weekly ? 2 : 7, values.count)
        let segment = values.suffix(segmentCount)
        return segment.reduce(0, +) / Double(segment.count)
    }
}
