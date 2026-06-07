//
//  AnalysisHomeView.swift
//
//  Created by magic3ightball on 6/7/26.
//

import SwiftUI

struct AnalysisHomeView: View {
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea(.all)

            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 32) {
                    WeeklySummaryCard()
                    InsightListSection()
                    PastRetrospectiveSection()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, AnalysisHomeLayout.screenPadding)
                .padding(.top, 32)
                .padding(.bottom, 36)
            }
        }
        .navigationTitle("회고 분석")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private enum AnalysisHomeLayout {
    static let screenPadding: CGFloat = 16
    static let cardPadding: CGFloat = 16
    static let cardCornerRadius: CGFloat = 18
    static let rowHorizontalPadding: CGFloat = 16
    static let rowVerticalPadding: CGFloat = 12
}

private struct WeeklySummaryCard: View {
    var body: some View {
        VStack(spacing: AnalysisHomeLayout.cardPadding) {
            HStack(alignment: .center, spacing: AnalysisHomeLayout.cardPadding) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("이번 주 만족도")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.gray600)

                    Text("긍정적인 흐름이 컸어요")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(Color.gray900)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                HStack(alignment: .lastTextBaseline, spacing: 0) {
                    Text("4.3")
                        .font(.system(size: 26, weight: .heavy))
                    Text("/5")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(Color.blue600)
                .frame(width: 88, height: 64)
                .background {
                    RoundedRectangle(cornerRadius: 32)
                        .fill(Color.blue50)
                }
            }

            SentimentToneBar()
                .padding(.horizontal, 16)
                .padding(.vertical, 16)

            Divider()

            NavigationLink {
                WeeklyAnalysisView()
            } label: {
                HStack {
                    Text("기간별 회고 패턴 보기")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.gray600)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.gray600)
                }
                .frame(height: 35)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint("기간별 인사이트 화면으로 이동")
        }
        .padding(AnalysisHomeLayout.cardPadding)
        .background {
            RoundedRectangle(cornerRadius: AnalysisHomeLayout.cardCornerRadius)
                .fill(Color.gray50)
        }
    }
}

private struct SentimentToneBar: View {
    var body: some View {
        VStack(spacing: 8) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.gray200)

                    Capsule()
                        .fill(Color.blue600)
                        .frame(width: geometry.size.width * 0.82)
                }
            }
            .frame(height: 13)

            HStack {
                Text("긍정 82%")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.gray900)

                Spacer()

                Text("부정 18%")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.gray600)
            }
        }
    }
}

private struct InsightListSection: View {
    private let insights = [
        InsightItem(
            title: "반성 포인트",
            count: "4회",
            description: "시간 관리 관련 회고가 많지만 아직 개선 흐름이 약해요. 우선순위 정리가 필요해 보여요."
        ),
        InsightItem(
            title: "강점 포인트",
            count: "4회",
            description: "팀 피드백을 빠르게 받아들이고 시도하는 점이 자주 보여요. 협업 적응력이 강점이에요."
        )
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("인사이트")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Color.gray900)

            VStack(spacing: 0) {
                Divider()

                ForEach(insights) { insight in
                    InsightRow(item: insight)

                    if insight.id != insights.last?.id {
                        Divider()
                    }
                }

                Divider()
            }
        }
    }
}

private struct InsightItem: Identifiable {
    let id = UUID()
    let title: String
    let count: String
    let description: String
}

private struct InsightRow: View {
    let item: InsightItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(item.title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.gray900)

                Spacer()

                Text(item.count)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.gray600)
                    .padding(.horizontal, 18)
                    .frame(height: 25)
                    .background {
                        Capsule()
                            .fill(Color.gray50)
                    }
            }

            Text(item.description)
                .font(.system(size: 14))
                .foregroundStyle(Color.gray600)
                .lineSpacing(3)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 12)
        .background(Color.white)
    }
}

private struct PastRetrospectiveSection: View {
    private let items = [
        PastRetrospectiveItem(date: "5/19", title: "작게 회복한 하루"),
        PastRetrospectiveItem(date: "5/18", title: "작게 회복한 하루"),
        PastRetrospectiveItem(date: "5/17", title: "작게 회복한 하루"),
        PastRetrospectiveItem(date: "5/16", title: "작게 회복한 하루"),
        PastRetrospectiveItem(date: "5/15", title: "작게 회복한 하루"),
        PastRetrospectiveItem(date: "5/14", title: "작게 회복한 하루")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("지난 회고들")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color.gray900)

                Spacer()

                Text("지난 회고 보기 >")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.gray300)
            }

            VStack(spacing: 0) {
                Divider()
                    .background(Color.black)

                ForEach(items) { item in
                    PastRetrospectiveRow(item: item)
                }
            }
        }
    }
}

private struct PastRetrospectiveItem: Identifiable {
    let id = UUID()
    let date: String
    let title: String
}

private struct PastRetrospectiveRow: View {
    let item: PastRetrospectiveItem

    var body: some View {
        HStack(spacing: 16) {
            Text(item.date)
                .font(.system(size: 12))
                .foregroundStyle(Color.blue600)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
                .frame(width: 30, height: 30)
                .background {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.blue50)
                }

            Text(item.title)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(Color.gray900)
                .lineLimit(1)
                .minimumScaleFactor(0.86)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.gray900)
        }
        .padding(.horizontal, AnalysisHomeLayout.rowHorizontalPadding)
        .padding(.vertical, AnalysisHomeLayout.rowVerticalPadding)
        .background(Color.white)
    }
}

struct AnalysisHomeView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            AnalysisHomeView()
        }
    }
}
