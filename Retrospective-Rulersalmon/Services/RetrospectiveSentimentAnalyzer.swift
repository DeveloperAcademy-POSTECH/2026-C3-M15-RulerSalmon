import Foundation
import CoreML
import NaturalLanguage

enum RetrospectiveSentimentLabel: String {
    case positive
    case neutral
    case negative

    var title: String {
        switch self {
        case .positive:
            "긍정"
        case .neutral:
            "중립"
        case .negative:
            "부정"
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
    let positiveEvidence: Double
    let negativeEvidence: Double
    let positiveKeywords: [SentimentKeyword]
    let negativeKeywords: [SentimentKeyword]
    let segments: [SentimentSegment]

    static let empty = RetrospectiveSentimentResult(
        positivePercentage: 0,
        negativePercentage: 0,
        satisfactionScore: 3,
        positiveEvidence: 0,
        negativeEvidence: 0,
        positiveKeywords: [],
        negativeKeywords: [],
        segments: []
    )
}

struct RetrospectiveSentimentAnalyzer {
    private let model: HowRUInt8?
    private let tokenizer: HowRUTokenizer
    private let maxTokenLength = 128

    var debugStatus: String {
        "model: \(model == nil ? "not loaded" : "loaded"), vocab: \(tokenizer.isReady ? "loaded" : "not loaded")"
    }

    init() {
        let configuration = MLModelConfiguration()
        configuration.computeUnits = .all

        model = try? HowRUInt8(configuration: configuration)
        tokenizer = HowRUTokenizer()
    }

    func analyze(_ transcript: String) -> RetrospectiveSentimentResult {
        let segments = splitIntoSegments(transcript).map(analyzeSegment)
        guard !segments.isEmpty else { return .empty }

        let positiveEvidence = segments.reduce(0) { partial, segment in
            partial + max(segment.score, 0)
        }
        let negativeEvidence = segments.reduce(0) { partial, segment in
            partial + abs(min(segment.score, 0))
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
            positiveEvidence: positiveEvidence,
            negativeEvidence: negativeEvidence,
            positiveKeywords: aggregateKeywords(from: segments, labels: [.positive]),
            negativeKeywords: aggregateKeywords(from: segments, labels: [.negative]),
            segments: segments
        )
    }

    private func analyzeSegment(_ rawText: String) -> SentimentSegment {
        let text = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        let score = predictedScore(for: text)
        let label = label(for: score)
        let keywords = extractKeywords(from: text)

        return SentimentSegment(
            text: text,
            label: label,
            score: score,
            positiveKeywords: label == .positive ? keywords : [],
            negativeKeywords: label == .negative ? keywords : []
        )
    }

    private func predictedScore(for text: String) -> Double {
        guard let model else {
            debugLog("HowRUInt8 failed to load.")
            return 0
        }

        guard let tokenized = tokenizer.encode(text, maxLength: maxTokenLength) else {
            debugLog("HowRUTokenizer failed to encode text. Check that vocab.txt is included in the app target.")
            return 0
        }

        do {
            let output = try model.prediction(
                input_ids: tokenized.inputIds,
                attention_mask: tokenized.attentionMask,
                token_type_ids: tokenized.tokenTypeIds
            )
            let score = output.emotion_score[0].doubleValue
            guard score.isFinite else {
                debugLog("HowRUInt8 returned a non-finite score: \(score). Re-export the CoreML model with INT8 precision.")
                return 0
            }
            return score
        } catch {
            debugLog("HowRUInt8 prediction failed: \(error.localizedDescription)")
            return 0
        }
    }

    private func debugLog(_ message: String) {
        #if DEBUG
        print("[RetrospectiveSentimentAnalyzer] \(message)")
        #endif
    }

    private func label(for score: Double) -> RetrospectiveSentimentLabel {
        if score >= 0.2 {
            return .positive
        } else if score <= -0.2 {
            return .negative
        } else {
            return .neutral
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
