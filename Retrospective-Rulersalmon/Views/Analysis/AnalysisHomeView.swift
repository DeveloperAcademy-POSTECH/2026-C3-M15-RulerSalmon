import SwiftUI

struct AnalysisHomeView: View {
    var body: some View {
        ZStack {
            Color.gray50
                .ignoresSafeArea(.all)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    AnalysisHomeHeader()
                    AnalysisHomeCardList()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.top, 32)
                .padding(.bottom, 36)
            }
        }
        .navigationTitle("분석")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct AnalysisHomeHeader: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("나의 회고 분석")
                .font(.system(size: 28, weight: .heavy))
                .foregroundStyle(Color.gray900)

            Text("주간 흐름을 먼저 확인하거나, 월간 패턴으로 이어서 볼 수 있어요.")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color.gray600)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 4)
    }
}

private struct AnalysisHomeCardList: View {
    var body: some View {
        VStack(spacing: 14) {
            NavigationLink {
                WeeklyAnalysisView()
            } label: {
                AnalysisHomeCard(
                    title: "주간 인사이트",
                    description: "이번 주 만족도, 감정 흐름, 반복된 회고 포인트를 확인해요.",
                    systemImageName: "calendar.badge.clock",
                    tintColor: Color.blue500
                )
            }
            .buttonStyle(.plain)
            .accessibilityHint("주간 인사이트 화면으로 이동")

            NavigationLink {
                MonthlyAnalysisView()
            } label: {
                AnalysisHomeCard(
                    title: "월간 인사이트",
                    description: "한 달 동안 자주 등장한 감정과 키워드, 만족도 변화를 살펴봐요.",
                    systemImageName: "chart.line.uptrend.xyaxis",
                    tintColor: Color.blue600
                )
            }
            .buttonStyle(.plain)
            .accessibilityHint("월간 인사이트 화면으로 이동")
        }
    }
}

private struct AnalysisHomeCard: View {
    let title: String
    let description: String
    let systemImageName: String
    let tintColor: Color

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: systemImageName)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(tintColor)
                .frame(width: 54, height: 54)
                .background {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color.blue50)
                }
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color.gray900)

                Text(description)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.gray600)
                    .lineSpacing(3)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "chevron.right")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Color.gray300)
                .accessibilityHidden(true)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.white)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 22)
                .stroke(Color.gray200, lineWidth: 1)
        }
        .shadow(color: Color.blue600.opacity(0.08), radius: 20, x: 0, y: 8)
        .contentShape(RoundedRectangle(cornerRadius: 22))
    }
}

struct AnalysisHomeView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            AnalysisHomeView()
        }
    }
}
