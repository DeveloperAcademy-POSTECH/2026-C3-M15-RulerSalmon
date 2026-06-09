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
    let positiveKeywords: [SentimentKeyword]
    let negativeKeywords: [SentimentKeyword]
    let segments: [SentimentSegment]

    static let empty = RetrospectiveSentimentResult(
        positivePercentage: 0,
        negativePercentage: 0,
        satisfactionScore: 3,
        positiveKeywords: [],
        negativeKeywords: [],
        segments: []
    )
}

struct RetrospectiveSentimentAnalyzer {
    private let model: HowRUInt8?
    private let tokenizer: HowRUTokenizer
    private let modelLoadStatus: String
    private let usesLexicalFallback: Bool
    private let maxTokenLength = 128

    var debugStatus: String {
        let modelStatus = usesLexicalFallback ? "lexical fallback" : modelLoadStatus
        return "model: \(modelStatus), vocab: \(tokenizer.isReady ? "loaded" : "not loaded")"
    }

    init() {
        let configuration = MLModelConfiguration()
        configuration.computeUnits = .cpuOnly

        do {
            model = try HowRUInt8(configuration: configuration)
            modelLoadStatus = "loaded"
            usesLexicalFallback = false
        } catch {
            model = nil
            modelLoadStatus = "load failed: \(error.localizedDescription)"
            usesLexicalFallback = true
            #if DEBUG
            print("[RetrospectiveSentimentAnalyzer] HowRUInt8 load failed: \(String(describing: error))")
            #endif
        }

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
            debugLog("HowRUInt8 is unavailable. \(modelLoadStatus)")
            return lexicalFallbackScore(for: text)
        }

        guard let tokenized = tokenizer.encode(text, maxLength: maxTokenLength) else {
            debugLog("HowRUTokenizer failed to encode text. Check that vocab.txt is included in the app target.")
            return lexicalFallbackScore(for: text)
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
                return lexicalFallbackScore(for: text)
            }
            return score
        } catch {
            debugLog("HowRUInt8 prediction failed: \(error.localizedDescription)")
            return lexicalFallbackScore(for: text)
        }
    }

    private func lexicalFallbackScore(for text: String) -> Double {
        let normalizedText = text
            .lowercased()
            .replacingOccurrences(of: " ", with: "")

        let positiveMarkers: [(String, Double)] = [
            ("좋", 0.3), ("도움", 0.35), ("성공", 0.45), ("완료", 0.35),
            ("마무리", 0.3), ("만족", 0.45), ("배웠", 0.35), ("학습", 0.25),
            ("성장", 0.35), ("깨달", 0.3), ("알게", 0.25), ("해냈", 0.45),
            ("잘", 0.3), ("안정", 0.35), ("고마", 0.35), ("감사", 0.35),
            ("집중", 0.25), ("개선", 0.3), ("즐거", 0.4), ("행복", 0.45),
            ("기뻤", 0.4), ("뿌듯", 0.45), ("편했", 0.3), ("재밌", 0.35),
            ("괜찮", 0.3), ("수월", 0.35), ("해결", 0.4), ("칭찬", 0.35),
            ("자신", 0.3), ("기대", 0.25), ("효율", 0.3), ("성취", 0.45),
            ("늘었", 0.25), ("익숙", 0.25), ("친절", 0.3), ("회복", 0.25)
        ]
        let negativeMarkers: [(String, Double)] = [
            ("힘들", 0.45), ("아쉽", 0.4), ("부족", 0.4), ("어렵", 0.35),
            ("혼란", 0.4), ("지연", 0.35), ("실패", 0.5), ("놓쳤", 0.4),
            ("놓침", 0.4), ("못했", 0.45), ("문제", 0.35), ("부담", 0.4),
            ("걱정", 0.35), ("불안", 0.4), ("피곤", 0.35), ("늦", 0.3),
            ("막혔", 0.4), ("긴장", 0.3), ("떨", 0.25), ("불편", 0.35),
            ("짜증", 0.45), ("슬프", 0.45), ("후회", 0.45), ("실수", 0.4),
            ("까먹", 0.35), ("미룸", 0.35), ("미뤘", 0.35), ("버거", 0.4),
            ("스트레스", 0.45), ("급했", 0.3), ("헤맸", 0.35), ("당황", 0.35),
            ("답답", 0.4), ("별로", 0.4), ("불만", 0.4), ("망", 0.45),
            ("미흡", 0.4), ("반성", 0.25), ("개선필요", 0.35)
        ]
        let negativePhrases = [
            "좋지않", "잘안", "잘못", "하지못", "못하", "안됐", "안되",
            "필요했", "필요하다고느꼈", "보완", "아쉬웠", "부족했"
        ]

        let positiveScore = positiveMarkers.reduce(0.0) { score, marker in
            score + marker.1 * Double(occurrenceCount(of: marker.0, in: normalizedText))
        }
        let negativeScore = negativeMarkers.reduce(0.0) { score, marker in
            score + marker.1 * Double(occurrenceCount(of: marker.0, in: normalizedText))
        }
        let negativePhraseScore = negativePhrases.reduce(0.0) { score, phrase in
            score + (normalizedText.contains(phrase) ? 0.35 : 0)
        }
        let fourLScore = scoreFromFourLLabel(in: normalizedText)
        let score = positiveScore - negativeScore - negativePhraseScore + fourLScore

        return max(-1, min(1, score))
    }

    private func occurrenceCount(of marker: String, in text: String) -> Int {
        guard !marker.isEmpty else { return 0 }

        var count = 0
        var searchRange = text.startIndex..<text.endIndex
        while let range = text.range(of: marker, options: [], range: searchRange) {
            count += 1
            searchRange = range.upperBound..<text.endIndex
        }
        return count
    }

    private func scoreFromFourLLabel(in normalizedText: String) -> Double {
        if normalizedText.hasPrefix("liked") || normalizedText.hasPrefix("좋았") {
            return 0.25
        }
        if normalizedText.hasPrefix("learned") || normalizedText.hasPrefix("배운") {
            return 0.25
        }
        if normalizedText.hasPrefix("lacked") || normalizedText.hasPrefix("부족") {
            return -0.3
        }
        if normalizedText.hasPrefix("longedfor") || normalizedText.hasPrefix("바랐") {
            return -0.15
        }
        return 0
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
