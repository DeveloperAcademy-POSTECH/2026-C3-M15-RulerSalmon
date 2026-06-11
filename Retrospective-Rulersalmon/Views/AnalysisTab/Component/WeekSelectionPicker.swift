//
//  WeekSelectionPicker.swift
//
//  Created by chaem on 6/11/26.
//

import SwiftUI

struct WeekSelectionPicker: View {
    @Binding var selectedWeekStartDate: Date?
    let weekOptions: [AnalysisWeekOption]

    var body: some View {
        Menu {
            ForEach(weekOptions) { option in
                Button {
                    selectedWeekStartDate = option.startDate
                } label: {
                    Text(option.title)
                }
            }
        } label: {
            HStack(spacing: 0) {
                Text(selectedWeekTitle)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.blue500)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color.blue500)
                    .frame(width: 16, alignment: .trailing)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
        }
        .disabled(weekOptions.isEmpty)
    }

    private var selectedWeekTitle: String {
        guard let selectedWeekStartDate else {
            return weekOptions.first?.title ?? "주차"
        }

        return weekOptions.first { option in
            Calendar.current.isDate(option.startDate, inSameDayAs: selectedWeekStartDate)
        }?.title ?? weekOptions.first?.title ?? "주차"
    }
}

