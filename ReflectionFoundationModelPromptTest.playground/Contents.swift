
import Foundation
import FoundationModels
import Playgrounds

@Generable
struct ReflectionSummaryOutput {
    @Guide(description: "사용자가 입력한 회고를 자연스럽게 정리한 2~4문장의 결과문입니다.")
    var refinedReflection: String

    @Guide(description: "오늘 회고를 정확히 3줄로 요약한 문장 배열입니다.")
    @Guide(.count(3))
    var todaySummaryLines: [String]
}

@Generable
struct ReflectionKeywordOutput {
    @Guide(description: "사건, 활동, 주제, 작업, 배운 내용을 나타내는 핵심키워드입니다. 감정 단어는 제외합니다. 최대 5개입니다.")
    var coreKeywords: [String]

    @Guide(description: "감정, 기분, 마음 상태를 나타내는 감정키워드입니다. 사건이나 활동명은 제외합니다. 최대 5개입니다.")
    var emotionKeywords: [String]
}

@Generable
struct ReflectionActionItemOutput {
    @Guide(description: "Longed for와 Lacked 회고를 바탕으로 만든 내일 실천 행동입니다. 반드시 ~하기 형식입니다. 최대 3개입니다.")
    var actionItems: [String]
}

@Generable
struct ReflectionChunkingOutput {
    @Guide(description: "4L 분석에 적합하게 나눈 의미 단위 문장 배열입니다.")
    var chunks: [String]
}

struct ReflectionSample {
    let title: String
    let userOnlyText: String
    let longedForText: String
    let lackedText: String
}

let samples: [ReflectionSample] = [
    ReflectionSample(
        title: "긍정 회고",
        userOnlyText: """
        오늘 팀원들과 빠르게 의견을 맞추면서 기능 방향이 명확해져서 좋았어요.
        Foundation Model 프롬프트를 정리하면서 JSON 출력 구조를 더 잘 이해했어요.
        내일은 이 결과를 리포트 화면에 연결해보고 싶어요.
        """,
        longedForText: "내일은 이 결과를 리포트 화면에 연결해보고 싶어요.",
        lackedText: ""
    ),
    ReflectionSample(
        title: "부정 회고",
        userOnlyText: """
        Foundation 모델을 사용해서 요약을 하고 있는데 내 마음대로 되지 않아서 혼란스러워요.
        오늘까지 맡은 기능을 완성해야 하는데 시간이 너무 부족하다고 느꼈어요.
        내가 과연 다 할 수 있을까 걱정되고 자신감이 부족했어요.
        """,
        longedForText: "",
        lackedText: "Foundation 모델 요약이 마음대로 되지 않아 혼란스러웠어요. 시간이 부족하고 자신감이 부족했어요."
    ),
    ReflectionSample(
        title: "애매한 회고",
        userOnlyText: """
        오늘은 이것저것 만져봤는데 아직 정리가 잘 안 됐어요.
        결과가 나쁘지는 않은데 무엇을 배웠는지 명확하게 말하기는 어려웠어요.
        내일은 우선순위를 다시 정리해보고 싶어요.
        """,
        longedForText: "내일은 우선순위를 다시 정리해보고 싶어요.",
        lackedText: "아직 정리가 잘 안 됐고 무엇을 배웠는지 명확하게 말하기 어려웠어요."
    )
]

let options = GenerationOptions(sampling: .greedy)

let summaryInstructions = Instructions {
    "너는 한국어 회고 요약 전문가야."
    "사용자가 말한 내용만 근거로 회고 결과문과 오늘의 요약을 작성해."
    "새로운 사건, 감정, 계획은 만들지 마."
    "출력은 요청된 Generable 타입에 맞춰 안정적으로 채워."
}

let keywordInstructions = Instructions {
    "너는 회고문에서 핵심키워드와 감정키워드를 분리하는 분석기야."
    "핵심키워드는 사건, 활동, 주제, 작업, 배운 내용만 포함해."
    "감정키워드는 감정, 기분, 마음 상태만 포함해."
    "핵심키워드와 감정키워드를 절대 섞지 마."
}

let actionItemInstructions = Instructions {
    "너는 Longed for와 Lacked 회고를 바탕으로 내일 실천 가능한 Action Item을 제안하는 코치야."
    "Action Item은 반드시 사용자의 회고에 근거해야 해."
    "짧고 구체적인 ~하기 형식으로 제안해."
}

let chunkingInstructions = Instructions {
    "너는 채팅형 회고 문장을 4L 분석에 적합한 의미 단위 chunk로 나누는 분석기야."
    "사용자가 말하지 않은 내용을 만들지 말고, 원문의 의미를 보존해."
}

func makeSummaryPrompt(for sample: ReflectionSample) -> Prompt {
    Prompt {
        "작업:"
        "- 전체 사용자 회고를 자연스러운 회고 결과문으로 정리해."
        "- 전체 사용자 회고를 정확히 3줄로 요약해."
        "출력 규칙:"
        "- 사용자가 말한 내용만 근거로 작성해."
        "- 새로운 사건, 감정, 계획을 만들지 마."
        "- refinedReflection은 2~4문장으로 작성해."
        "- todaySummaryLines는 정확히 3개 문장으로 작성해."
        "전체 사용자 회고:"
        sample.userOnlyText
    }
}

