//
//  WeeklyAnalysisView.swift
//
//  Created by magic3ightball on 6/7/26.
//

import SwiftUI

struct WeeklyAnalysisView: View {
    var body: some View {
        AnalysisView(initialTab: .weekly, navigationTitle: "기간별 인사이트")
    }
}

enum AnalysisTab {
    case weekly
    case monthly
}

struct AnalysisView: View {
    let navigationTitle: String

    @State private var selectedTab: AnalysisTab

    private var selectedData: PeriodAnalysisData {
        PeriodAnalysisMockData.data(for: selectedTab)
    }

    init(initialTab: AnalysisTab, navigationTitle: String) {
        self.navigationTitle = navigationTitle
        _selectedTab = State(initialValue: initialTab)
    }

    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea(.all)

            VStack(spacing: 24) {
                AnalysisSegmentedControl(selectedTab: $selectedTab)
                    .padding(.horizontal, PeriodAnalysisLayout.screenPadding)
                    .padding(.top, 20)
                    .background(Color.white)
                    .zIndex(1)

                ScrollView(showsIndicators: false) {
                    PeriodAnalysisContent(data: selectedData)
                        .padding(.horizontal, PeriodAnalysisLayout.screenPadding)
                        .padding(.bottom, 36)
                }
            }
        }
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private enum PeriodAnalysisLayout {
    static let screenPadding: CGFloat = 16
    static let cardCornerRadius: CGFloat = 18
    static let keywordLabelWidth: CGFloat = 70
    static let keywordCountWidth: CGFloat = 46
    static let chartWidth: CGFloat = 286
    static let chartHeight: CGFloat = 128
    static let trendCardHeight: CGFloat = 204
}

private struct AnalysisSegmentedControl: View {
    @Binding var selectedTab: AnalysisTab

    var body: some View {
        HStack(spacing: 4) {
            tabButton(title: "주간", tab: .weekly)
            tabButton(title: "월간", tab: .monthly)
        }
        .padding(2)
        .frame(height: 32)
        .background {
            Capsule()
                .fill(Color.black.opacity(0.08))
        }
    }

    private func tabButton(title: String, tab: AnalysisTab) -> some View {
        Button {
            selectedTab = tab
        } label: {
            Text(title)
                .font(.system(size: 13.5, weight: selectedTab == tab ? .semibold : .medium))
                .foregroundStyle(Color.black)
                .frame(maxWidth: .infinity)
                .frame(height: 28)
                .background {
                    if selectedTab == tab {
                        Capsule()
                            .fill(Color.white)
                    }
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}

private struct PeriodAnalysisContent: View {
    let data: PeriodAnalysisData

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            EmotionKeywordSection(keywords: data.emotionKeywords)
            RepeatKeywordSection(keywords: data.repeatKeywords)
            SatisfactionTrendSection(points: data.satisfactionPoints)
        }
    }
}

private enum PeriodAnalysisMockData {
    static func data(for tab: AnalysisTab) -> PeriodAnalysisData {
        switch tab {
        case .weekly:
            return weekly
        case .monthly:
            return monthly
        }
    }

    private static let weekly = PeriodAnalysisData(
        emotionKeywords: [
            EmotionKeyword(title: "집중", count: 12),
            EmotionKeyword(title: "성장", count: 10),
            EmotionKeyword(title: "불안", count: 7),
            EmotionKeyword(title: "감사", count: 6),
            EmotionKeyword(title: "도전", count: 5)
        ],
        repeatKeywords: [
            RepeatKeyword(title: "집중", isSelected: true),
            RepeatKeyword(title: "시간", isSelected: false),
            RepeatKeyword(title: "회의", isSelected: false),
            RepeatKeyword(title: "피드백", isSelected: false),
            RepeatKeyword(title: "정리", isSelected: false),
            RepeatKeyword(title: "팀", isSelected: false)
        ],
        satisfactionPoints: [
            SatisfactionPoint(date: "5/20", value: 3.1),
            SatisfactionPoint(date: "5/21", value: 3.3),
            SatisfactionPoint(date: "5/22", value: 4.0),
            SatisfactionPoint(date: "5/23", value: 3.7),
            SatisfactionPoint(date: "5/24", value: 4.2),
            SatisfactionPoint(date: "5/25", value: 4.1)
        ]
    )

