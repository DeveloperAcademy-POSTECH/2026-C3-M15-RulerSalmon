//
//  MainPageViewModel.swift
//  Retrospective-Rulersalmon
//
//  Created by DevPaul on 6/4/26.
//

import Foundation
import Combine

final class MainPageViewModel: ObservableObject {
    @Published private(set) var content: MainPageContent

    init(content: MainPageContent = .mock) {
        self.content = content
    }
}
