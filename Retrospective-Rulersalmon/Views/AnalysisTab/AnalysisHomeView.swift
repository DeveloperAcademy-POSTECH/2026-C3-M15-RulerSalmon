//
//  AnalysisHomeView.swift
//
//  Created by magic3ightball on 6/7/26.
//

import SwiftUI

struct AnalysisHomeView: View {
    @StateObject private var viewModel = AnalysisHomeViewModel()

    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea(.all)

            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 32) {
                    PeriodSelectorButton(
                        year: viewModel.selectedYear,
                        month: viewModel.selectedMonth
                    ) {
                        viewModel.showPeriodSheet()
                    }

                    MonthlySatisfactionSummaryCard(
                        month: viewModel.selectedMonth,
                        score: viewModel.selectedData.monthlyScore,
                        title: viewModel.selectedData.monthlyTitle
                    )

                    SatisfactionTrendSection(
                        data: viewModel.selectedData,
                        year: viewModel.selectedYear,
                        month: viewModel.selectedMonth
                    )
                    SentimentRatioSection()
                    StrengthKeywordSection(keywords: viewModel.selectedData.strengthKeywords)
                    InsightListSection()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, AnalysisHomeLayout.screenPadding)
                .padding(.top, 16)
                .padding(.bottom, 36)
            }
        }
        .onAppear {
            viewModel.normalizeSelectedPeriod()
        }
        .sheet(isPresented: $viewModel.isPeriodSheetPresented) {
            PeriodSelectionSheet(
                selectedYear: $viewModel.selectedYear,
                selectedMonth: $viewModel.selectedMonth,
                availableRange: viewModel.availableRange,
                isPresented: $viewModel.isPeriodSheetPresented
            )
            .presentationDetents([.height(300)])
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("회고 분석")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Color.gray900)
            }
        }
        .toolbarBackground(Color.white, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }
}

private enum AnalysisHomeLayout {
    static let screenPadding: CGFloat = 16
    static let cardPadding: CGFloat = 16
    static let cardCornerRadius: CGFloat = 18
    static let chartHeight: CGFloat = 152
}

