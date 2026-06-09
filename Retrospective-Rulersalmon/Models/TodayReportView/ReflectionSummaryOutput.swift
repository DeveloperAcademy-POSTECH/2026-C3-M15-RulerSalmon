//
//  ReflectionSummaryOutput.swift
//  Retrospective-Rulersalmon
//
//  Created by dlsundn on 6/9/26.
//

import Foundation
import FoundationModels

@Generable
struct ReflectionRefinementOutput {
    @Guide(description: "사용자가 입력한 회고를 자연스럽게 정리한 3문장의 결과문입니다. 사용자가 말하지 않은 내용은 추가하지 않습니다.")
    var refinedReflection: String
}

@Generable
struct ReflectionTodaySummaryOutput {
    @Guide(description: "오늘 회고 전체를 자연스럽게 요약한 한 문장입니다. 사용자가 말하지 않은 내용은 추가하지 않습니다.")
    var todaySummary: String
}

@Generable
struct ReflectionCoreKeywordOutput {
    @Guide(description: "사건, 활동, 주제, 작업, 배운 내용을 나타내는 핵심키워드입니다. 감정 단어는 제외합니다. 최대 5개이며, 각 항목은 2어절 이하의 짧은 명사구입니다. 긴 영어 표현과 설명형 문장은 제외합니다.")
    var coreKeywords: [String]
}

@Generable
struct ReflectionEmotionKeywordOutput {
    @Guide(description: "감정, 기분, 마음 상태를 나타내는 감정키워드입니다. 사건이나 활동명은 제외합니다. 최대 5개입니다.")
    var emotionKeywords: [String]
}

@Generable
struct ReflectionActionItemOutput {
    @Guide(description: "Longed for와 Lacked 회고를 바탕으로 만든 내일 실천 행동입니다. 반드시 '~하기' 형식입니다. 최대 3개이며, 범용적인 표현이 아니라 회고에 나온 문제나 바람과 직접 연결된 짧은 행동입니다.")
    var actionItems: [String]
}


@Generable
struct FourLRefinementOutput {
    @Guide(description: "입력된 4L 분류 결과의 index와 정돈된 회고 문장을 함께 담은 배열입니다.")
    var items: [FourLRefinedItem]
}

@Generable
struct FourLRefinedItem {
    @Guide(description: "입력된 4L 분류 결과의 index입니다. UUID가 아니라 0부터 시작하는 숫자 문자열입니다.")
    var index: String

    @Guide(description: "4L 라벨에 맞게 정돈한 짧은 한국어 회고 문장입니다. 사용자가 말하지 않은 내용은 추가하지 않습니다.")
    var refinedText: String
}

extension ReflectionRefinementOutput {
    static let exampleFromChat = ReflectionRefinementOutput(
        refinedReflection: "아침 운동을 계획대로 마쳐서 몸이 한결 가벼웠어요. 오후에는 집중이 잘 되지 않아 아쉬웠지만, 쉬는 시간을 나누어 쓰면 더 나아질 수 있다는 점을 알게 되었어요."
    )
}

extension ReflectionTodaySummaryOutput {
    static let exampleThreeLineSummary = ReflectionTodaySummaryOutput(
        todaySummary: "준비한 일을 차근차근 해내며 뿌듯함을 느꼈고, 부족했던 시간 관리를 내일 조금 더 정리해보고 싶었던 하루였어요."
    )
}

extension ReflectionCoreKeywordOutput {
    static let exampleReflectionTopics = ReflectionCoreKeywordOutput(
        coreKeywords: ["운동 완료", "집중 부족", "쉬는 시간", "작업 계획", "할 일"]
    )
}

extension ReflectionEmotionKeywordOutput {
    static let exampleReflectionEmotions = ReflectionEmotionKeywordOutput(
        emotionKeywords: ["혼란", "답답", "걱정", "행복", "뿌듯"]
    )
}

extension ReflectionActionItemOutput {
    static let exampleActionItems = ReflectionActionItemOutput(
        actionItems: [
            "작업 순서 정하기",
            "마감 시간 적기",
            "할 일 3개 적기"
        ]
    )
}

extension FourLRefinementOutput {
    static let exampleFourLSentences = FourLRefinementOutput(
        items: [
            FourLRefinedItem(
                index: "0",
                refinedText: "오늘은 팀원들과 빠르게 의견을 맞춘 부분이 좋았어요."
            ),
            FourLRefinedItem(
                index: "1",
                refinedText: "오늘은 쉬는 시간을 나누어 쓰는 방법을 알게 되었어요."
            ),
            FourLRefinedItem(
                index: "2",
                refinedText: "오늘은 작업 시간이 부족했던 점이 아쉬웠어요."
            ),
            FourLRefinedItem(
                index: "3",
                refinedText: "내일은 할 일을 먼저 정리해보고 싶어요."
            )
        ]
    )
}
