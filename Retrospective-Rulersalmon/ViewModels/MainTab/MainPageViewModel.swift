//
//  MainPageViewModel.swift
//  Retrospective-Rulersalmon
//
//  Created by DevPaul on 6/4/26.
//

import Combine
import Foundation
import SwiftUI

enum MainPageTab: Hashable {
    case home
    case analysis
}

enum HomeNavigationRoute: Hashable {
    case reflectionChat
    case editUserInfo
    case editMentor
}

@MainActor
final class MainPageViewModel: ObservableObject {
    @Published private(set) var content: MainPageContent
    @Published var selectedTab: MainPageTab = .home
    @Published var homePath = NavigationPath()
    private let dataStore: AppDataStore

    init(content: MainPageContent? = nil, dataStore: AppDataStore? = nil) {
        self.dataStore = dataStore ?? .shared
        self.content = content ?? self.dataStore.makeMainPageContent()
        reload()
    }

    func reload() {
        content = dataStore.makeMainPageContent()
    }

    private var selectedMentor: Mentor {
        Mentor.sampleMentors.first(where: { $0.name == content.mentorName }) ?? Mentor.sampleMentors.first!
    }

    func makeChatView(onExitToMain: (() -> Void)? = nil) -> ReflectionChatView {
        let pipeline = ReflectionRAGPipeline(
            sessionID: UUID(),
            mentor: selectedMentor
        )
        return ReflectionChatView(
            viewModel: ReflectionChatViewModel(ragPipeline: pipeline),
            onExitToMain: onExitToMain
        )
    }

    func startReflection() {
        homePath.append(HomeNavigationRoute.reflectionChat)
    }

    func startUserInfoEdit() {
        homePath.append(HomeNavigationRoute.editUserInfo)
    }

    func startMentorEdit() {
        homePath.append(HomeNavigationRoute.editMentor)
    }

    func onExitToHome() {
        homePath = NavigationPath()
        selectedTab = .home
        reload()
    }
}
