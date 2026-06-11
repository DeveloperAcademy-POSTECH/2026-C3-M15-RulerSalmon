//
//  SentimentRatioSection.swift
//
//  Created by chaem on 6/11/26.
//

import SwiftUI

struct SentimentRatioSection: View {
    let positivePercentage: Double
    let negativePercentage: Double

    private var clampedPositivePercentage: Double {
        max(0, min(positivePercentage, 100))
    }

    private var clampedNegativePercentage: Double {
        max(0, min(negativePercentage, 100))
    }

    private var positiveRatio: CGFloat {
        CGFloat(clampedPositivePercentage / 100)
    }

    private var positiveText: String {
        String(format: "%.0f", clampedPositivePercentage)
    }

    private var negativeText: String {
        String(format: "%.0f", clampedNegativePercentage)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("감정 비율")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Color.gray900)

            VStack(spacing: 10) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.gray200)

                        Capsule()
                            .fill(Color.blue500)
                            .frame(width: geometry.size.width * positiveRatio)
                    }
                }
                .frame(height: 10)

                HStack {
                    Text("긍정 \(positiveText)%")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.blue500)

                    Spacer()

                    Text("부정 \(negativeText)%")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.gray600)
                }
            }
            .padding(AnalysisHomeLayout.cardPadding)
            .background {
                RoundedRectangle(cornerRadius: AnalysisHomeLayout.cardCornerRadius)
                    .fill(Color.white)
            }
            .overlay {
                RoundedRectangle(cornerRadius: AnalysisHomeLayout.cardCornerRadius)
                    .stroke(Color.gray300, lineWidth: 1)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("긍정 \(positiveText)퍼센트, 부정 \(negativeText)퍼센트")
        }
    }
}

