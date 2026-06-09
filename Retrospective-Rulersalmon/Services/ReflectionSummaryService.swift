//
//  ReflectionSummaryService.swift
//  Retrospective-Rulersalmon
//
//  Created by dlsundn on 6/3/26.
//

import Foundation

struct ReflectionSummaryResult: Equatable {
    let todaySummary: String
    let actionItems: [String]
}

final class ReflectionSummaryService {
    private let foundationModelService: FoundationModelServicing

    init(foundationModelService: FoundationModelServicing = FoundationModelService()) {
        self.foundationModelService = foundationModelService
    }

    func summarize(
        messages: [ChatMessage],
        results: [FourLClassificationResult],
        refinedTexts: [UUID: String]
    ) async -> ReflectionSummaryResult? {
        do {
            let response = try await foundationModelService.respond(
                to: makePrompt(results: results, refinedTexts: refinedTexts)
            )
            return parseSummary(from: response)
        } catch {
            return nil
        }
    }

    private func makePrompt(
        results: [FourLClassificationResult],
        refinedTexts: [UUID: String]
    ) -> String {
        let longedForItems = results
            .filter { $0.label == "Longed for" && $0.isFourLRelated }
            .map { result in
                refinedTexts[result.id] ?? result.text
            }

        let payload = SummaryPromptPayload(longedForItems: longedForItems)
        let payloadText = encodedJSONString(payload)

        return """
        Create a concise Korean reflection summary and tomorrow action items only from the user's Longed for items.

        Rules:
        - Write in Korean.
        - Do not add events, emotions, reasons, or goals that are not present in the input.
        - Keep the tone warm, practical, and mentor-like.
        - The today summary should be 1 to 2 sentences based only on longedForItems.
        - Derive tomorrow action items only from longedForItems.
        - Review all longedForItems before generating action items.
        - Do not infer context from any source outside longedForItems.
        - Action items must be short task titles, not full sentences.
        - Each action item should be concrete and doable tomorrow.
        - Each action item should be a noun phrase or short task phrase.
        - Do not include duplicate or semantically overlapping action items.
        - If multiple longedForItems point to the same task, merge them into one action item.
        - Do not use reflective endings such as "~했어요", "~느꼈어요", or "~해보고 싶어요" for action items.
        - Do not add explanations after action items.
        - Do not include numbering inside the JSON strings.
        - Generate up to exactly 3 action items when enough information exists.
        - If there is not enough information for an action item, use fewer than 3 items.
        - Output only a JSON object.
        - Do not include explanations, Markdown, or code blocks.

        Output format:
        {
          "todaySummary": "오늘의 요약",
          "actionItems": ["..."]
        }

        Input:
        \(payloadText)
        """
    }

    private func parseSummary(from text: String) -> ReflectionSummaryResult? {
        guard let jsonText = extractJSONObject(from: text),
              let data = jsonText.data(using: .utf8),
              let decoded = try? JSONDecoder().decode(SummaryResponse.self, from: data) else {
            return nil
        }

        return ReflectionSummaryResult(
            todaySummary: decoded.todaySummary.trimmingCharacters(in: .whitespacesAndNewlines),
            actionItems: cleaned(decoded.actionItems)
        )
    }

    private func extractJSONObject(from text: String) -> String? {
        guard let start = text.firstIndex(of: "{"),
              let end = text.lastIndex(of: "}"),
              start <= end else {
            return nil
        }

        return String(text[start...end])
    }

    private func cleaned(_ items: [String]) -> [String] {
        items
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private func encodedJSONString<T: Encodable>(_ value: T) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        guard let data = try? encoder.encode(value),
              let text = String(data: data, encoding: .utf8) else {
            return "{}"
        }

        return text
    }
}

private struct SummaryPromptPayload: Encodable {
    let longedForItems: [String]
}

private struct SummaryResponse: Decodable {
    let todaySummary: String
    let actionItems: [String]
}
