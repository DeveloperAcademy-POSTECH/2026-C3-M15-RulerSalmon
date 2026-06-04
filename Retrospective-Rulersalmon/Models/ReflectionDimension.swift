//
//  ReflectionDimension.swift
//  Retrospective-Rulersalmon
//
//  Created by DevPaul on 5/27/26.
//

import Foundation

enum ReflectionDimension: String, Codable, CaseIterable, Identifiable {
    case liked
    case learned
    case lacked
    case longedFor

    var id: String { rawValue }

    var title: String {
        switch self {
        case .liked:
            return "Liked"
        case .learned:
            return "Learned"
        case .lacked:
            return "Lacked"
        case .longedFor:
            return "Longed For"
        }
    }

    var description: String {
        switch self {
        case .liked:
            return "좋았던 점"
        case .learned:
            return "배운 점"
        case .lacked:
            return "부족했던 점"
        case .longedFor:
            return "바라는 점"
        }
    }
}
