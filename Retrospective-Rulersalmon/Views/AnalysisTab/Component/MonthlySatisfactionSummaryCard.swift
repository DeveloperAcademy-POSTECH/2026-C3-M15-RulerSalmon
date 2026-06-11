//
//  MonthlySatisfactionSummaryCard.swift
//
//  Created by chaem on 6/11/26.
//

import SwiftUI

struct MonthlySatisfactionSummaryCard: View {
    let label: String
    let score: String
    let title: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 8) {
                Text(label)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.gray600)

                Text(title)
                    .font(.system(size: 23, weight: .bold))
                    .foregroundStyle(Color.gray900)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(alignment: .lastTextBaseline, spacing: 0) {
                Text(score)
                    .font(.system(size: 26, weight: .heavy))
                    .foregroundStyle(Color.blue500)

                Text("/5")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.gray600)
            }
            .layoutPriority(1)
        }
        .padding(AnalysisHomeLayout.cardPadding)
        .background {
            RoundedRectangle(cornerRadius: AnalysisHomeLayout.cardCornerRadius)
                .fill(Color.blue50)
        }
    }
}

