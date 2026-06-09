//
//  MainPageView.swift
//  Retrospective-Rulersalmon
//
//  Created by 권오상 on 6/2/26.
//

import SwiftUI

struct MainPageView: View {
    @StateObject private var viewModel: MainPageViewModel
    @State private var selectedTab: MainPageTab = .home

    @MainActor
    init(viewModel: MainPageViewModel? = nil) {
        _viewModel = StateObject(wrappedValue: viewModel ?? MainPageViewModel())
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                MainHomeView(content: viewModel.content, chatView: viewModel.makeChatView())
            }
            .tag(MainPageTab.home)
            .tabItem {
                Label("홈", systemImage: "house.fill")
            }

            NavigationStack {
                AnalysisHomeView()
            }
            .tag(MainPageTab.analysis)
            .tabItem {
                Label("분석", systemImage: "chart.bar.fill")
            }
        }
        .tint(Color.blue500)
        .task {
            viewModel.reload()
        }
    }
}

private enum MainPageTab: Hashable {
    case home
    case analysis
}

private struct MainHomeView: View {
    let content: MainPageContent
    let chatView: ReflectionChatView

    var body: some View {
        ZStack {
            Color.gray50
                .ignoresSafeArea(.all)

            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 36) {
                    MainHeaderView(
                        userName: content.userName,
                        encouragementMessage: content.encouragementMessage
                    )
                    TodayMentorCard(content: content, chatView: chatView)
                    RetrospectiveListView(items: content.retrospectives)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, MainPageLayout.screenPadding)
                .padding(.top, 48)
                .padding(.bottom, 32)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}

private enum MainPageLayout {
    static let screenPadding: CGFloat = 16
    static let headerHorizontalPadding: CGFloat = 10
    static let cardPadding: CGFloat = 24
    static let listRowHorizontalPadding: CGFloat = 16
    static let listRowVerticalPadding: CGFloat = 12
    static let cardCornerRadius: CGFloat = 25
    static let borderWidth: CGFloat = 1
    static let primaryButtonHeight: CGFloat = 56
}

private struct MainHeaderView: View {
    let userName: String
    let encouragementMessage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("안녕하세요, \(userName) 님")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(Color.gray900)
                    .lineLimit(2)
                    .minimumScaleFactor(0.78)

                Image(systemName: "pencil")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Color.gray900)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(encouragementMessage)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color.gray600)
                .lineSpacing(4)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, MainPageLayout.headerHorizontalPadding)
    }
}

private struct TodayMentorCard: View {
    let content: MainPageContent
    let chatView: ReflectionChatView

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                MentorAvatarTile(imageName: content.mentorImageName)

                VStack(alignment: .leading, spacing: 8) {
                    Text(content.mentorBadgeTitle)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.blue500)
                        .padding(.horizontal, 13)
                        .padding(.vertical, 6)
                        .background {
                            Capsule()
                                .fill(Color.blue50)
                        }

                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(content.mentorName)
                            .font(.system(size: 30, weight: .bold))
                            .foregroundStyle(Color.blue500)
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)

                        Image(systemName: "pencil")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(Color.blue500)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .layoutPriority(1)
            }
            .frame(maxWidth: .infinity)

            Text(content.mentorGreeting)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color.gray600)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .frame(maxWidth: .infinity)

            MainPrimaryNavigationButton(
                title: "회고 시작",
                systemImageName: "phone.fill",
                destination: chatView
            )
        }
        .frame(maxWidth: .infinity)
        .padding(MainPageLayout.cardPadding)
        .background {
            RoundedRectangle(cornerRadius: MainPageLayout.cardCornerRadius)
                .fill(Color.white)
        }
        .overlay {
            RoundedRectangle(cornerRadius: MainPageLayout.cardCornerRadius)
                .stroke(Color.gray200, lineWidth: MainPageLayout.borderWidth)
        }
        .shadow(color: Color.blue600.opacity(0.12), radius: 30, x: 0, y: 12)
    }
}

private struct MentorAvatarTile: View {
    let imageName: String

    var body: some View {
        Image(imageName)
            .resizable()
            .scaledToFit()
            .frame(width: 96, height: 96)
            .frame(width: 120, height: 120)
            .background {
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white,
                                Color.blue50.opacity(0.9)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: Color.gray300.opacity(0.18), radius: 20, x: 0, y: 10)
            }
            .accessibilityHidden(true)
    }
}

private struct MainPrimaryNavigationButton<Destination: View>: View {
    let title: String
    let systemImageName: String
    let destination: Destination

    var body: some View {
        NavigationLink {
            destination
        } label: {
            HStack(spacing: 6) {
                Image(systemName: systemImageName)
                    .font(.system(size: 17, weight: .bold))

                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .foregroundStyle(Color.white)
            .frame(maxWidth: .infinity)
            .frame(height: MainPageLayout.primaryButtonHeight)
            .background {
                Capsule()
                    .fill(Color.blue600)
            }
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityHint("회고 작성 화면으로 이동")
    }
}

private struct RetrospectiveListView: View {
    let items: [RetrospectiveItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text("지난주 회고들")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(Color.gray900)

                Spacer()

                NavigationLink {
                    RetrospectiveArchiveView(items: items)
                } label: {
                    Text("지난 회고 보기 >")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.gray300)
                }
                .buttonStyle(.plain)
                .accessibilityHint("지난 회고 전체 목록으로 이동")
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, MainPageLayout.headerHorizontalPadding)

            LazyVStack(spacing: 0) {
                ForEach(items) { item in
                    RetrospectiveRow(item: item)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct RetrospectiveRow: View {
    let item: RetrospectiveItem

    var body: some View {
        NavigationLink {
            RetrospectiveDetailPlaceholderView(item: item)
        } label: {
            HStack(spacing: 18) {
                Text(item.date)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(Color.blue500)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .frame(width: 30, height: 30)
                    .background {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(Color.blue50)
                    }

                Text(item.title)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(Color.gray900)
                    .lineLimit(1)
                    .minimumScaleFactor(0.86)

                Spacer(minLength: 12)

                Image(systemName: "chevron.right")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color.gray900)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, MainPageLayout.listRowHorizontalPadding)
            .padding(.vertical, MainPageLayout.listRowVerticalPadding)
            .background(Color.white)
            .contentShape(Rectangle())
            .overlay(alignment: .bottom) {
            }
        }
        .buttonStyle(.plain)
        .accessibilityHint("회고 상세 화면으로 이동")
    }
}

private struct RetrospectiveArchiveView: View {
    let items: [RetrospectiveItem]

    var body: some View {
        ZStack {
            Color.gray50
                .ignoresSafeArea(.all)

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(items) { item in
                        RetrospectiveRow(item: item)
                    }
                }
                .padding(.horizontal, MainPageLayout.screenPadding)
                .padding(.top, 16)
            }
        }
        .navigationTitle("지난 회고")
    }
}

private struct RetrospectiveDetailPlaceholderView: View {
    let item: RetrospectiveItem

    var body: some View {
        ZStack {
            Color.gray50
                .ignoresSafeArea(.all)

            VStack(alignment: .leading, spacing: 12) {
                Text(item.date)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.blue500)

                Text(item.title)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(Color.gray900)

                Text("회고 상세 화면 연결을 확인하기 위한 테스트용 화면입니다.")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.gray600)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(MainPageLayout.screenPadding)
        }
        .navigationTitle("회고 상세")
    }
}

struct MainPageView_Previews: PreviewProvider {
    static var previews: some View {
        MainPageView()
    }
}
