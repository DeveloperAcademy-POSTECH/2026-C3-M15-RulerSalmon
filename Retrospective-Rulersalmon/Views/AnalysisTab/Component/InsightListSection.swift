//
//  InsightListSection.swift
//
//  Created by chaem on 6/11/26.
//

import SwiftUI

struct InsightListSection: View {
    let insights: [AnalysisInsightItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("인사이트")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Color.gray900)

            if insights.isEmpty {
                EmptyInsightCard()
            } else {
                VStack(spacing: 10) {
                    ForEach(insights) { insight in
                        InsightCard(item: insight)
                    }
                }
            }
        }
    }
}

private struct InsightCard: View {
    let item: AnalysisInsightItem

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(item.title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.gray900)

                Text(kindTitle)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(kindColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background {
                        Capsule()
                            .fill(kindColor.opacity(0.12))
                    }

                Spacer(minLength: 8)
            }

            Text(item.description)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.gray600)
                .lineSpacing(3)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(AnalysisHomeLayout.cardPadding)
        .background {
            RoundedRectangle(cornerRadius: AnalysisHomeLayout.cardCornerRadius)
                .fill(Color.white)
                .shadow(color: Color.gray900.opacity(0.05), radius: 18, x: 0, y: 8)
        }
        .overlay {
            RoundedRectangle(cornerRadius: AnalysisHomeLayout.cardCornerRadius)
                .stroke(Color.gray300, lineWidth: 1)
        }
    }

    private var kindTitle: String {
        switch item.kind {
        case "strength":
            return "강점"
        case "reflection":
            return "반성"
        default:
            return "인사이트"
        }
    }

    private var kindColor: Color {
        switch item.kind {
        case "strength":
            return Color.blue500
        case "reflection":
            return Color.gray600
        default:
            return Color.gray900
        }
    }
}

private struct EmptyInsightCard: View {
    var body: some View {
        Text("아직 이 기간에 반복 인사이트가 충분히 쌓이지 않았어요.")
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(Color.gray600)
            .lineSpacing(3)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(AnalysisHomeLayout.cardPadding)
            .background {
                RoundedRectangle(cornerRadius: AnalysisHomeLayout.cardCornerRadius)
                    .fill(Color.white)
            }
            .overlay {
                RoundedRectangle(cornerRadius: AnalysisHomeLayout.cardCornerRadius)
                    .stroke(Color.gray300, lineWidth: 1)
            }
    }
}
