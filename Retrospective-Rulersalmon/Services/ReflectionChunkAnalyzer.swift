//
//  ReflectionChunkAnalyzer.swift
//  Retrospective-Rulersalmon
//
//  Created by DevPaul on 5/27/26.
//

import Foundation

struct ReflectionChunkAnalyzer {
    func makeChunk(from rawText: String, startedAt: Date = .now, endedAt: Date = .now) -> SpeechChunk {
        let cleanedText = clean(rawText)
        return SpeechChunk(
            rawText: rawText,
            cleanedText: cleanedText,
            startedAt: startedAt,
            endedAt: endedAt,
            type: chunkType(for: cleanedText)
        )
    }

    func analyze(_ chunk: SpeechChunk) -> ChunkAnalysis {
        let dimensions = detectedDimensions(in: chunk.cleanedText)
        let emotions = detectedEmotions(in: chunk.cleanedText, dimensions: dimensions)
        let evidence = chunk.cleanedText.isEmpty ? [] : [chunk.cleanedText]
        let summary = makeSummary(from: chunk.cleanedText, dimensions: dimensions)
        let missingFollowUpHints = ReflectionDimension.allCases.filter { !dimensions.contains($0) }
        let confidence = makeConfidence(text: chunk.cleanedText, dimensions: dimensions)

        return ChunkAnalysis(
            originalText: chunk.rawText,
            cleanedText: chunk.cleanedText,
            summary: summary,
            detectedDimensions: dimensions,
            emotions: emotions,
            evidence: evidence,
            missingFollowUpHints: missingFollowUpHints,
            confidence: confidence
        )
    }

    private func clean(_ text: String) -> String {
        let fillers = ["음", "어", "그", "근데", "그리고", "아", "뭐랄까", "그러니까"]
        let tokens = text
            .replacingOccurrences(of: "  ", with: " ")
            .split(separator: " ")
            .map(String.init)
            .filter { !fillers.contains($0) }

        return tokens.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func chunkType(for text: String) -> ChunkType {
        if text.isEmpty { return .filler }
        if containsAny(text, ["좋았", "뿌듯", "기뻤", "만족", "즐거"]) { return .emotion }
        if containsAny(text, ["배웠", "배운", "배운 점", "알게", "깨달", "느꼈"]) { return .insight }
        if containsAny(text, ["아쉬", "부족", "못했", "힘들", "어려웠", "꼬였"]) { return .problem }
        if containsAny(text, ["다음", "하고 싶", "해보고 싶", "원해", "원하", "원했"]) { return .desire }
        if containsAny(text, ["회의", "미팅", "프로젝트", "발표", "팀", "일"]) { return .event }
        return .unknown
    }

    private func detectedDimensions(in text: String) -> [ReflectionDimension] {
        var dimensions: [ReflectionDimension] = []

        if containsAny(text, ["좋았", "뿌듯", "만족", "기뻤", "잘 됐", "괜찮았"]) {
            dimensions.append(.liked)
        }

        if containsAny(text, ["배웠", "배운", "배운 점", "알게", "깨달", "느꼈", "공부", "이해"]) {
            dimensions.append(.learned)
        }

        if containsAny(text, ["아쉬", "부족", "못했", "힘들", "어려웠", "막혔"]) {
            dimensions.append(.lacked)
        }

        if containsAny(text, ["다음", "하고 싶", "해보고 싶", "원해", "원하", "더 잘", "개선"]) {
            dimensions.append(.longedFor)
        }

        return dimensions.uniqued()
    }

    private func detectedEmotions(in text: String, dimensions: [ReflectionDimension]) -> [String] {
        var emotions: [String] = []

        if containsAny(text, ["뿌듯", "기뻤", "좋았", "만족"]) {
            emotions.append("뿌듯함")
        }

        if containsAny(text, ["아쉬", "부족", "못했", "어려웠"]) {
            emotions.append("아쉬움")
        }

        if containsAny(text, ["힘들", "지쳤", "부담"]) {
            emotions.append("부담감")
        }

        if dimensions.contains(.learned) {
            emotions.append("깨달음")
        }

        return emotions.uniqued()
    }

    private func makeSummary(from text: String, dimensions: [ReflectionDimension]) -> String {
        guard !text.isEmpty else {
            return "의미 있는 회고 내용이 아직 충분하지 않음."
        }

        let labels = dimensions.map(\.description)
        guard !labels.isEmpty else {
            return "사용자가 회고를 말했지만 아직 4L 중 어디에 속하는지 확실하지 않음."
        }

        return labels.joined(separator: ", ") + "에 해당하는 회고가 감지됨."
    }

    private func makeConfidence(text: String, dimensions: [ReflectionDimension]) -> Double {
        let lengthScore = min(Double(text.count) / 80.0, 0.45)
        let dimensionScore = min(Double(dimensions.count) * 0.2, 0.45)
        return min(lengthScore + dimensionScore + 0.1, 1.0)
    }

    private func containsAny(_ text: String, _ keywords: [String]) -> Bool {
        keywords.contains { text.contains($0) }
    }
}

private extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}
