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

    var title: String {
        switch self {
        case .event:
            return "이벤트"
        case .emotion:
            return "감정"
        case .insight:
            return "배움"
        case .problem:
            return "문제"
        case .desire:
            return "바람"
        case .filler:
            return "군더더기"
        case .unknown:
            return "기타"
        }
    }
}
