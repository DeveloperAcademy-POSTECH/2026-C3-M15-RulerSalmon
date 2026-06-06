import SwiftUI

struct WeeklyAnalysisView: View {
    let onBackToHome: (() -> Void)?

    init(onBackToHome: (() -> Void)? = nil) {
        self.onBackToHome = onBackToHome
    }

    var body: some View {
        AnalysisView(initialTab: .weekly, navigationTitle: "주간 인사이트", onBackToHome: onBackToHome)
    }
}

enum AnalysisTab {
    case weekly
    case monthly
}

struct AnalysisView: View {
    let initialTab: AnalysisTab
    let navigationTitle: String
    let onBackToHome: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab: AnalysisTab

    init(initialTab: AnalysisTab, navigationTitle: String, onBackToHome: (() -> Void)? = nil) {
        self.initialTab = initialTab
        self.navigationTitle = navigationTitle
        self.onBackToHome = onBackToHome
        _selectedTab = State(initialValue: initialTab)
    }

    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea(.all)

            VStack(spacing: selectedTab == .weekly ? 32 : 24) {
                AnalysisSegmentedControl(selectedTab: $selectedTab)
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                    .background(Color.white)
                    .zIndex(1)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        if selectedTab == .weekly {
                            WeeklyAnalysisContent()
                        } else {
                            MonthlyAnalysisContent()
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 36)
                }
            }
        }
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    handleBackButtonTap()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(WeeklyAnalysisColor.gray900)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("뒤로가기")
            }
        }
    }

    private func handleBackButtonTap() {
        if let onBackToHome {
            onBackToHome()
        } else {
            dismiss()
        }
    }
}

private struct WeeklyAnalysisContent: View {
    private let insights = WeeklyAnalysisMockData.insights
    private let retrospectives = WeeklyAnalysisMockData.retrospectives

    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            WeeklyStatsSection()
            WeeklyInsightSection(insights: insights)
            WeeklyRetrospectiveSection(items: retrospectives)
        }
    }
}

private enum WeeklyAnalysisColor {
    static let gray900 = Color(red: 0.098, green: 0.122, blue: 0.157)
    static let gray600 = Color(red: 0.42, green: 0.463, blue: 0.518)
    static let gray300 = Color(red: 0.82, green: 0.839, blue: 0.859)
    static let gray200 = Color(red: 0.898, green: 0.91, blue: 0.922)
    static let gray100 = Color(red: 0.949, green: 0.957, blue: 0.965)
    static let gray50 = Color(red: 0.976, green: 0.98, blue: 0.984)
    static let blue500 = Color(red: 0.133, green: 0.447, blue: 0.922)
    static let blue50 = Color(red: 0.91, green: 0.953, blue: 1)
    static let blueTrack = Color(red: 0.863, green: 0.922, blue: 1)
    static let red500 = Color(red: 0.941, green: 0.267, blue: 0.22)
    static let red50 = Color(red: 1, green: 0.945, blue: 0.941)
    static let redTrack = Color(red: 1, green: 0.878, blue: 0.867)
}

private enum WeeklyAnalysisMockData {
    static let insights: [WeeklyInsightItem] = [
        WeeklyInsightItem(
            title: "반복 반성 포인트",
            count: "4회",
            description: "시간 관리 관련 회고가 많지만 아직 개선 흐름이 약해요. 우선순위 정리가 필요해 보여요.",
            detail: "회의 전 준비, 마감 직전 집중 저하"
        ),
        WeeklyInsightItem(
            title: "반복 강점 포인트",
            count: "4회",
            description: "팀 피드백을 빠르게 받아들이고 시도하는 점이 자주 보여요. 협업 적응력이 강점이에요.",
            detail: "회의 전 준비, 마감 직전 집중 저하"
        )
    ]

    static let retrospectives: [WeeklyRetrospectiveItem] = [
        WeeklyRetrospectiveItem(date: "5/19", title: "작게 회복한 하루"),
        WeeklyRetrospectiveItem(date: "5/20", title: "집중을 되찾은 시간"),
        WeeklyRetrospectiveItem(date: "5/21", title: "피드백을 반영한 날"),
        WeeklyRetrospectiveItem(date: "5/22", title: "조금 더 정리된 생각"),
        WeeklyRetrospectiveItem(date: "5/23", title: "팀과 맞춰 간 하루"),
        WeeklyRetrospectiveItem(date: "5/24", title: "마감 전 다시 점검"),
        WeeklyRetrospectiveItem(date: "5/25", title: "다음 주를 준비하며")
    ]
}

private struct WeeklyInsightItem: Identifiable {
    let id = UUID()
    let title: String
    let count: String
    let description: String
    let detail: String
}

private struct WeeklyRetrospectiveItem: Identifiable {
    let id = UUID()
    let date: String
    let title: String
}

struct AnalysisSegmentedControl: View {
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
                .foregroundStyle(.black)
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
    }
}

