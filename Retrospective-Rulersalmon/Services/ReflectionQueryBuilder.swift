//
//  ReflectionQueryBuilder.swift
//  Retrospective-Rulersalmon
//
//  Created by DevPaul on 6/4/26.
//

import Foundation

struct ReflectionQueryBuilder {
    func makeAnalysisQuery(currentText: String) -> ReflectionRetrievalQuery {
        ReflectionRetrievalQuery(
            purpose: .analysis,
            rawText: currentText,
            targetDimension: nil,
            keywords: [],
            preferredPhrases: [currentText]
        )
    }

    func makeQuestionQuery(
        state: ReflectionState,
        analysis: ChunkAnalysis?,
        turnFourLAnalysis: TurnFourLAnalysis,
        policy: QuestionGenerationPolicy
    ) -> ReflectionRetrievalQuery {
        let rawText = [
            analysis?.cleanedText,
            analysis?.summary,
            state.lastUserChunk,
            policy.focusText,
            turnFourLAnalysis.strongestDimension?.description,
            turnFourLAnalysis.weakestDimension?.description
        ]
        .compactMap { $0 }
        .joined(separator: " ")

        let focusKeywords = policy.focusText.map { [$0] } ?? []
        let keywords = Array(Set((analysis?.keywords ?? []) + focusKeywords))
        let preferredPhrases = [
            policy.focusText,
            analysis?.summary,
            state.currentTopic,
            state.lastUserChunk
        ]
        .compactMap { $0 }

        return ReflectionRetrievalQuery(
            purpose: .question,
            rawText: rawText,
            targetDimension: policy.targetDimension,
            keywords: keywords,
            preferredPhrases: preferredPhrases
        )
    }
}
