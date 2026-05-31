import Foundation

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
    private let positiveLexicon = [
        "좋", "만족", "성장", "배웠", "배움", "뿌듯", "도움", "개선", "안정", "원활",
        "명확", "효율", "신뢰", "성공", "잘 됐", "잘되", "괜찮", "편했", "해결", "자신감",
        "의미", "적극", "빠르게", "충분", "완성", "기대보다", "건강", "다행", "탄탄", "좋아졌"
    ]

    private let negativeLexicon = [
        "힘들", "아쉽", "불만", "문제", "지연", "혼란", "부족", "불안", "어렵", "피곤",
        "부담", "늦", "밀려", "모호", "애매", "부정확", "장애", "반복", "기술 부채", "급하게",
        "놓친", "낮", "갈등", "꼬였", "차질", "답답", "기다", "부족", "리스크", "실패"
    ]

    private let positiveNegationPhrases = [
        "나쁘지 않", "불편하지 않", "아쉽지 않", "힘들지 않", "문제 없", "문제가 없"
    ]

    private let negativeNegationPhrases = [
        "좋지 않", "만족스럽지 않", "괜찮지 않", "원활하지 않", "명확하지 않", "충분하지 않"
    ]

    func analyze(_ transcript: String) -> RetrospectiveSentimentResult {
        let segments = splitIntoSegments(transcript).map(analyzeSegment)
        guard !segments.isEmpty else { return .empty }

        let positiveEvidence = segments.reduce(0) { partial, segment in
            partial + Double(segment.positiveKeywords.count)
        }
        let negativeEvidence = segments.reduce(0) { partial, segment in
            partial + Double(segment.negativeKeywords.count)
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
            positiveKeywords: aggregateKeywords(segments.flatMap(\.positiveKeywords)),
            negativeKeywords: aggregateKeywords(segments.flatMap(\.negativeKeywords)),
            segments: segments
        )
    }

    private func analyzeSegment(_ rawText: String) -> SentimentSegment {
        let text = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        var positiveMatches = matches(in: text, lexicon: positiveLexicon)
        var negativeMatches = matches(in: text, lexicon: negativeLexicon)

        for phrase in positiveNegationPhrases where text.contains(phrase) {
            positiveMatches.append(phrase)
            negativeMatches.removeAll { phrase.contains($0) || $0.contains("나쁘") || $0.contains("불편") || $0.contains("아쉽") || $0.contains("힘들") || $0.contains("문제") }
        }

        for phrase in negativeNegationPhrases where text.contains(phrase) {
            negativeMatches.append(phrase)
            positiveMatches.removeAll { phrase.contains($0) || $0.contains("좋") || $0.contains("만족") || $0.contains("괜찮") || $0.contains("원활") || $0.contains("명확") || $0.contains("충분") }
        }

        let positiveCount = Double(positiveMatches.count)
        let negativeCount = Double(negativeMatches.count)
        let total = positiveCount + negativeCount

        let score = total > 0 ? (positiveCount - negativeCount) / total : 0
        let label: RetrospectiveSentimentLabel
        if positiveCount > 0 && negativeCount > 0 {
            label = .mixed
        } else if score > 0 {
            label = .positive
        } else if score < 0 {
            label = .negative
        } else {
            label = .neutral
        }

        return SentimentSegment(
            text: text,
            label: label,
            score: score,
            positiveKeywords: Array(Set(positiveMatches)).sorted(),
            negativeKeywords: Array(Set(negativeMatches)).sorted()
        )
    }

    private func splitIntoSegments(_ transcript: String) -> [String] {
        transcript
            .components(separatedBy: CharacterSet(charactersIn: ".?!。！？\n"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private func matches(in text: String, lexicon: [String]) -> [String] {
        lexicon.filter { text.localizedStandardContains($0) }
    }

    private func aggregateKeywords(_ keywords: [String]) -> [SentimentKeyword] {
        Dictionary(grouping: keywords, by: { $0 })
            .map { SentimentKeyword(text: $0.key, count: $0.value.count) }
            .sorted {
                if $0.count == $1.count { return $0.text < $1.text }
                return $0.count > $1.count
            }
            .prefix(8)
            .map { $0 }
    }
}
