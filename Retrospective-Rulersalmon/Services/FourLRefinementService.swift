//
//  FourLRefinementService.swift
//  Retrospective-Rulersalmon
//
//  Created by dlsundn on 6/3/26.
//

import Foundation

final class FourLRefinementService {
    private let foundationModelService: FoundationModelServicing

    init(foundationModelService: FoundationModelServicing = FoundationModelService()) {
        self.foundationModelService = foundationModelService
    }

    func refine(results: [FourLClassificationResult]) async -> [UUID: String] {
        let fourLResults = results.filter(\.isFourLRelated)
        guard !fourLResults.isEmpty else { return [:] }

        do {
            let response = try await foundationModelService.respond(to: makePrompt(results: fourLResults))
            return parseRefinedTexts(from: response)
        } catch {
            return [:]
        }
    }

    private func makePrompt(results: [FourLClassificationResult]) -> String {
        let payload = results.map { result in
            """
            {"id":"\(result.id.uuidString)","label":"\(result.label)","text":"\(escaped(result.text))"}
            """
        }
        .joined(separator: ",\n")

        return """
        Please rewrite the original sentences from the following 4L classification results into user-friendly reflection sentences.

        Rules:
        - Do not add any events, emotions, numbers, or reasons that are not present in the original text.
        - Do not change the meaning of the original text.
        - Rewrite each sentence in the tone of a mentor gently guiding the user.
        - For Liked, make the positive experience or emotion feel natural.
        - For Learned, make the learned fact or realization clear.
        - For Lacked, express what was lacking or disappointing gently, without sounding critical.
        - For Longed for, make the user's wish, intention, or next goal clear.
        - Output only a JSON array.
        - Do not include explanations, Markdown, or code blocks.
        - Preserve the core event from the original text.
        - If an emotion is present, express it softly and naturally.
        - Do not infer or add emotions that are not in the original text.
        - End each Korean sentence with a soft reflective tone such as "~했어요", "~느꼈어요", "~알게 되었어요", or "~해보고 싶어요".
        - Each item should be at most 1 to 2 sentences.
        - Keep the sentences short and reflective rather than overly explanatory.

        출력 형식:
        [
          {"id":"원래 id","refinedText":"정돈된 문장"}
        ]

        입력:
        [
        \(payload)
        ]
        """
    }

    private func parseRefinedTexts(from text: String) -> [UUID: String] {
        guard let jsonText = extractJSONArray(from: text),
              let data = jsonText.data(using: .utf8),
              let items = try? JSONDecoder().decode([RefinedItem].self, from: data) else {
            return [:]
        }

        return Dictionary(uniqueKeysWithValues: items.compactMap { item in
            guard let id = UUID(uuidString: item.id) else { return nil }
            let refinedText = item.refinedText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !refinedText.isEmpty else { return nil }
            return (id, refinedText)
        })
    }

    private func extractJSONArray(from text: String) -> String? {
        guard let start = text.firstIndex(of: "["),
              let end = text.lastIndex(of: "]"),
              start <= end else {
            return nil
        }

        return String(text[start...end])
    }

    private func escaped(_ text: String) -> String {
        text
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
    }
}

private struct RefinedItem: Decodable {
    let id: String
    let refinedText: String
}
