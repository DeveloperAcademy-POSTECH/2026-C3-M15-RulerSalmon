//
//  ReflectionQueryBuilder.swift
//  Retrospective-Rulersalmon
//
//  Created by DevPaul on 6/4/26.
//

import Foundation

struct ReflectionQueryBuilder {
    func makeContextQuery(
        currentText: String,
        firstPassResults: [FourLClassificationResult]
    ) -> ReflectionRetrievalQuery {
        let keywords = firstPassResults.flatMap { result in
            [result.label, result.secondaryLabel].compactMap { $0 }
        }

        return ReflectionRetrievalQuery(
            rawText: ([currentText] + firstPassResults.map(\.text)).joined(separator: " "),
            targetDimension: nil,
            keywords: keywords,
            preferredPhrases: [currentText] + firstPassResults.map(\.text)
        )
    }
}
