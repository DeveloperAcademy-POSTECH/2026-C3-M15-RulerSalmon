//
//  ReflectionQueryBuilder.swift
//  Retrospective-Rulersalmon
//
//  Created by DevPaul on 6/4/26.
//

import Foundation

struct ReflectionQueryBuilder {
    func makeAnalysisQuery(
        currentText: String,
        firstPassResults: [FourLClassificationResult]
    ) -> ReflectionRetrievalQuery {
        let keywords = firstPassResults.flatMap { result in
            [result.label, result.secondaryLabel].compactMap { $0 }
        }

        return ReflectionRetrievalQuery(
            purpose: .analysis,
            rawText: ([currentText] + firstPassResults.map(\.text)).joined(separator: " "),
            targetDimension: nil,
            keywords: keywords,
            preferredPhrases: [currentText] + firstPassResults.map(\.text)
        )
    }

    func makeQuestionQuery(
        currentText: String,
        validation: ReflectionSecondPassValidation
    ) -> ReflectionRetrievalQuery {
        let rawTextParts: [String?] = [
            currentText,
            validation.summary,
            validation.topic,
            validation.evidence.first
        ]
        let rawText = rawTextParts.compactMap { $0 }.joined(separator: " ")

        let keywords = Array(Set(validation.keywords + validation.verifiedDimensions.map(\.rawValue)))
        let preferredPhraseCandidates: [String?] = [
            currentText,
            validation.summary,
            validation.evidence.first
        ]
        let preferredPhrases = preferredPhraseCandidates.compactMap { $0 }

        return ReflectionRetrievalQuery(
            purpose: .question,
            rawText: rawText,
            targetDimension: validation.primaryDimension,
            keywords: keywords,
            preferredPhrases: preferredPhrases
        )
    }
}
