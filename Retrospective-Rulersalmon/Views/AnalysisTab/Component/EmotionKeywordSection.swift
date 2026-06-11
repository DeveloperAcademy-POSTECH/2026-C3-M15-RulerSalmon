//
//  EmotionKeywordSection.swift
//
//  Created by chaem on 6/11/26.
//

import SwiftUI

struct EmotionKeywordSection: View {
    let keywords: [EmotionKeyword]

    private var maxCount: CGFloat {
        CGFloat(keywords.map(\.count).max() ?? 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("감정 키워드 top5")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Color.gray900)

            VStack(spacing: 8) {
                if keywords.isEmpty {
                    Text("아직 누적된 감정 키워드가 없어요.")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.gray600)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    ForEach(keywords) { keyword in
                        EmotionRow(
                            keyword: keyword,
                            progress: CGFloat(keyword.count) / maxCount
                        )
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, keywords.isEmpty ? 28 : 34)
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
    }
}

private struct EmotionRow: View {
    let keyword: EmotionKeyword
    let progress: CGFloat

    var body: some View {
        HStack(spacing: 0) {
            Text(keyword.title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.gray900)
                .frame(width: 70, alignment: .leading)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.gray200)
                        .frame(height: 6)

                    Capsule()
                        .fill(Color.blue500)
                        .frame(width: geometry.size.width * progress, height: 6)
                }
                .frame(maxHeight: .infinity)
            }
            .frame(height: 18)

            Text("\(keyword.count)")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.gray600)
                .frame(width: 46, alignment: .trailing)
        }
        .frame(height: 18)
    }
}