private struct MonthlySatisfactionSummaryCard: View {
    let month: Int
    let score: String
    let title: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 8) {
                Text("\(month)월 만족도")
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

private struct SatisfactionTrendSection: View {
    let data: MonthlyAnalysisData
    let year: Int
    let month: Int

    @State private var selectedChartMode: SatisfactionChartMode = .weekly

    private var selectedPoints: [SatisfactionPoint] {
        switch selectedChartMode {
        case .weekly:
            return data.weeklySatisfactionPoints
        case .monthly:
            return data.monthlySatisfactionPoints
        }
    }

    private var xAxisLabels: [SatisfactionAxisLabel] {
        switch selectedChartMode {
        case .weekly:
            return weeklyAxisLabels
        case .monthly:
            return monthlyAxisLabels
        }
    }

    private var chartRange: String {
        switch selectedChartMode {
        case .weekly:
            return weeklyChartRange
        case .monthly:
            return "\(year)년 \(month)월"
        }
    }

    private var weeklyAxisLabels: [SatisfactionAxisLabel] {
        let calendar = analysisCalendar
        let startDate = currentWeekStartDate

        return (0..<7).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: startDate) else {
                return nil
            }

            return SatisfactionAxisLabel(index: offset, title: shortMonthDayString(from: date))
        }
    }

    private var monthlyAxisLabels: [SatisfactionAxisLabel] {
        let dayCount = max(data.monthlySatisfactionPoints.count, 1)
        let labelDays = [1, 8, 15, 22, dayCount]

        return labelDays
            .reduce(into: [Int]()) { days, day in
                guard !days.contains(day), day <= dayCount else { return }
                days.append(day)
            }
            .map { day in
                SatisfactionAxisLabel(index: day - 1, title: "\(day)일")
            }
    }

    private var weeklyChartRange: String {
        guard
            let firstLabel = weeklyAxisLabels.first?.title,
            let lastLabel = weeklyAxisLabels.last?.title
        else {
            return ""
        }

        return "\(firstLabel) ~ \(lastLabel)"
    }

    private func shortMonthDayString(from date: Date) -> String {
        let calendar = analysisCalendar
        return "\(calendar.component(.month, from: date)).\(calendar.component(.day, from: date))"
    }

    private var currentWeekStartDate: Date {
        let calendar = analysisCalendar
        let today = calendar.startOfDay(for: Date())
        let weekday = calendar.component(.weekday, from: today)
        let daysFromMonday = (weekday + 5) % 7
        return calendar.date(byAdding: .day, value: -daysFromMonday, to: today) ?? today
    }

    private var analysisCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        calendar.firstWeekday = 2
        return calendar
    }

    private var summaryTitle: String {
        switch selectedChartMode {
        case .weekly:
            return "이번 주 만족도 흐름을 확인해요"
        case .monthly:
            return "6월은 후반부로 갈수록 더 안정적이었어요"
        }
    }

    private var summaryDescription: String {
        switch selectedChartMode {
        case .weekly:
            return "오늘에 가까워질수록 긍정 흐름이 커졌고, 6월 전체 상승 흐름의 시작점으로 보여요."
        case .monthly:
            return "일별 변동은 있었지만 전체 흐름은 완만하게 좋아졌고, 마지막 구간의 만족도가 높게 유지됐어요."
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text("만족도 흐름")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color.gray900)

                Spacer()

                Text(chartRange)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.gray600)
            }

            SatisfactionChartModeSegmentedControl(selectedMode: $selectedChartMode)

            SatisfactionLineChart(
                points: selectedPoints,
                xAxisLabels: xAxisLabels,
                showsPointMarkers: selectedChartMode == .weekly,
                highlightsLastPoint: selectedChartMode == .monthly
            )
            .frame(height: AnalysisHomeLayout.chartHeight)
            .padding(.top, 14)
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(Color.gray200)
                    .frame(height: 1)
            }

            VStack(alignment: .leading, spacing: 7) {
                Text(summaryTitle)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.gray900)
                    .lineSpacing(2)

                Text(summaryDescription)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.gray600)
                    .lineSpacing(3)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, AnalysisHomeLayout.cardPadding)
            .padding(.vertical, 14)
            .background {
                RoundedRectangle(cornerRadius: AnalysisHomeLayout.cardCornerRadius)
                    .fill(Color.gray50)
            }
        }
    }
}

private enum SatisfactionChartMode: CaseIterable {
    case weekly
    case monthly

    var title: String {
        switch self {
        case .weekly:
            return "주간"
        case .monthly:
            return "월간"
        }
    }
}

private struct SatisfactionChartModeSegmentedControl: View {
    @Binding var selectedMode: SatisfactionChartMode

