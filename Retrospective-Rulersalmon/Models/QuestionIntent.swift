//
//  QuestionIntent.swift
//  Retrospective-Rulersalmon
//
//  Created by DevPaul on 6/4/26.
//

import Foundation

enum QuestionIntent: String, Codable, Equatable {
    case reason
    case example
    case blocker
    case feeling
    case lesson
    case nextStep
    case wrapUp

    var koreanDescription: String {
        switch self {
        case .reason:
            return "이유"
        case .example:
            return "구체적인 장면"
        case .blocker:
            return "막힌 지점"
        case .feeling:
            return "감정 배경"
        case .lesson:
            return "배운 점"
        case .nextStep:
            return "다음 시도"
        case .wrapUp:
            return "마무리"
        }
    }
}
