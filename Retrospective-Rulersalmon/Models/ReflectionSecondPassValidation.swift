//
//  ReflectionSecondPassValidation.swift
//  Retrospective-Rulersalmon
//
//  Created by DevPaul on 6/6/26.
//

import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

struct ReflectionSecondPassValidation: Codable, Equatable {
    let summary: String
    let verifiedDimensions: [ReflectionDimension]
    let primaryDimension: ReflectionDimension?
    let evidence: [String]
    let keywords: [String]
    let topic: String?
    let confidence: Double
    let reasoning: String
}

struct ReflectionRAGPipelineOutput: Equatable {
    let question: String
    let validation: ReflectionSecondPassValidation
    let firstPassResults: [FourLClassificationResult]
}

struct ReflectionGeneratedTurn: Equatable {
    let validation: ReflectionSecondPassValidation
    let question: String
}

#if canImport(FoundationModels)
@available(iOS 26.0, *)
@Generable(description: "회고 발화 검증 결과와 다음 질문")
struct ReflectionGeneratedTurnPayload {
    @Guide(description: "현재 사용자 발화를 한 문장으로 짧게 요약")
    var summary: String

    @Guide(description: "현재 발화에 해당하는 회고 차원 목록. liked, learned, lacked, longedFor 중에서만 선택")
    var verifiedDimensions: [String]

    @Guide(description: "가장 대표적인 회고 차원 하나. liked, learned, lacked, longedFor 중 하나거나 없으면 null")
    var primaryDimension: String?

    @Guide(description: "현재 발화를 그렇게 본 핵심 근거 표현 1개에서 3개")
    var evidence: [String]

    @Guide(description: "현재 발화의 핵심 키워드 1개에서 4개")
    var keywords: [String]

    @Guide(description: "현재 발화의 주제를 짧게 표현한 단어 또는 구")
    var topic: String?

    @Guide(description: "검토 신뢰도. 0.0 이상 1.0 이하")
    var confidence: Double

    @Guide(description: "왜 그렇게 검토했는지 짧은 설명")
    var reasoning: String

    @Guide(description: "사용자에게 바로 보여줄 다음 질문. 반드시 한국어 반말 한 문장 질문형으로 작성")
    var question: String
}
#endif