    var body: some View {
        HStack(spacing: 0) {
            ForEach(SatisfactionChartMode.allCases, id: \.self) { mode in
                Button {
                    selectedMode = mode
                } label: {
                    Text(mode.title)
                        .font(.system(size: 13, weight: .bold))
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

private struct StrengthKeywordSection: View {
    let keywords: [StrengthKeyword]

    private var maxCount: CGFloat {
        CGFloat(keywords.map(\.count).max() ?? 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("감정 키워드")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Color.gray900)

            VStack(spacing: 8) {
                ForEach(keywords) { keyword in
                    StrengthKeywordRow(
                        keyword: keyword,
                        progress: CGFloat(keyword.count) / maxCount
                    )
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 34)
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

private struct StrengthKeywordRow: View {
    let keyword: StrengthKeyword
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

private struct SentimentRatioSection: View {
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
                            .frame(width: geometry.size.width * 0.82)
                    }
                }
                .frame(height: 10)

                HStack {
                    Text("긍정 82%")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.blue500)

                    Spacer()

                    Text("부정 18%")
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
            .accessibilityLabel("긍정 82퍼센트, 부정 18퍼센트")
        }
    }
}

private struct InsightListSection: View {
    private let insights = [
        InsightItem(
            title: "강점 포인트",
            description: "이번 달에는 성장과 감사 키워드가 자주 나타났어요. 월간 흐름에서는 후반부가 가장 안정적으로 보였어요."
        ),
        InsightItem(
            title: "반성 포인트",
            description: "시간 관리 회고는 월간 누적에서 계속 반복되고 있어요. 다음 달에는 우선순위를 먼저 정하는 방식이 좋아 보여요."
        )
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("인사이트")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Color.gray900)

            VStack(spacing: 10) {
                ForEach(insights) { insight in
                    InsightCard(item: insight)
                }
            }
        }
    }
}

private struct InsightItem: Identifiable {
    let id = UUID()
    let title: String
    let description: String
}

private struct InsightCard: View {
    let item: InsightItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(item.title)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Color.gray900)

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
}

private struct PeriodSelectorButton: View {
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

private struct PeriodSelectionSheet: View {
    @Binding var selectedYear: Int
    @Binding var selectedMonth: Int
    let availableRange: PeriodRange
    @Binding var isPresented: Bool

    @State private var displayedYear: Int

    init(
        selectedYear: Binding<Int>,
        selectedMonth: Binding<Int>,
        availableRange: PeriodRange,
        isPresented: Binding<Bool>
    ) {
        _selectedYear = selectedYear
        _selectedMonth = selectedMonth
        self.availableRange = availableRange
        _isPresented = isPresented
        _displayedYear = State(initialValue: selectedYear.wrappedValue)
    }

    var body: some View {
        VStack(spacing: 18) {
            Capsule()
                .fill(Color.gray300)
                .frame(width: 42, height: 4)
                .padding(.top, 8)

            HStack {
                Text("기간 선택")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Color.gray900)

                Spacer()

                Button("완료") {
                    isPresented = false
                }
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Color.blue600)
                .buttonStyle(.plain)
            }

            HStack {
                yearButton(systemName: "chevron.left", year: displayedYear - 1)

                Text("\(String(displayedYear))년")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.gray900)
                    .frame(maxWidth: .infinity)

                yearButton(systemName: "chevron.right", year: displayedYear + 1)
            }
            .frame(height: 38)
            .background {
                Capsule()
                    .fill(Color.gray50)
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                ForEach(1...12, id: \.self) { month in
                    monthButton(month)
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 18)
    }

    private func yearButton(systemName: String, year: Int) -> some View {
        Button {
            guard availableRange.canMove(to: year) else { return }
            displayedYear = year
        } label: {
            Image(systemName: systemName)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(availableRange.canMove(to: year) ? Color.gray600 : Color.gray300)
                .frame(width: 38, height: 38)
        }
        .buttonStyle(.plain)
        .disabled(!availableRange.canMove(to: year))
    }

    private func monthButton(_ month: Int) -> some View {
        let isEnabled = availableRange.isMonthEnabled(year: displayedYear, month: month)
        let isSelected = selectedYear == displayedYear && selectedMonth == month

        return Button {
            guard isEnabled else { return }
            selectedYear = displayedYear
            selectedMonth = month
            isPresented = false
        } label: {
            Text("\(month)월")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(monthTextColor(isEnabled: isEnabled, isSelected: isSelected))
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background {
                    Capsule()
                        .fill(isSelected ? Color.blue50 : Color.gray50)
                }
                .overlay {
                    Capsule()
                        .stroke(isSelected ? Color.blue500 : Color.clear, lineWidth: 1.5)
                }
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .accessibilityLabel("\(displayedYear)년 \(month)월")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func monthTextColor(isEnabled: Bool, isSelected: Bool) -> Color {
        if !isEnabled {
            return Color.gray300
        }

        return isSelected ? Color.blue600 : Color.gray600
    }
}

private struct SatisfactionLineChart: View {
    let points: [SatisfactionPoint]
    let xAxisLabels: [SatisfactionAxisLabel]
    let showsPointMarkers: Bool
    let highlightsLastPoint: Bool

    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                drawHorizontalGrid(in: &context, size: size)
                drawLine(in: &context, size: size)
                drawPointMarkers(in: &context, size: size)
                drawAxisLabels(in: &context, size: size)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }

    private func drawHorizontalGrid(in context: inout GraphicsContext, size: CGSize) {
        for value in [5, 3, 1] {
            let y = chartY(for: CGFloat(value), in: size)
            var path = Path()
            path.move(to: CGPoint(x: chartLeftInset, y: y))
            path.addLine(to: CGPoint(x: plotMaxX(in: size), y: y))
            context.stroke(path, with: .color(Color.gray200), style: StrokeStyle(lineWidth: 1))
        }
    }

    private func drawLine(in context: inout GraphicsContext, size: CGSize) {
        let validPoints = points.enumerated().compactMap { index, point -> (Int, CGFloat)? in
            guard let value = point.value else { return nil }
            return (index, value)
        }

        guard validPoints.count > 1 else { return }

        for pair in zip(validPoints, validPoints.dropFirst()) {
            let previous = pair.0
            let current = pair.1

            guard current.0 == previous.0 + 1 else { continue }

            var path = Path()
            path.move(to: chartPoint(index: previous.0, value: previous.1, in: size))
            path.addLine(to: chartPoint(index: current.0, value: current.1, in: size))
            context.stroke(
                path,
                with: .color(Color.blue500),
                style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
            )
        }
    }

    private func drawPointMarkers(in context: inout GraphicsContext, size: CGSize) {
        for (index, point) in points.enumerated() {
            guard let value = point.value else { continue }
            let isLastPoint = index == points.indices.last

            guard showsPointMarkers || (highlightsLastPoint && isLastPoint) else {
                continue
            }

            let center = chartPoint(index: index, value: value, in: size)
            let radius: CGFloat = 3.2
            let rect = CGRect(
                x: center.x - radius,
                y: center.y - radius,
                width: radius * 2,
                height: radius * 2
            )
            context.fill(Path(ellipseIn: rect), with: .color(Color.blue500))
        }
    }

    private func drawAxisLabels(in context: inout GraphicsContext, size: CGSize) {
        for value in [5, 3, 1] {
            let text = context.resolve(
                Text("\(value)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color.gray600)
            )
            context.draw(
                text,
                at: CGPoint(x: plotMaxX(in: size) + 12, y: chartY(for: CGFloat(value), in: size)),
                anchor: .leading
            )
        }

        for label in xAxisLabels {
            let text = context.resolve(
                Text(label.title)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color.gray600)
            )
            context.draw(
                text,
                at: CGPoint(x: chartX(for: label.index, in: size), y: size.height - 6),
                anchor: .bottom
            )
        }
    }

    private func chartPoint(index: Int, value: CGFloat, in size: CGSize) -> CGPoint {
        CGPoint(
            x: chartX(for: index, in: size),
            y: chartY(for: value, in: size)
        )
    }

    private func chartX(for index: Int, in size: CGSize) -> CGFloat {
        guard points.count > 1 else {
            return chartLeftInset + plotWidth(in: size) / 2
        }

        return chartLeftInset + CGFloat(index) / CGFloat(points.count - 1) * plotWidth(in: size)
    }

    private func chartY(for value: CGFloat, in size: CGSize) -> CGFloat {
        let normalizedValue = min(max(value / 5, 0), 1)
        return plotMaxY(in: size) - (normalizedValue * plotHeight(in: size))
    }

    private var chartLeftInset: CGFloat {
        30
    }

    private var chartRightInset: CGFloat {
        42
    }

    private var chartTopInset: CGFloat {
        6
    }

    private var chartBottomInset: CGFloat {
        22
    }

    private func plotWidth(in size: CGSize) -> CGFloat {
        max(size.width - chartLeftInset - chartRightInset, 1)
    }

    private func plotHeight(in size: CGSize) -> CGFloat {
        max(size.height - chartTopInset - chartBottomInset, 1)
    }

    private func plotMaxX(in size: CGSize) -> CGFloat {
        chartLeftInset + plotWidth(in: size)
    }

    private func plotMaxY(in size: CGSize) -> CGFloat {
        chartTopInset + plotHeight(in: size)
    }
}

struct AnalysisHomeView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            AnalysisHomeView()
        }
    }
}
