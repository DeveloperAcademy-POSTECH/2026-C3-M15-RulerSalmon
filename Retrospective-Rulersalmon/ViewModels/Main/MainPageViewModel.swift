//
//  MainPageViewModel.swift
//  Retrospective-Rulersalmon
//
//  Created by DevPaul on 6/4/26.
//

import Foundation
import Combine

@MainActor
final class MainPageViewModel: ObservableObject {
    @Published private(set) var content: MainPageContent
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

    func makeChatView() -> ReflectionChatView {
        let pipeline = ReflectionRAGPipeline(
            sessionID: UUID(),
            mentor: selectedMentor
        )
        return ReflectionChatView(viewModel: ReflectionChatViewModel(ragPipeline: pipeline))
    }
}
