//
//  PeriodSelectorButton.swift
//
//  Created by chaem on 6/11/26.
//

import SwiftUI

struct PeriodSelectorButton: View {
    let year: Int
    let month: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text("\(String(year))년 \(month)월")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.gray900)

                Image(systemName: "chevron.down")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.gray600)
            }
            .padding(.horizontal, 14)
            .frame(height: 36)
            .background {
                Capsule()
                    .fill(Color.gray50)
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .accessibilityLabel("\(year)년 \(month)월 기간 선택")
    }
}

