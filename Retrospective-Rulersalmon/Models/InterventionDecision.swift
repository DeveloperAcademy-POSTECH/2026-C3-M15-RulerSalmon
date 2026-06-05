//
//  InterventionDecision.swift
//  Retrospective-Rulersalmon
//
//  Created by DevPaul on 5/27/26.
//

import Foundation

struct InterventionDecision: Codable, Equatable {
    let shouldIntervene: Bool
    let targetDimension: ReflectionDimension?
    let reason: String
    let urgency: Double
}
