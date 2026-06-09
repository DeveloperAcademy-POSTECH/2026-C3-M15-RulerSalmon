//
//  ReflectionFoundationModel.swift
//  Retrospective-Rulersalmon
//
//  Created by dlsundn on 6/9/26.
//

import Foundation
import FoundationModels

final class ReflectionFoundationModelService {
    private let refinementSession: LanguageModelSession
    private let summarySession: LanguageModelSession
    private let coreKeywordSession: LanguageModelSession
    private let emotionKeywordSession: LanguageModelSession
    private let actionItemSession: LanguageModelSession

    private static let options = GenerationOptions(sampling: .greedy)

    init() {
        self.refinementSession = LanguageModelSession(
            instructions: ReflectionFoundationInstructions.refinement
        )
        self.summarySession = LanguageModelSession(
            instructions: ReflectionFoundationInstructions.summary
        )
        self.coreKeywordSession = LanguageModelSession(
            instructions: ReflectionFoundationInstructions.coreKeyword
        )
        self.emotionKeywordSession = LanguageModelSession(
            instructions: ReflectionFoundationInstructions.emotionKeyword
        )
        self.actionItemSession = LanguageModelSession(
            instructions: ReflectionFoundationInstructions.actionItem
        )
    }

    func generateRefinedReflection(userOnlyText: String) async throws -> ReflectionRefinementOutput {
        let prompt = Prompt {
            "아래 회고를 사용자가 읽기 좋은 회고 결과문으로 정리해줘."
            "Here is an example of the desired output style, but don't copy its content or topic:"
            ReflectionRefinementOutput.exampleFromChat

            "사용자 회고:"
            userOnlyText
        }

        let response = try await refinementSession.respond(
            to: prompt,
            generating: ReflectionRefinementOutput.self,
            options: Self.options
        )

        return response.content
    }

    func generateTodaySummary(userOnlyText: String) async throws -> ReflectionTodaySummaryOutput {
        let prompt = Prompt {
            "아래 회고를 오늘의 요약 3문장으로 정리해줘."
            "Here is an example of the desired output format, but don't copy its content or topic:"
            ReflectionTodaySummaryOutput.exampleThreeLineSummary

            "사용자 회고:"
            userOnlyText
        }

        let response = try await summarySession.respond(
            to: prompt,
            generating: ReflectionTodaySummaryOutput.self,
            options: Self.options
        )

        return response.content
    }

    func generateCoreKeywords(userOnlyText: String) async throws -> ReflectionCoreKeywordOutput {
        let prompt = Prompt {
            "아래 회고에서 핵심키워드만 추출해줘."
            "Here is an example of the desired output format, but don't copy its content or topic:"
            ReflectionCoreKeywordOutput.exampleReflectionTopics

            "사용자 회고:"
            userOnlyText
        }

        let response = try await coreKeywordSession.respond(
            to: prompt,
            generating: ReflectionCoreKeywordOutput.self,
            options: Self.options
        )

        return response.content
    }

    func generateEmotionKeywords(userOnlyText: String) async throws -> ReflectionEmotionKeywordOutput {
        let prompt = Prompt {
            "아래 회고에서 감정키워드만 추출해줘."
            "Here is an example of the desired output format, but don't copy its content or topic:"
            ReflectionEmotionKeywordOutput.exampleReflectionEmotions

            "사용자 회고:"
            userOnlyText
        }

        let response = try await emotionKeywordSession.respond(
            to: prompt,
            generating: ReflectionEmotionKeywordOutput.self,
            options: Self.options
        )

        return response.content
    }

    func generateActionItems(
        longedForText: String,
        lackedText: String
    ) async throws -> ReflectionActionItemOutput {
        let prompt = Prompt {
            "Longed for 회고와 Lacked 회고를 바탕으로 내일 실천 가능한 Action Item을 제안해줘."
            "Here is an example of the desired output format, but don't copy its content or topic:"
            ReflectionActionItemOutput.exampleActionItems

            "Longed for 문장:"
            longedForText.isEmpty ? "없음" : longedForText

            "Lacked 문장:"
            lackedText.isEmpty ? "없음" : lackedText
        }

        let response = try await actionItemSession.respond(
            to: prompt,
            generating: ReflectionActionItemOutput.self,
            options: Self.options
        )

        return response.content
    }

    func prewarm() {
        refinementSession.prewarm()
        summarySession.prewarm()
        coreKeywordSession.prewarm()
        emotionKeywordSession.prewarm()
        actionItemSession.prewarm()
    }

    private enum ReflectionFoundationInstructions {
        static let refinement = Instructions {
            "너는 한국어 회고 문장 보정 도우미야."
            "사용자의 채팅형 회고를 자연스럽고 따뜻한 2~4문장 결과문으로 정리해."
            "사용자가 말하지 않은 사건, 감정, 계획은 추가하지 마."
            "과장하지 말고 원문의 의미를 보존해."
        }

        static let summary = Instructions {
            "너는 한국어 회고 요약 전문가야."
            "사용자의 전체 회고를 정확히 3개의 짧은 요약 문장으로 정리해."
            "각 요약 문장은 서로 다른 핵심 내용을 담아야 해."
            "예시에 있는 단어와 주제를 복사하지 마."
            "새로운 사건, 감정, 계획은 만들지 마."
        }

        static let coreKeyword = Instructions {
            "너는 회고문에서 핵심키워드만 추출하는 분석기야."
            "핵심키워드는 사건, 활동, 주제, 작업, 배운 내용을 나타내는 단어 또는 짧은 명사구야."
            "감정, 기분, 마음 상태를 나타내는 단어는 절대 포함하지 마."
            "각 키워드는 2어절 이하로 작성하고 최대 5개까지만 추출해."
            "같은 의미의 키워드는 한 번만 출력해."
            "예시에 있는 단어와 주제를 복사하지 마."
        }

        static let emotionKeyword = Instructions {
            "너는 회고문에서 감정키워드만 추출하는 분석기야."
            "감정키워드는 감정, 기분, 마음 상태를 나타내는 단어야."
            "사건, 활동, 사람, 장소, 기술명, 프로젝트명, 작업명은 포함하지 마."
            "각 키워드는 2어절 이하로 작성하고 최대 5개까지만 추출해."
            "같은 의미의 감정은 한 번만 출력해."
            "예시에 있는 단어와 주제를 복사하지 마."
            "감정 표현은 가능하면 명사형으로 정리해. 예를 들어 '혼란스러워요'는 '혼란'으로 정리해."
        }

        static let actionItem = Instructions {
            "너는 Longed for와 Lacked 회고를 바탕으로 내일 실천 가능한 Action Item을 제안하는 코치야."
            "Action Item은 반드시 사용자의 Longed for 또는 Lacked 회고에 근거해야 해."
            "사용자가 말하지 않은 프로젝트나 상황을 새로 만들지 마."
            "짧고 구체적인 '~하기' 형식으로 작성하고 최대 3개까지만 제안해."
            "각 Action Item은 16자 이내의 짧은 행동으로 작성해."
            "긴 설명, 이유, 목적어가 많은 문장은 쓰지 마."
            "같은 의미의 Action Item은 한 번만 출력해."
            "예시에 있는 단어와 주제를 복사하지 마."
            "Longed for와 Lacked가 모두 없으면 빈 배열을 반환해."
        }

    }
}
