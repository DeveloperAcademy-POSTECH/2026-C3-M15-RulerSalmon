//
//  ChunkType.swift
//  Retrospective-Rulersalmon
//
//  Created by DevPaul on 5/27/26.
//

import Foundation

enum ChunkType: String, Codable, CaseIterable, Identifiable {
    case event
    case emotion
    case insight
    case problem
    case desire
    case filler
    case unknown

    var id: String { rawValue }
}
