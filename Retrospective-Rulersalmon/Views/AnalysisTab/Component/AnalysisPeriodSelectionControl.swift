//
//  AnalysisPeriodSelectionControl.swift
//
//  Created by chaem on 6/11/26.
//

import SwiftUI

struct AnalysisPeriodSelectionControl: View {
    let selectedMode: SatisfactionChartMode
    let year: Int
    let month: Int
    let selectedWeekStartDate: Date?
    let weekOptions: [AnalysisWeekOption]
    let canMoveToPreviousPeriod: Bool
    let canMoveToNextPeriod: Bool
    let moveToPreviousPeriod: () -> Void
    let moveToNextPeriod: () -> Void

    var body: some View {
        HStack(spacing: 18) {
            periodMoveButton(
                systemName: "chevron.left",
                isEnabled: canMoveToPreviousPeriod,
                action: moveToPreviousPeriod
            )

            Text(periodTitle)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Color.gray900)
                .monospacedDigit()
                .frame(minWidth: selectedMode == .weekly ? 116 : 44)

            periodMoveButton(
                systemName: "chevron.right",
                isEnabled: canMoveToNextPeriod,
                action: moveToNextPeriod
            )
        }
        .frame(maxWidth: .infinity)
    }

    private var periodTitle: String {
        switch selectedMode {
        case .weekly:
            guard let selectedWeekStartDate,
                  let selectedOption = weekOptions.first(where: {
                      Calendar.current.isDate($0.startDate, inSameDayAs: selectedWeekStartDate)
                  }) else {
                return weekOptions.last?.title ?? "주간"
            }

            return selectedOption.navigationTitle
        case .monthly:
            return "\(month)월"
        }
    }

    private func periodMoveButton(
        systemName: String,
        isEnabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(isEnabled ? Color.gray600 : Color.gray300)
                .frame(width: 24, height: 32)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
}

private extension AnalysisWeekOption {
    var navigationTitle: String {
        let calendar = Calendar.current
        let startMonth = String(format: "%02d", calendar.component(.month, from: startDate))
        let startDay = String(format: "%02d", calendar.component(.day, from: startDate))
        let endDate = calendar.date(byAdding: .day, value: 6, to: startDate) ?? startDate
        let endMonth = String(format: "%02d", calendar.component(.month, from: endDate))
        let endDay = String(format: "%02d", calendar.component(.day, from: endDate))

        return "\(startMonth).\(startDay)-\(endMonth).\(endDay)"
    }
}
