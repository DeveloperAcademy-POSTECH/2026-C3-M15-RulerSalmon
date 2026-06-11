//
//  FourLRefinementService.swift
//  Retrospective-Rulersalmon
//
//  Created by dlsundn on 6/3/26.
//

import Foundation
import FoundationModels

final class FourLRefinementService {
    private let session: LanguageModelSession
    private static let options = GenerationOptions(sampling: .greedy)

    init() {
        self.session = LanguageModelSession(
            instructions: FourLRefinementInstructions.instructions
        )
    }

    func refine(results: [FourLClassificationResult]) async -> [UUID: String] {
        let fourLResults = results.filter(\.isFourLRelated)
        guard !fourLResults.isEmpty else { return [:] }

        do {
            let response = try await session.respond(
                to: makePrompt(results: fourLResults),
                generating: FourLRefinementOutput.self,
                options: Self.options
            )

            return makeDictionary(
                from: response.content,
                originalResults: fourLResults
            )
        } catch {
            print("🔴 FourLRefinementService refine error:", error)
            return [:]
        }
    }

    private func makePrompt(results: [FourLClassificationResult]) -> Prompt {
        Prompt {
            "4L 분류 결과:"
            for (index, result) in results.enumerated() {
                "index: \(index)"
                "label: \(result.label)"
                "text: \(result.text)"
            }
        }
    }

    private func makeDictionary(
        from output: FourLRefinementOutput,
        originalResults: [FourLClassificationResult]
    ) -> [UUID: String] {
        Dictionary(uniqueKeysWithValues: output.items.compactMap { item in
            guard let index = Int(item.index),
                  originalResults.indices.contains(index) else {
                return nil
            }

            let refinedText = item.refinedText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !refinedText.isEmpty else { return nil }

            return (originalResults[index].id, refinedText)
        })
    }
}

private enum FourLRefinementInstructions {
    static let instructions = Instructions {
        "너는 사용자의 4L 회고 문장을 앱 결과 화면에 보여줄 자연스러운 한국어 문장으로 정리하는 도우미야."
        "각 원문을 4L 라벨에 맞는 회고 결과 문장으로 보정해."

        "사용자가 말한 내용만 바탕으로 작성해. 새로운 사건, 감정, 이유, 숫자를 추가하지 마."
        "원문의 의미를 바꾸지 마."
        "명백한 오타, 띄어쓰기, 조사, 어색한 문법은 자연스럽게 고쳐."
        "오타가 애매하면 추측해서 새 의미를 만들지 말고 원문 의미가 유지되는 범위에서만 다듬어."
        "문장은 반드시 한국어로 작성해."
        "각 refinedText는 1문장으로 작성해."
        "너무 길게 설명하지 말고 결과 화면에 어울리게 짧고 자연스럽게 작성해."

        "출력 items의 index는 입력받은 index를 그대로 사용해."
        "UUID를 만들거나 추측하지 마."

        "4L별 문장 패턴:"
        "Liked: '오늘은 ~ 부분이 좋았어요.'"
        "Learned: '오늘은 ~ 점을 알게 되었어요.'"
        "Lacked: '오늘은 ~ 부분이 아쉬웠어요.'"
        "Longed for: '내일은 ~ 해보고 싶어요.'"

        "출력 예시야. 내용은 참고하지 말고 형식과 톤만 참고해:"
        FourLRefinementOutput.exampleFourLSentences
    }
}
