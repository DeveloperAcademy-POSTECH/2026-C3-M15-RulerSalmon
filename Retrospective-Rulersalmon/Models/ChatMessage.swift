//
//  ChatMessage.swift
//  Retrospective-Rulersalmon
//
//  Created by DevPaul on 5/21/26.
//

import Foundation

enum ChatRole: String, Codable {
    case user
    case assistant
}

struct ChatMessage: Identifiable, Equatable, Codable {
    let id: UUID
    let role: ChatRole
    let text: String
    let date: Date

    init(
        id: UUID = UUID(),
        role: ChatRole,
        text: String,
        date: Date = .now
    ) {
        self.id = id
        self.role = role
        self.text = text
        self.date = date
    }
}
