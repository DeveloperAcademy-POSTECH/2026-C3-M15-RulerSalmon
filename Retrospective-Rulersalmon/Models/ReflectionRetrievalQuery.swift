//
//  ReflectionRetrievalQuery.swift
//  Retrospective-Rulersalmon
//
//  Created by DevPaul on 6/4/26.
//

import Foundation

struct ReflectionRetrievalQuery: Equatable {
    let rawText: String
    let targetDimension: ReflectionDimension?
    let keywords: [String]
    let preferredPhrases: [String]
}
