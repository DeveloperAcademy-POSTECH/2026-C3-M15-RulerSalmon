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
    @Binding var selectedWeekStartDate: Date?
    let weekOptions: [AnalysisWeekOption]
    let showMonthlyPicker: () -> Void

    var body: some View {
        HStack {
            Spacer()

            switch selectedMode {
            case .weekly:
                WeekSelectionPicker(
                    selectedWeekStartDate: $selectedWeekStartDate,
                    weekOptions: weekOptions
                )
                .frame(width: 136, height: 32)
            case .monthly:
                PeriodSelectorButton(
                    year: year,
                    month: month,
                    action: showMonthlyPicker
                )
                .frame(width: 136, height: 32)
            }

            Spacer()
        }
    }
}
