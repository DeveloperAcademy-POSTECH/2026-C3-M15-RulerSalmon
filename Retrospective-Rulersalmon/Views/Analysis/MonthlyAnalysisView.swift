import SwiftUI

struct MonthlyAnalysisView: View {
    let onBackToHome: (() -> Void)?

    init(onBackToHome: (() -> Void)? = nil) {
        self.onBackToHome = onBackToHome
    }

    var body: some View {
        AnalysisView(initialTab: .monthly, navigationTitle: "월간 인사이트", onBackToHome: onBackToHome)
    }
}

struct MonthlyAnalysisContent: View {
    private let emotionKeywords = MonthlyAnalysisMockData.emotionKeywords
    private let repeatKeywords = MonthlyAnalysisMockData.repeatKeywords
    private let satisfactionPoints = MonthlyAnalysisMockData.satisfactionPoints

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            MonthlyEmotionKeywordSection(keywords: emotionKeywords)
            MonthlyRepeatKeywordSection(keywords: repeatKeywords)
            MonthlySatisfactionTrendSection(points: satisfactionPoints)
        }
    }
}

private enum MonthlyAnalysisColor {
    static let gray900 = Color(red: 0.098, green: 0.122, blue: 0.157)
    static let gray600 = Color(red: 0.42, green: 0.463, blue: 0.518)
    static let gray400 = Color(red: 0.502, green: 0.502, blue: 0.502)
    static let gray300 = Color(red: 0.82, green: 0.839, blue: 0.859)
    static let gray200 = Color(red: 0.898, green: 0.91, blue: 0.922)
    static let gray100 = Color(red: 0.969, green: 0.969, blue: 0.969)
    static let gray50 = Color(red: 0.976, green: 0.98, blue: 0.984)
    static let blue500 = Color(red: 0.192, green: 0.51, blue: 0.965)
    static let blueText = Color(red: 0.133, green: 0.447, blue: 0.922)
    static let blue50 = Color(red: 0.91, green: 0.953, blue: 1)
}

private enum MonthlyAnalysisMockData {
    static let emotionKeywords: [MonthlyEmotionKeyword] = [
        MonthlyEmotionKeyword(title: "성장", count: 24),
        MonthlyEmotionKeyword(title: "감사", count: 18),
        MonthlyEmotionKeyword(title: "도전", count: 16),
        MonthlyEmotionKeyword(title: "설렘", count: 14),
        MonthlyEmotionKeyword(title: "불안", count: 9)
    ]

    static let repeatKeywords: [MonthlyRepeatKeyword] = [
        MonthlyRepeatKeyword(title: "성장", isSelected: true),
        MonthlyRepeatKeyword(title: "목표", isSelected: false),
        MonthlyRepeatKeyword(title: "시간", isSelected: false),
        MonthlyRepeatKeyword(title: "집중", isSelected: false),
        MonthlyRepeatKeyword(title: "도전", isSelected: false),
        MonthlyRepeatKeyword(title: "재미", isSelected: false),
        MonthlyRepeatKeyword(title: "팀", isSelected: false),
        MonthlyRepeatKeyword(title: "팀", isSelected: false)
    ]

    static let satisfactionPoints: [MonthlySatisfactionPoint] = [
        MonthlySatisfactionPoint(date: "5/14", value: 2.1),
        MonthlySatisfactionPoint(date: "5/15", value: 2.4),
        MonthlySatisfactionPoint(date: "5/16", value: 3.5),
        MonthlySatisfactionPoint(date: "5/17", value: 2.9),
        MonthlySatisfactionPoint(date: "5/18", value: 3.7),
        MonthlySatisfactionPoint(date: "5/19", value: 3.5)
    ]
}

private struct MonthlyEmotionKeyword: Identifiable {
    let id = UUID()
    let title: String
    let count: Int
}

private struct MonthlyRepeatKeyword: Identifiable {
    let id = UUID()
    let title: String
    let isSelected: Bool
}

private struct MonthlySatisfactionPoint: Identifiable {
    let id = UUID()
    let date: String
    let value: CGFloat
}

private struct MonthlyEmotionKeywordSection: View {
    let keywords: [MonthlyEmotionKeyword]

