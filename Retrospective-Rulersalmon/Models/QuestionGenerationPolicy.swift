//
//  QuestionGenerationPolicy.swift
//  Retrospective-Rulersalmon
//
//  Created by DevPaul on 6/4/26.
//

import Foundation

struct QuestionGenerationPolicy: Equatable {
    let targetDimension: ReflectionDimension?
    let intent: QuestionIntent
    let focusText: String?
    let reasoning: String
    let shouldClose: Bool
}
