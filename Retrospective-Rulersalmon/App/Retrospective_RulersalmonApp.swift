//
//  Retrospective_RulersalmonApp.swift
//  Retrospective-Rulersalmon
//
//  Created by DevPaul on 5/21/26.
//

import SwiftUI
import SwiftData

@main
struct Retrospective_RulersalmonApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                OnboardingFlowView()
                    .modelContainer(AppDataStore.shared.container)
            }
            .environment(\.font, .system(.body, design: .default))
        }
    }
}
