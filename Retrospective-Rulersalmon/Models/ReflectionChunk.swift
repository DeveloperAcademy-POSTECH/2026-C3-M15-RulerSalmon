//
//  ReflectionChunk.swift
//  Retrospective-Rulersalmon
//
//  Created by DevPaul on 6/2/26.
//

import Foundation

struct ReflectionChunk: Codable, Identifiable, Equatable {
    let id: UUID
    let rawText: String
    let cleanedText: String
    let startedAt: Date
    let endedAt: Date
    let type: ChunkType

    init(
        id: UUID = UUID(),
        rawText: String,
        cleanedText: String,
        startedAt: Date,
        endedAt: Date,
        type: ChunkType
    ) {
        self.id = id
        self.rawText = rawText
        self.cleanedText = cleanedText
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.type = type
    }
}