    private static let monthly = PeriodAnalysisData(
        emotionKeywords: [
            EmotionKeyword(title: "성장", count: 24),
            EmotionKeyword(title: "감사", count: 18),
            EmotionKeyword(title: "도전", count: 16),
            EmotionKeyword(title: "설렘", count: 14),
            EmotionKeyword(title: "불안", count: 9)
        ],
        repeatKeywords: [
            RepeatKeyword(title: "성장", isSelected: true),
            RepeatKeyword(title: "목표", isSelected: false),
            RepeatKeyword(title: "시간", isSelected: false),
            RepeatKeyword(title: "집중", isSelected: false),
            RepeatKeyword(title: "도전", isSelected: false),
            RepeatKeyword(title: "재미", isSelected: false),
            RepeatKeyword(title: "팀", isSelected: false),
            RepeatKeyword(title: "회고", isSelected: false)
        ],
        satisfactionPoints: [
            SatisfactionPoint(date: "5/14", value: 2.1),
            SatisfactionPoint(date: "5/15", value: 2.4),
            SatisfactionPoint(date: "5/16", value: 3.5),
            SatisfactionPoint(date: "5/17", value: 2.9),
            SatisfactionPoint(date: "5/18", value: 3.7),
            SatisfactionPoint(date: "5/19", value: 3.5)
        ]
    )
}

private struct PeriodAnalysisData {
    let emotionKeywords: [EmotionKeyword]
    let repeatKeywords: [RepeatKeyword]
    let satisfactionPoints: [SatisfactionPoint]
}

private struct EmotionKeyword: Identifiable {
    let id = UUID()
    let title: String
    let count: Int
}

private struct RepeatKeyword: Identifiable {
    let id = UUID()
    let title: String
    let isSelected: Bool
}

private struct SatisfactionPoint: Identifiable {
    let id = UUID()
    let date: String
    let value: CGFloat
}

private struct EmotionKeywordSection: View {
    let keywords: [EmotionKeyword]

    private var maxCount: CGFloat {
        CGFloat(keywords.map(\.count).max() ?? 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("감정 키워드 TOP 5")
                .font(.system(size: 18, weight: .heavy))
                .foregroundStyle(Color.gray900)

            VStack(spacing: 8) {
                ForEach(keywords) { keyword in
                    EmotionKeywordRow(
                        keyword: keyword,
                        progress: CGFloat(keyword.count) / maxCount
                    )
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 34)
            .background {
                RoundedRectangle(cornerRadius: PeriodAnalysisLayout.cardCornerRadius)
                    .fill(Color.white)
                    .shadow(color: Color.gray900.opacity(0.05), radius: 18, x: 0, y: 8)
            }
            .overlay {
                RoundedRectangle(cornerRadius: PeriodAnalysisLayout.cardCornerRadius)
                    .stroke(Color.gray300, lineWidth: 1)
            }
        }
    }
}

private struct EmotionKeywordRow: View {
    let keyword: EmotionKeyword
    let progress: CGFloat

    var body: some View {
        HStack(spacing: 0) {
            Text(keyword.title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.gray900)
                .frame(width: PeriodAnalysisLayout.keywordLabelWidth, alignment: .leading)

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
                .frame(width: PeriodAnalysisLayout.keywordCountWidth, alignment: .trailing)
        }
        .frame(height: 18)
    }
}

private struct RepeatKeywordSection: View {
    let keywords: [RepeatKeyword]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("반복 키워드")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Color.gray900)

            FlowLayout(spacing: 4, lineSpacing: 4) {
                ForEach(keywords) { keyword in
                    Text(keyword.title)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(keyword.isSelected ? Color.blue600 : Color.gray600)
                        .padding(.horizontal, 13)
                        .frame(height: 36)
                        .background {
                            Capsule()
                                .fill(keyword.isSelected ? Color.blue50 : Color.gray50)
                        }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background {
                RoundedRectangle(cornerRadius: PeriodAnalysisLayout.cardCornerRadius)
                    .fill(Color.white)
                    .shadow(color: Color.gray900.opacity(0.05), radius: 18, x: 0, y: 8)
            }
            .overlay {
                RoundedRectangle(cornerRadius: PeriodAnalysisLayout.cardCornerRadius)
                    .stroke(Color.gray300, lineWidth: 1)
            }
        }
    }
}

private struct SatisfactionTrendSection: View {
    let points: [SatisfactionPoint]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("회고 만족도 추이")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Color.gray900)

