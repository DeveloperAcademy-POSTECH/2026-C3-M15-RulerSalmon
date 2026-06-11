//
//  SatisfactionChartModeSegmentedControl.swift
//
//  Created by chaem on 6/11/26.
//

import SwiftUI

struct SatisfactionChartModeSegmentedControl: View {
    @Binding var selectedMode: SatisfactionChartMode

    var body: some View {
        HStack(spacing: 0) {
            ForEach(SatisfactionChartMode.allCases, id: \.self) { mode in
                Button {
                    selectedMode = mode
                } label: {
                    Text(mode.title)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(selectedMode == mode ? Color.gray900 : Color.gray600)
                        .frame(maxWidth: .infinity)
                        .frame(height: 32)
                        .background {
                            Capsule()
                                .fill(selectedMode == mode ? Color.white : Color.clear)
                        }
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selectedMode == mode ? .isSelected : [])
            }
        }
        .padding(3)
        .background {
            Capsule()
                .fill(Color.gray200)
        }
    }
}
