//
//  MainPageView.swift
//  Retrospective-Rulersalmon
//
//  Created by 권오상 on 6/2/26.
//

import SwiftUI

struct MainPageView: View {
    @StateObject private var viewModel: MainPageViewModel

    @MainActor
    init(viewModel: MainPageViewModel? = nil) {
        _viewModel = StateObject(wrappedValue: viewModel ?? MainPageViewModel())
    }

    var body: some View {
        TabView(selection: $viewModel.selectedTab) {
            NavigationStack(path: $viewModel.homePath) {
                MainHomeView(
                    content: viewModel.content,
                    onStartReflection: viewModel.startReflection,
                    onEditUserInfo: viewModel.startUserInfoEdit,
                    onEditMentor: viewModel.startMentorEdit
                )
                .navigationDestination(for: HomeNavigationRoute.self) { route in
                    switch route {
                    case .reflectionChat:
                        viewModel.makeChatView(onExitToMain: viewModel.onExitToHome)
                    case .editUserInfo:
                        UserInfoEditView(onSaved: viewModel.onExitToHome)
                    case .editMentor:
                        MentorEditView(onSaved: viewModel.onExitToHome)
                    }
                }
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

struct MainPageView_Previews: PreviewProvider {
    static var previews: some View {
        MainPageView()
    }
}
