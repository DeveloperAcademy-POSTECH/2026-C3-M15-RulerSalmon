//
//  ReflectionState.swift
//  Retrospective-Rulersalmon
//
//  Created by DevPaul on 5/27/26.
//

import Foundation

struct ReflectionState: Codable, Equatable {
    var liked: ReflectionSlot = .init()
    var learned: ReflectionSlot = .init()
    var lacked: ReflectionSlot = .init()
    var longedFor: ReflectionSlot = .init()

    var lastUserChunk: String?
    var askedDimensions: [ReflectionDimension] = []
    var askedQuestions: [String] = []
    var currentTopic: String?
    var lastUpdatedAt: Date?

    static let empty = ReflectionState()
}