            VStack {
                LineChart(points: points)
                    .frame(width: PeriodAnalysisLayout.chartWidth, height: PeriodAnalysisLayout.chartHeight)
            }
            .frame(maxWidth: .infinity)
            .frame(height: PeriodAnalysisLayout.trendCardHeight)
            .background {
                RoundedRectangle(cornerRadius: PeriodAnalysisLayout.cardCornerRadius)
                    .fill(Color.white)
                    .shadow(color: Color.gray900.opacity(0.05), radius: 18, x: 0, y: 8)
            }
            .overlay {
                RoundedRectangle(cornerRadius: PeriodAnalysisLayout.cardCornerRadius)
                    .stroke(Color.gray300, lineWidth: 1)
            }
        }
    }
}

private struct LineChart: View {
    let points: [SatisfactionPoint]

    var body: some View {
        VStack(spacing: 4) {
            GeometryReader { geometry in
                let plottedPoints = chartPoints(in: geometry.size)

                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.gray50)

                    Path { path in
                        guard let firstPoint = plottedPoints.first else { return }
                        path.move(to: firstPoint)

                        for point in plottedPoints.dropFirst() {
                            path.addLine(to: point)
                        }
                    }
                    .stroke(
                        Color.blue500.opacity(0.18),
                        style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round, dash: [4, 4])
                    )

                    ForEach(Array(plottedPoints.enumerated()), id: \.offset) { _, point in
                        Circle()
                            .fill(Color.blue500)
                            .frame(width: 8, height: 8)
                            .position(point)
                    }
                }
            }
            .frame(height: 108)

            HStack {
                ForEach(points) { point in
                    Text(point.date)
                        .font(.system(size: 10))
                        .foregroundStyle(Color.gray600)
                        .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 16)
        }
    }

    private func chartPoints(in size: CGSize) -> [CGPoint] {
        guard points.count > 1 else { return [] }

        let horizontalInset: CGFloat = 12
        let topInset: CGFloat = 42
        let bottomInset: CGFloat = 22
        let values = points.map(\.value)
        let minValue = values.min() ?? 0
        let maxValue = values.max() ?? 1
        let range = max(maxValue - minValue, 1)
        let step = (size.width - horizontalInset * 2) / CGFloat(points.count - 1)

        return points.enumerated().map { index, point in
            let x = horizontalInset + CGFloat(index) * step
            let normalizedValue = (point.value - minValue) / range
            let yRange = size.height - topInset - bottomInset
            let y = topInset + (1 - normalizedValue) * yRange
            return CGPoint(x: x, y: y)
        }
    }
}

private struct FlowLayout: Layout {
    let spacing: CGFloat
    let lineSpacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var currentX: CGFloat = 0
        var currentLineHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        var widestLine: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            let needsNewLine = currentX > 0 && currentX + spacing + size.width > maxWidth

            if needsNewLine {
                widestLine = max(widestLine, currentX)
                totalHeight += currentLineHeight + lineSpacing
                currentX = 0
                currentLineHeight = 0
            }

            if currentX > 0 {
                currentX += spacing
            }

            currentX += size.width
            currentLineHeight = max(currentLineHeight, size.height)
        }

        widestLine = max(widestLine, currentX)
        totalHeight += currentLineHeight

        return CGSize(width: maxWidth.isFinite ? maxWidth : widestLine, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var currentX = bounds.minX
        var currentY = bounds.minY
        var currentLineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            let needsNewLine = currentX > bounds.minX && currentX + spacing + size.width > bounds.maxX

            if needsNewLine {
                currentX = bounds.minX
                currentY += currentLineHeight + lineSpacing
                currentLineHeight = 0
            }

            subview.place(
                at: CGPoint(x: currentX, y: currentY),
                proposal: ProposedViewSize(size)
            )

            currentX += size.width + spacing
            currentLineHeight = max(currentLineHeight, size.height)
        }
    }
}

struct WeeklyAnalysisView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            WeeklyAnalysisView()
        }
    }
}