    private var maxCount: CGFloat {
        CGFloat(keywords.map(\.count).max() ?? 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("감정 키워드 TOP 5")
                .font(.system(size: 18, weight: .heavy))
                .foregroundStyle(MonthlyAnalysisColor.gray900)

            VStack(spacing: 8) {
                ForEach(keywords) { keyword in
                    MonthlyEmotionKeywordRow(
                        keyword: keyword,
                        progress: CGFloat(keyword.count) / maxCount
                    )
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 34)
            .background {
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white)
                    .shadow(color: Color(red: 0.031, green: 0.071, blue: 0.137).opacity(0.05), radius: 18, x: 0, y: 8)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .stroke(MonthlyAnalysisColor.gray300, lineWidth: 1)
            }
        }
    }
}

private struct MonthlyEmotionKeywordRow: View {
    let keyword: MonthlyEmotionKeyword
    let progress: CGFloat

    var body: some View {
        HStack(spacing: 0) {
            Text(keyword.title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(MonthlyAnalysisColor.gray900)
                .frame(width: 70, alignment: .leading)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(MonthlyAnalysisColor.gray200)
                        .frame(height: 6)

                    Capsule()
                        .fill(MonthlyAnalysisColor.blue500)
                        .frame(width: geometry.size.width * progress, height: 6)
                }
                .frame(maxHeight: .infinity)
            }
            .frame(height: 18)

            Text("\(keyword.count)")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(MonthlyAnalysisColor.gray600)
                .frame(width: 46, alignment: .trailing)
        }
        .frame(height: 18)
    }
}

private struct MonthlyRepeatKeywordSection: View {
    let keywords: [MonthlyRepeatKeyword]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("반복 키워드")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(MonthlyAnalysisColor.gray900)

            FlowLayout(spacing: 4, lineSpacing: 4) {
                ForEach(keywords) { keyword in
                    Text(keyword.title)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(keyword.isSelected ? MonthlyAnalysisColor.blueText : MonthlyAnalysisColor.gray400)
                        .padding(.horizontal, 13)
                        .frame(height: 36)
                        .background {
                            Capsule()
                                .fill(keyword.isSelected ? MonthlyAnalysisColor.blue50 : MonthlyAnalysisColor.gray100)
                        }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background {
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white)
                    .shadow(color: Color(red: 0.031, green: 0.071, blue: 0.137).opacity(0.05), radius: 18, x: 0, y: 8)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .stroke(MonthlyAnalysisColor.gray300, lineWidth: 1)
            }
        }
    }
}

private struct MonthlySatisfactionTrendSection: View {
    let points: [MonthlySatisfactionPoint]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("회고 만족도 추이")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(MonthlyAnalysisColor.gray900)

            VStack {
                MonthlyLineChart(points: points)
                    .frame(width: 286, height: 128)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 204)
            .background {
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white)
                    .shadow(color: Color(red: 0.031, green: 0.071, blue: 0.137).opacity(0.05), radius: 18, x: 0, y: 8)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .stroke(MonthlyAnalysisColor.gray300, lineWidth: 1)
            }
        }
    }
}

private struct MonthlyLineChart: View {
    let points: [MonthlySatisfactionPoint]

    var body: some View {
        VStack(spacing: 4) {
            GeometryReader { geometry in
                let plottedPoints = chartPoints(in: geometry.size)

                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(MonthlyAnalysisColor.gray50)

                    Path { path in
                        guard let firstPoint = plottedPoints.first else { return }
                        path.move(to: firstPoint)

                        for point in plottedPoints.dropFirst() {
                            path.addLine(to: point)
                        }
                    }
                    .stroke(
                        MonthlyAnalysisColor.blue500.opacity(0.18),
                        style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round, dash: [4, 4])
                    )

                    ForEach(Array(plottedPoints.enumerated()), id: \.offset) { _, point in
                        Circle()
                            .fill(MonthlyAnalysisColor.blue500)
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
                        .foregroundStyle(MonthlyAnalysisColor.gray600)
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

struct MonthlyAnalysisView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            MonthlyAnalysisView()
        }
    }
}
