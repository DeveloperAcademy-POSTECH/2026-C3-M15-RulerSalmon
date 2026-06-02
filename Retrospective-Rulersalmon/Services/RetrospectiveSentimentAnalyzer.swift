import Foundation
import NaturalLanguage

enum RetrospectiveSentimentLabel: String {
    case positive
    case neutral
    case negative
    case mixed

    var title: String {
        switch self {
        case .positive:
            "긍정"
        case .neutral:
            "중립"
        case .negative:
            "부정"
        case .mixed:
            "혼합"
        }
    }
}

struct SentimentKeyword: Identifiable {
    let id = UUID()
    let text: String
    let count: Int
}

struct SentimentSegment: Identifiable {
    let id = UUID()
    let text: String
    let label: RetrospectiveSentimentLabel
    let score: Double
    let positiveKeywords: [String]
    let negativeKeywords: [String]
}

struct RetrospectiveSentimentResult {
    let positivePercentage: Double
    let negativePercentage: Double
    let satisfactionScore: Double
    let labelCounts: [RetrospectiveSentimentLabel: Int]
    let positiveKeywords: [SentimentKeyword]
    let negativeKeywords: [SentimentKeyword]
    let segments: [SentimentSegment]

    static let empty = RetrospectiveSentimentResult(
        positivePercentage: 0,
        negativePercentage: 0,
        satisfactionScore: 3,
        labelCounts: [:],
        positiveKeywords: [],
        negativeKeywords: [],
        segments: []
    )
}

struct RetrospectiveSentimentAnalyzer {
    private let model: NLModel?

    init(modelResourceName: String = "AIHUB binary 1") {
        guard let modelURL = Bundle.main.url(forResource: modelResourceName, withExtension: "mlmodelc") else {
            model = nil
            return
        }

        model = try? NLModel(contentsOf: modelURL)
    }

    func analyze(_ transcript: String) -> RetrospectiveSentimentResult {
        let segments = splitIntoSegments(transcript).map(analyzeSegment)
        guard !segments.isEmpty else { return .empty }

        let positiveEvidence = segments.reduce(0) { partial, segment in
            partial + evidenceWeight(for: segment.label, target: .positive)
        }
        let negativeEvidence = segments.reduce(0) { partial, segment in
            partial + evidenceWeight(for: segment.label, target: .negative)
        }
        let evidenceTotal = positiveEvidence + negativeEvidence

        let positivePercentage: Double
        let negativePercentage: Double
        if evidenceTotal > 0 {
            positivePercentage = positiveEvidence / evidenceTotal * 100
            negativePercentage = negativeEvidence / evidenceTotal * 100
        } else {
            positivePercentage = 0
            negativePercentage = 0
        }

        let satisfactionScore: Double
        if evidenceTotal > 0 {
            satisfactionScore = 1 + (positiveEvidence / evidenceTotal * 4)
        } else {
            satisfactionScore = 3
        }

        return RetrospectiveSentimentResult(
            positivePercentage: positivePercentage,
            negativePercentage: negativePercentage,
            satisfactionScore: satisfactionScore,
            labelCounts: Dictionary(grouping: segments, by: \.label).mapValues(\.count),
            positiveKeywords: aggregateKeywords(from: segments, labels: [.positive, .mixed]),
            negativeKeywords: aggregateKeywords(from: segments, labels: [.negative, .mixed]),
            segments: segments
        )
    }

    private func analyzeSegment(_ rawText: String) -> SentimentSegment {
        let text = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        let label = predictedLabel(for: text)
        let score = score(for: label)
        let keywords = extractKeywords(from: text)

        return SentimentSegment(
            text: text,
            label: label,
            score: score,
            positiveKeywords: [.positive, .mixed].contains(label) ? keywords : [],
            negativeKeywords: [.negative, .mixed].contains(label) ? keywords : []
        )
    }

    private func predictedLabel(for text: String) -> RetrospectiveSentimentLabel {
        guard let rawLabel = model?.predictedLabel(for: text) else {
            return .neutral
        }

        return RetrospectiveSentimentLabel(rawValue: rawLabel) ?? .neutral
    }

    private func score(for label: RetrospectiveSentimentLabel) -> Double {
        switch label {
        case .positive:
            1
        case .mixed:
            0.2
        case .neutral:
            0
        case .negative:
            -1
        }
    }

    private func evidenceWeight(
        for label: RetrospectiveSentimentLabel,
        target: RetrospectiveSentimentLabel
    ) -> Double {
        switch (label, target) {
        case (.positive, .positive), (.negative, .negative):
            1
        case (.mixed, .positive), (.mixed, .negative):
            0.5
        default:
            0
        }
    }

    private func splitIntoSegments(_ transcript: String) -> [String] {
        transcript
            .components(separatedBy: CharacterSet(charactersIn: ".?!。！？\n"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private func extractKeywords(from text: String) -> [String] {
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = text

        var tokens: [String] = []
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
            let token = String(text[range]).trimmingCharacters(in: .whitespacesAndNewlines)
            if isKeywordCandidate(token) {
                tokens.append(token)
            }
            return true
        }

        return Array(Set(tokens)).sorted()
    }

    private func isKeywordCandidate(_ token: String) -> Bool {
        guard token.count >= 2 else { return false }

        let stopwords: Set<String> = [
            "이번", "오늘", "전반적으로", "다만", "하지만", "그리고", "그래서", "정도",
            "부분", "점은", "것이", "있는", "있고", "있었다", "했다", "되었다", "나와서"
        ]

        return !stopwords.contains(token)
    }

    private func aggregateKeywords(
        from segments: [SentimentSegment],
        labels: Set<RetrospectiveSentimentLabel>
    ) -> [SentimentKeyword] {
        let keywords = segments
            .filter { labels.contains($0.label) }
            .flatMap { extractKeywords(from: $0.text) }

        return Dictionary(grouping: keywords, by: { $0 })
            .map { SentimentKeyword(text: $0.key, count: $0.value.count) }
            .sorted {
                if $0.count == $1.count { return $0.text < $1.text }
                return $0.count > $1.count
            }
            .prefix(8)
            .map { $0 }
    }
}