func makeKeywordPrompt(for sample: ReflectionSample) -> Prompt {
    Prompt {
        "작업:"
        "- 전체 사용자 회고에서 핵심키워드와 감정키워드를 분리해서 추출해."
        "핵심키워드 규칙:"
        "- 사건, 활동, 주제, 작업, 배운 내용을 나타내는 단어만 출력해."
        "- 감정 단어는 coreKeywords에 넣지 마."
        "- 각 키워드는 2어절 이하."
        "- 최대 5개."
        "감정키워드 규칙:"
        "- 감정, 기분, 마음 상태만 출력해."
        "- 사건, 활동, 기술명, 프로젝트명은 emotionKeywords에 넣지 마."
        "- 혼란스러워는 혼란스러움처럼 감정 명사로 바꿔."
        "- 걱정돼는 걱정 또는 불안함으로 바꿔."
        "- 각 키워드는 2어절 이하."
        "- 최대 5개."
        "전체 사용자 회고:"
        sample.userOnlyText
    }
}

func makeActionItemPrompt(for sample: ReflectionSample) -> Prompt {
    Prompt {
        "작업:"
        "- Longed for 회고와 Lacked 회고를 바탕으로 내일 실천 가능한 Action Item을 제안해."
        "출력 규칙:"
        "- 반드시 Longed for 또는 Lacked 문장에 근거해."
        "- 사용자가 말하지 않은 프로젝트나 상황을 만들지 마."
        "- 반드시 ~하기 형식으로 작성해."
        "- 짧고 구체적인 행동이어야 해."
        "- 최대 3개."
        "- 입력이 모두 없으면 빈 배열을 출력해."
        "좋은 예시:"
        "- 내일 할 일 3가지 정리하기"
        "- 작업 시간을 나누어 계획하기"
        "- 결과 화면 연결하기"
        "- 부족했던 개념 다시 확인하기"
        "Longed for 문장:"
        sample.longedForText.isEmpty ? "없음" : sample.longedForText
        "Lacked 문장:"
        sample.lackedText.isEmpty ? "없음" : sample.lackedText
    }
}

func makeChunkingPrompt(for sample: ReflectionSample) -> Prompt {
    Prompt {
        "작업:"
        "- 사용자의 채팅형 회고 입력을 4L 분석에 적합한 의미 단위 문장으로 나눠."
        "규칙:"
        "- 사용자가 말한 표현만 사용해."
        "- 새로운 사건, 감정, 이유를 만들지 마."
        "- 너무 짧은 감탄사나 의미 없는 말은 제외해."
        "- 각 chunk는 독립적으로 4L 분류 모델에 넣을 수 있어야 해."
        "사용자 입력:"
        sample.userOnlyText
    }
}

func printPromptPreview(for sample: ReflectionSample) {
    print("\n==============================")
    print("🧪 Sample:", sample.title)
    print("==============================")
    print("원문:\n\(sample.userOnlyText)")
    print("Longed for:\n\(sample.longedForText.isEmpty ? "없음" : sample.longedForText)")
    print("Lacked:\n\(sample.lackedText.isEmpty ? "없음" : sample.lackedText)")
}

#Playground {
    let model = SystemLanguageModel.default

    switch model.availability {
    case .available:
        print("✅ Foundation Models is available")
    case .unavailable(let reason):
        print("❌ Foundation Models unavailable:", reason)
        return
    }

    let summarySession = LanguageModelSession(instructions: summaryInstructions)
    let keywordSession = LanguageModelSession(instructions: keywordInstructions)
    let actionItemSession = LanguageModelSession(instructions: actionItemInstructions)
    let chunkingSession = LanguageModelSession(instructions: chunkingInstructions)

    summarySession.prewarm()
    keywordSession.prewarm()
    actionItemSession.prewarm()
    chunkingSession.prewarm()

    for sample in samples {
        printPromptPreview(for: sample)

        do {
            let summary = try await summarySession.respond(
                to: makeSummaryPrompt(for: sample),
                generating: ReflectionSummaryOutput.self,
                options: options
            ).content

            let keywords = try await keywordSession.respond(
                to: makeKeywordPrompt(for: sample),
                generating: ReflectionKeywordOutput.self,
                options: options
            ).content

            let actionItems = try await actionItemSession.respond(
                to: makeActionItemPrompt(for: sample),
                generating: ReflectionActionItemOutput.self,
                options: options
            ).content

            let chunks = try await chunkingSession.respond(
                to: makeChunkingPrompt(for: sample),
                generating: ReflectionChunkingOutput.self,
                options: options
            ).content

            print("\n📌 refinedReflection:\n\(summary.refinedReflection)")
            print("\n📌 todaySummaryLines:")
            summary.todaySummaryLines.forEach { print("-", $0) }
            print("\n📌 coreKeywords:", keywords.coreKeywords)
            print("📌 emotionKeywords:", keywords.emotionKeywords)
            print("📌 actionItems:", actionItems.actionItems)
            print("📌 chunks:", chunks.chunks)
        } catch {
            print("❌ generation failed:", error)
        }
    }
}