private struct WeeklyStatsSection: View {
    var body: some View {
        VStack(spacing: 16) {
            HStack(alignment: .center, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("이번 주 만족도")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(WeeklyAnalysisColor.gray600)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("긍정적인 흐름이 컸어요")
                            .font(.system(size: 20, weight: .heavy))
                            .foregroundStyle(WeeklyAnalysisColor.gray900)
                            .lineLimit(1)
                            .minimumScaleFactor(0.82)

                        Text("전반적으로 만족도가 높아요")
                            .font(.system(size: 14))
                            .foregroundStyle(WeeklyAnalysisColor.gray600)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                HStack(alignment: .lastTextBaseline, spacing: 0) {
                    Text("4.3")
                        .font(.system(size: 26, weight: .heavy))
                    Text("/5")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(WeeklyAnalysisColor.blue500)
                .frame(width: 88, height: 64)
                .background {
                    RoundedRectangle(cornerRadius: 32)
                        .fill(WeeklyAnalysisColor.blue50)
                }
            }
            .padding(16)
            .background {
                RoundedRectangle(cornerRadius: 18)
                    .fill(WeeklyAnalysisColor.gray50)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("이번 주 감정")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(WeeklyAnalysisColor.gray600)

                VStack(spacing: 8) {
                    SentimentRow(
                        label: "긍정 82%",
                        description: "좋았던 흐름",
                        progress: 0.82,
                        chipColor: WeeklyAnalysisColor.blue50,
                        valueColor: WeeklyAnalysisColor.blue500,
                        trackColor: WeeklyAnalysisColor.blueTrack
                    )

                    SentimentRow(
                        label: "부정 18%",
                        description: "부담 감정",
                        progress: 0.18,
                        chipColor: WeeklyAnalysisColor.red50,
                        valueColor: WeeklyAnalysisColor.red500,
                        trackColor: WeeklyAnalysisColor.redTrack
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(WeeklyAnalysisColor.gray300, lineWidth: 1)
            }
        }
    }
}

private struct SentimentRow: View {
    let label: String
    let description: String
    let progress: CGFloat
    let chipColor: Color
    let valueColor: Color
    let trackColor: Color

    var body: some View {
        HStack(spacing: 0) {
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(valueColor)
                .frame(width: 78, height: 24)
                .background {
                    Capsule()
                        .fill(chipColor)
                }

            Text(description)
                .font(.system(size: 12))
                .foregroundStyle(WeeklyAnalysisColor.gray600)
                .frame(width: 102)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(trackColor)
                        .frame(height: 5)

                    Capsule()
                        .fill(valueColor)
                        .frame(width: geometry.size.width * progress, height: 5)
                }
                .frame(maxHeight: .infinity)
            }
            .frame(height: 24)
        }
    }
}

private struct WeeklyInsightSection: View {
    let insights: [WeeklyInsightItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("회고 인사이트")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(WeeklyAnalysisColor.gray900)

            VStack(spacing: 0) {
                Divider()
                    .padding(.horizontal, 10)

                ForEach(insights) { insight in
                    WeeklyInsightCard(item: insight)

                    if insight.id != insights.last?.id {
                        Divider()
                            .padding(.horizontal, 10)
                    }
                }
            }
        }
    }
}

private struct WeeklyInsightCard: View {
    let item: WeeklyInsightItem

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(item.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(WeeklyAnalysisColor.gray900)

                Spacer()

                Text(item.count)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(WeeklyAnalysisColor.gray600)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 4)
                    .background {
                        Capsule()
                            .fill(WeeklyAnalysisColor.gray100)
                    }
            }

            Text(item.description)
                .font(.system(size: 13))
                .foregroundStyle(WeeklyAnalysisColor.gray600)
                .lineSpacing(3)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(item.detail)
                .font(.system(size: 12))
                .foregroundStyle(WeeklyAnalysisColor.gray600)
                .lineLimit(1)
                .minimumScaleFactor(0.88)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(Color.white)
    }
}

private struct WeeklyRetrospectiveSection: View {
    let items: [WeeklyRetrospectiveItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("지난 회고들")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(WeeklyAnalysisColor.gray900)

                Spacer()

                Text("지난 회고 보기 >")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(WeeklyAnalysisColor.gray300)
            }

            VStack(spacing: 0) {
                Divider()

                ForEach(items) { item in
                    WeeklyRetrospectiveRow(item: item)
                    Divider()
                }
            }
        }
    }
}

private struct WeeklyRetrospectiveRow: View {
    let item: WeeklyRetrospectiveItem

    var body: some View {
        HStack(spacing: 16) {
            Text(item.date)
                .font(.system(size: 12))
                .foregroundStyle(WeeklyAnalysisColor.blue500)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(width: 30, height: 30)
                .background {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(WeeklyAnalysisColor.blue50)
                }

            Text(item.title)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(WeeklyAnalysisColor.gray900)
                .lineLimit(1)
                .minimumScaleFactor(0.86)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(WeeklyAnalysisColor.gray900)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white)
    }
}

struct WeeklyAnalysisView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            WeeklyAnalysisView()
        }
    }
}
