//
//  SentenceChunk.swift
//  Retrospective-Rulersalmon
//
//  Created by dlsundn on 6/3/26.
//

import Foundation

struct SentenceChunk: Identifiable, Equatable {
    let id = UUID()
    let messageId: UUID
    let text: String
    let date: Date
}

struct SentenceChunkerService {
    func chunks(from messages: [ChatMessage]) -> [SentenceChunk] {
        messages
            .filter { $0.role == .user }
            .flatMap { message in
                splitIntoSentences(message.text).map { sentence in
                    SentenceChunk(
                        messageId: message.id,
                        text: sentence,
                        date: message.date
                    )
                }
            }
    }

    private func splitIntoSentences(_ text: String) -> [String] {
        let separators = CharacterSet(charactersIn: ".!?。！？\n")

        return text
            .components(separatedBy: separators)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}
