//
//  ReflectionSlot.swift
//  Retrospective-Rulersalmon
//
//  Created by DevPaul on 5/27/26.
//

import Foundation

struct ReflectionSlot: Codable, Equatable {
    var evidence: [String] = []
    var summary: String?
    var confidence: Double = 0
    var isSatisfied: Bool = false
}
