//
//  ReflectionInsightService.swift
//  Retrospective-Rulersalmon
//
//  Created by chaem on 6/7/26.
//

import Foundation

struct ReflectionInsightResult {
    let reflectionPoints: [ReflectionInsightPoint]
    let strengthPoints: [ReflectionInsightPoint]

    static let empty = ReflectionInsightResult(
        reflectionPoints: [],
        strengthPoints: []
    )
}

struct ReflectionInsightPoint: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let description: String
    let count: Int
}

struct ReflectionInsightSourceRecord: Identifiable, Equatable {
    let id: UUID
    let createdAt: Date
    let transcript: String
    let positivePercentage: Double
    let negativePercentage: Double
    let satisfactionScore: Double

    init(
        id: UUID = UUID(),
        createdAt: Date,
        transcript: String,
        positivePercentage: Double,
        negativePercentage: Double,
        satisfactionScore: Double
    ) {
        self.id = id
        self.createdAt = createdAt
        self.transcript = transcript
        self.positivePercentage = positivePercentage
        self.negativePercentage = negativePercentage
        self.satisfactionScore = satisfactionScore
    }
}

struct ReflectionInsightUpdate {
    let matchedInsightIDs: [UUID]
    let newReflectionPoints: [ReflectionInsightPoint]
    let newStrengthPoints: [ReflectionInsightPoint]

    static let empty = ReflectionInsightUpdate(
        matchedInsightIDs: [],
        newReflectionPoints: [],
        newStrengthPoints: []
    )
}

final class ReflectionInsightService {
    private enum Section {
        case reflection
        case strength
    }

    private struct TopicPattern {
        let kind: String
        let title: String
        let keywords: [String]
        let defaultDescription: String
    }

    private struct PatternCandidate {
        let kind: String
        let title: String
        let count: Int
        let matchedKeywords: [String]
        let defaultDescription: String
    }

    private struct InsightPayload: Decodable {
        let reflection: [InsightPayloadPoint]
        let strength: [InsightPayloadPoint]
    }

    private struct InsightPayloadPoint: Decodable {
        let title: String
        let description: String
        let count: Int
    }

    private struct IncrementalInsightPayload: Decodable {
        let matches: [UUID]
        let newReflection: [InsightPayloadPoint]
        let newStrength: [InsightPayloadPoint]

        enum CodingKeys: String, CodingKey {
            case matches
            case newReflection = "new_reflection"
            case newStrength = "new_strength"
        }
    }

    private let foundationModelService: FoundationModelServicing
    private let calendar: Calendar
    private let topicPatterns: [TopicPattern] = [
        TopicPattern(
            kind: "reflection",
            title: "시간 관리",
            keywords: ["시간", "일정", "마감", "늦", "지연", "우선순위", "계획", "미룸", "딜레이", "촉박"],
            defaultDescription: "시간 관리와 일정 조율의 어려움이 반복되고 있어요. 다음 회고에서는 가장 먼저 처리할 일을 하나만 정해보면 좋아요."
        ),
        TopicPattern(
            kind: "strength",
            title: "운동 습관",
            keywords: ["운동", "헬스", "러닝", "산책", "요가", "필라테스", "꾸준", "뿌듯", "체력"],
            defaultDescription: "꾸준히 몸을 움직이고 스스로 뿌듯함을 느끼는 흐름이 반복되고 있어요. 지속 가능한 루틴을 만드는 점이 강점이에요."
        ),
        TopicPattern(
            kind: "reflection",
            title: "집중과 컨디션",
            keywords: ["집중", "피곤", "지침", "컨디션", "휴식", "몰입", "부담", "긴장"],
            defaultDescription: "집중과 컨디션 관리의 어려움이 반복되고 있어요. 무리해서 밀기보다 회복 시간을 먼저 확보해보면 좋아요."
        ),
        TopicPattern(
            kind: "strength",
            title: "협업 적응력",
            keywords: ["팀", "팀원", "소통", "협업", "피드백", "리뷰", "회의", "공유"],
            defaultDescription: "팀과 소통하고 피드백을 받아들이는 모습이 반복되고 있어요. 협업 상황에 적응하는 힘이 강점으로 보여요."
        ),
        TopicPattern(
            kind: "strength",
            title: "학습 정리",
            keywords: ["배웠", "학습", "깨달", "알게", "성장", "이해", "경험"],
            defaultDescription: "회고에서 배운 점을 발견하고 정리하는 흐름이 반복되고 있어요. 경험을 학습으로 바꾸는 능력이 강점이에요."
        )
    ]

    init(
        foundationModelService: FoundationModelServicing = FoundationModelService(),
        calendar: Calendar = .current
    ) {
        self.foundationModelService = foundationModelService
        self.calendar = calendar
    }

    func updateInsights(
        afterAdding newRecord: ReflectionInsightSourceRecord,
        allRecords: [ReflectionInsightSourceRecord],
        existingInsights: [ReflectionInsightRecord],
        minimumRepeatCount: Int = 3
    ) async throws -> ReflectionInsightUpdate {
        guard allRecords.count >= minimumRepeatCount else {
            return .empty
        }
        let candidates = makePatternCandidates(
            from: allRecords,
            minimumRepeatCount: minimumRepeatCount
        )
        guard !candidates.isEmpty else {
            return .empty
        }

        let prompt = makeIncrementalPrompt(
            newRecord: newRecord,
            allRecords: allRecords,
            existingInsights: existingInsights,
            candidates: candidates,
            minimumRepeatCount: minimumRepeatCount
        )
        let response = try await foundationModelService.respond(to: prompt)

        #if DEBUG
        print("[ReflectionInsightService] incremental response: \(response)")
        #endif

        guard let payload = parseIncrementalResponse(response) else {
            return .empty
        }

        let existingIDs = Set(existingInsights.map(\.id))
        let modelMatchedIDs = payload.matches.filter { existingIDs.contains($0) }
        let candidateKeys = Set(candidates.map { normalizedKey($0.title) })
        let candidateMatchedIDs = existingInsights
            .filter { candidateKeys.contains(normalizedKey($0.title)) }
            .map(\.id)
        let matchedIDs = Array(Set(modelMatchedIDs + candidateMatchedIDs))
        let existingTitles = Set(existingInsights.map { normalizedKey($0.title) })
        let existingDescriptions = Set(existingInsights.map { normalizedKey($0.insightDescription) })

        let newReflectionPoints = payload.newReflection.compactMap {
            makePoint(from: $0, minimumRepeatCount: minimumRepeatCount)
        }
        .filter {
            !existingTitles.contains(normalizedKey($0.title)) &&
            !existingDescriptions.contains(normalizedKey($0.description))
        }

        let newStrengthPoints = payload.newStrength.compactMap {
            makePoint(from: $0, minimumRepeatCount: minimumRepeatCount)
        }
        .filter {
            !existingTitles.contains(normalizedKey($0.title)) &&
            !existingDescriptions.contains(normalizedKey($0.description))
        }

        return ReflectionInsightUpdate(
            matchedInsightIDs: matchedIDs,
            newReflectionPoints: stablePoints(
                modelPoints: Array(newReflectionPoints),
                candidates: candidates.filter { $0.kind == "reflection" },
                existingInsights: existingInsights
            ),
            newStrengthPoints: stablePoints(
                modelPoints: Array(newStrengthPoints),
                candidates: candidates.filter { $0.kind == "strength" },
                existingInsights: existingInsights
            )
        )
    }

    func generateInsights(
        from records: [ReflectionInsightSourceRecord],
        days: Int = 30,
        minimumRepeatCount: Int = 3,
        referenceDate: Date = Date()
    ) async throws -> ReflectionInsightResult {
        let effectiveReferenceDate = max(
            referenceDate,
            records.map(\.createdAt).max() ?? referenceDate
        )
        let recentRecords = recordsInPeriod(
            records,
            days: days,
            referenceDate: effectiveReferenceDate
        )

        guard recentRecords.count >= minimumRepeatCount else {
            return .empty
        }
        let candidates = makePatternCandidates(
            from: recentRecords,
            minimumRepeatCount: minimumRepeatCount
        )
        guard !candidates.isEmpty else {
            return .empty
        }

        let prompt = makePrompt(
            records: recentRecords,
            days: days,
            candidates: candidates,
            minimumRepeatCount: minimumRepeatCount
        )
        let response = try await foundationModelService.respond(to: prompt)
        let parsedResult = parse(
            response,
            minimumRepeatCount: minimumRepeatCount
        )

        #if DEBUG
        print("[ReflectionInsightService] records: \(records.count), inPeriod: \(recentRecords.count), response: \(response)")
        #endif

        return stableResult(
            modelResult: parsedResult,
            candidates: candidates
        )
    }

    private func isUsableModelResult(_ result: ReflectionInsightResult) -> Bool {
        let points = result.reflectionPoints + result.strengthPoints
        guard !points.isEmpty else { return false }

        return points.contains { point in
            point.title != "제목" &&
            point.description != "설명" &&
            !point.title.isEmpty &&
            !point.description.isEmpty
        }
    }

    private func recordsInPeriod(
        _ records: [ReflectionInsightSourceRecord],
        days: Int,
        referenceDate: Date
    ) -> [ReflectionInsightSourceRecord] {
        let endOfReferenceDay = calendar.date(
            byAdding: .day,
            value: 1,
            to: calendar.startOfDay(for: referenceDate)
        ) ?? referenceDate
        guard let startDate = calendar.date(
            byAdding: .day,
            value: -(days - 1),
            to: calendar.startOfDay(for: referenceDate)
        ) else {
            return records
        }

        return records
            .filter { $0.createdAt >= startDate && $0.createdAt < endOfReferenceDay }
            .sorted { $0.createdAt < $1.createdAt }
    }

    private func makePatternCandidates(
        from records: [ReflectionInsightSourceRecord],
        minimumRepeatCount: Int
    ) -> [PatternCandidate] {
        topicPatterns.compactMap { pattern in
            let matchingRecords = records.filter { record in
                containsAnyKeyword(
                    in: record.transcript,
                    keywords: pattern.keywords
                )
            }
            guard matchingRecords.count >= minimumRepeatCount else {
                return nil
            }

            let matchedKeywords = pattern.keywords.filter { keyword in
                matchingRecords.contains { record in
                    record.transcript.localizedCaseInsensitiveContains(keyword)
                }
            }

            return PatternCandidate(
                kind: pattern.kind,
                title: pattern.title,
                count: matchingRecords.count,
                matchedKeywords: Array(matchedKeywords.prefix(5)),
                defaultDescription: pattern.defaultDescription
            )
        }
    }

    private func containsAnyKeyword(
        in text: String,
        keywords: [String]
    ) -> Bool {
        keywords.contains { keyword in
            text.localizedCaseInsensitiveContains(keyword)
        }
    }

    private func stableResult(
        modelResult: ReflectionInsightResult,
        candidates: [PatternCandidate]
    ) -> ReflectionInsightResult {
        ReflectionInsightResult(
            reflectionPoints: stablePoints(
                modelPoints: modelResult.reflectionPoints,
                candidates: candidates.filter { $0.kind == "reflection" },
                existingInsights: []
            ),
            strengthPoints: stablePoints(
                modelPoints: modelResult.strengthPoints,
                candidates: candidates.filter { $0.kind == "strength" },
                existingInsights: []
            )
        )
    }

    private func stablePoints(
        modelPoints: [ReflectionInsightPoint],
        candidates: [PatternCandidate],
        existingInsights: [ReflectionInsightRecord]
    ) -> [ReflectionInsightPoint] {
        var points = modelPoints.compactMap { point -> ReflectionInsightPoint? in
            guard !isPlaceholderPoint(
                title: point.title,
                description: point.description
            ) else {
                return nil
            }
                
            guard let candidate = matchingCandidate(for: point, in: candidates) else {
                            return point
                        }

            return ReflectionInsightPoint(
                title: point.title,
                description: point.description,
                count: candidate.count
            )
        }
        let existingKeys = Set(existingInsights.map { normalizedKey($0.title) })
        points.removeAll { point in
            existingKeys.contains(normalizedKey(point.title))
        }

        for candidate in candidates {
            let candidateKey = normalizedKey(candidate.title)
            let alreadyIncluded = points.contains { point in
                normalizedKey(point.title) == candidateKey
            }
            let alreadyExisting = existingKeys.contains(candidateKey)

            guard !alreadyIncluded, !alreadyExisting else {
                continue
            }

            points.append(
                ReflectionInsightPoint(
                    title: candidate.title,
                    description: candidate.defaultDescription,
                    count: candidate.count
                )
            )
        }

        return uniquePointsByTitle(points).sorted { first, second in
            if first.count == second.count { return first.title < second.title }
            return first.count > second.count
        }
    }

    private func uniquePointsByTitle(
        _ points: [ReflectionInsightPoint]
    ) -> [ReflectionInsightPoint] {
        var seenKeys = Set<String>()

        return points.filter { point in
            let key = normalizedKey(point.title)
            guard !seenKeys.contains(key) else { return false }

            seenKeys.insert(key)
            return true
        }
    }

    private func matchingCandidate(
        for point: ReflectionInsightPoint,
        in candidates: [PatternCandidate]
    ) -> PatternCandidate? {
        let pointKey = normalizedKey(point.title)

        return candidates.first { candidate in
            let candidateKey = normalizedKey(candidate.title)
            return pointKey == candidateKey ||
                pointKey.contains(candidateKey) ||
                candidateKey.contains(pointKey)
        }
    }

    private func makePrompt(
        records: [ReflectionInsightSourceRecord],
        days: Int,
        candidates: [PatternCandidate],
        minimumRepeatCount: Int
    ) -> String {
        let recordText = records.map { record in
            """
            - date: \(formatDate(record.createdAt))
              positive: \(formatPercentage(record.positivePercentage))%
              negative: \(formatPercentage(record.negativePercentage))%
              satisfaction: \(formatScore(record.satisfactionScore))/5
              reflection: \(record.transcript)
            """
        }
        .joined(separator: "\n")
        let candidateText = candidates.map { candidate in
            """
            - kind: \(candidate.kind)
              title: \(candidate.title)
              count: \(candidate.count)
              matched_keywords: \(candidate.matchedKeywords.joined(separator: ", "))
            """
        }
        .joined(separator: "\n")

        return """
        너는 한국어 회고 앱의 분석 엔진이야.
        앱이 최근 \(days)일 회고 \(records.count)개에서 반복 후보를 이미 계산했어.
        너는 아래 후보를 사용자에게 보여줄 자연스러운 인사이트 문장으로 바꿔줘.

        기준:
        - 아래 후보는 모두 서로 다른 회고 \(minimumRepeatCount)개 이상에서 반복된 패턴이야.
        - 후보를 누락하지 마.
        - kind가 reflection이면 reflection 배열에 넣어.
        - kind가 strength이면 strength 배열에 넣어.
        - count는 후보의 count 숫자를 그대로 써.
        - title은 후보 title을 그대로 쓰거나 더 자연스럽게 짧게 다듬어.
        - 사용자를 비난하지 말고 다정한 제안형으로 말해.
        - description은 한 회고의 구체적 사건이 아니라 반복되는 공통점을 말해.
        - "제목", "설명", "새 반성 포인트 제목", "새 강점 포인트 제목" 같은 예시 문구를 절대 출력하지 마.

        출력은 반드시 JSON 객체 하나만 사용해. Markdown, 표, 코드블록, 다른 설명은 쓰지 마.
        JSON 키:
        - reflection: 반성 포인트 배열
        - strength: 강점 포인트 배열
        - 각 배열 항목은 title, description, count를 가진 객체
        - title은 2~8단어의 실제 인사이트 이름
        - description은 반복되는 공통점과 다음에 시도할 방향을 담은 한 문장
        - count는 서로 다른 회고에서 발견된 반복 횟수

        반복 후보:
        \(candidateText)

        회고:
        \(recordText)
        """
    }

    private func makeIncrementalPrompt(
        newRecord: ReflectionInsightSourceRecord,
        allRecords: [ReflectionInsightSourceRecord],
        existingInsights: [ReflectionInsightRecord],
        candidates: [PatternCandidate],
        minimumRepeatCount: Int
    ) -> String {
        let existingInsightText = existingInsights.isEmpty
            ? "없음"
            : existingInsights.map { insight in
                """
                - id: \(insight.id.uuidString)
                  kind: \(insight.kind)
                  title: \(insight.title)
                  description: \(insight.insightDescription)
                  count: \(insight.count)
                """
            }
            .joined(separator: "\n")

        let recordText = allRecords.sorted { $0.createdAt < $1.createdAt }.map { record in
            """
            - id: \(record.id.uuidString)
              date: \(formatDate(record.createdAt))
              reflection: \(record.transcript)
            """
        }
        .joined(separator: "\n")
        let candidateText = candidates.map { candidate in
            """
            - kind: \(candidate.kind)
              title: \(candidate.title)
              count: \(candidate.count)
              matched_keywords: \(candidate.matchedKeywords.joined(separator: ", "))
            """
        }
        .joined(separator: "\n")

        return """
        너는 한국어 회고 앱의 인사이트 업데이트 엔진이야.
        앱이 새 회고 저장 후 반복 후보를 이미 계산했어.
        너는 후보를 기존 인사이트와 매칭하거나 새 인사이트 문장으로 바꿔줘.

        절대 규칙:
        - 후보 title이 기존 인사이트와 같은 의미이면 matches에 기존 id만 넣어.
        - 기존 인사이트의 title 또는 description을 절대 다시 쓰거나 바꾸지 마.
        - 기존 인사이트와 같은 뜻의 포인트를 new_reflection 또는 new_strength에 새 문구로 다시 만들지 마.
        - 아래 후보는 모두 서로 다른 회고 \(minimumRepeatCount)개 이상에서 반복된 패턴이야.
        - 기존 인사이트와 다른 후보는 누락하지 말고 새 포인트로 작성해.
        - kind가 reflection이면 new_reflection 배열에 넣어.
        - kind가 strength이면 new_strength 배열에 넣어.
        - count는 후보의 count 숫자를 그대로 써.
        - title은 후보 title을 그대로 쓰거나 더 자연스럽게 짧게 다듬어.
        - 한 회고에만 해당하는 구체적 사건, 날짜, 사람, 물건, 회고 번호를 쓰지 마.
        - "회고1", "회고6", "이 회고에서" 같은 표현을 쓰지 마.
        - description은 구체적 상황이 아니라 여러 회고의 공통점을 다정한 제안형으로 말해.
        - "제목", "설명", "새 반성 포인트 제목", "새 강점 포인트 제목", "구체적 사건이 아니라 반복되는 공통점 설명" 같은 예시 문구를 절대 출력하지 마.

        기존 인사이트:
        \(existingInsightText)

        새로 저장된 회고:
        - id: \(newRecord.id.uuidString)
          date: \(formatDate(newRecord.createdAt))
          reflection: \(newRecord.transcript)

        전체 회고:
        \(recordText)

        반복 후보:
        \(candidateText)

        출력은 반드시 JSON 객체 하나만 사용해. Markdown, 코드블록, 다른 설명은 쓰지 마.
        JSON 키:
        - matches: 기존 인사이트 id 문자열 배열
        - new_reflection: 새 반성 포인트 배열
        - new_strength: 새 강점 포인트 배열
        - 새 포인트 배열 항목은 title, description, count를 가진 객체
        - title은 2~8단어의 실제 인사이트 이름
        - description은 반복되는 공통점과 다음에 시도할 방향을 담은 한 문장
        - count는 서로 다른 회고에서 발견된 반복 횟수

        기존 인사이트와 매칭되지 않는 후보는 빈 배열로 두지 마.
        """
    }

    private func parse(
        _ response: String,
        minimumRepeatCount: Int
    ) -> ReflectionInsightResult {
        if let jsonResult = parseJSON(
            response,
            minimumRepeatCount: minimumRepeatCount
        ) {
            return jsonResult
        }

        var currentSection: Section?
        var reflectionPoints: [ReflectionInsightPoint] = []
        var strengthPoints: [ReflectionInsightPoint] = []

        for rawLine in response.components(separatedBy: .newlines) {
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !line.isEmpty else { continue }

            if line.uppercased().contains("[REFLECTION]") {
                currentSection = .reflection
                continue
            }

            if line.uppercased().contains("[STRENGTH]") {
                currentSection = .strength
                continue
            }

            if line.contains("반성") {
                currentSection = .reflection
                continue
            }

            if line.contains("강점") {
                currentSection = .strength
                continue
            }

            guard let currentSection,
                  let point = parsePoint(
                    from: line,
                    minimumRepeatCount: minimumRepeatCount
                  ) else {
                continue
            }

            switch currentSection {
            case .reflection:
                reflectionPoints.append(point)
            case .strength:
                strengthPoints.append(point)
            }
        }

        return ReflectionInsightResult(
            reflectionPoints: uniquePointsByTitle(reflectionPoints),
            strengthPoints: uniquePointsByTitle(strengthPoints)
        )
    }

    private func parsePoint(
        from line: String,
        minimumRepeatCount: Int
    ) -> ReflectionInsightPoint? {
        let cleanedLine = line
            .trimmingCharacters(in: CharacterSet(charactersIn: "-• "))
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if cleanedLine.contains("---") {
            return nil
        }

        let pipeParts = cleanedLine
            .components(separatedBy: "|")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if let point = makePoint(
            from: pipeParts,
            minimumRepeatCount: minimumRepeatCount
        ) {
            return point
        }

        let colonParts = cleanedLine
            .components(separatedBy: ":")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        if colonParts.count >= 2 {
            let title = colonParts[0]
            let remainder = colonParts.dropFirst().joined(separator: ":")
            let count = parseCount(from: remainder)
            let description = remainder
                .replacingOccurrences(of: "\\(?\\d+\\s*회\\)?", with: "", options: .regularExpression)
                .replacingOccurrences(of: "\\(?[한두세네넷셋다섯]+\\s*(번|회)\\)?", with: "", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)

            return makePoint(
                from: [title, description, count.map(String.init) ?? ""],
                minimumRepeatCount: minimumRepeatCount
            )
        }

        return nil
    }

    private func makePoint(
        from payloadPoint: InsightPayloadPoint,
        minimumRepeatCount: Int
    ) -> ReflectionInsightPoint? {
        makePoint(
            from: [
                payloadPoint.title,
                payloadPoint.description,
                String(payloadPoint.count)
            ],
            minimumRepeatCount: minimumRepeatCount
        )
    }

    private func makePoint(
        from parts: [String],
        minimumRepeatCount: Int
    ) -> ReflectionInsightPoint? {
        guard parts.count >= 3,
              !parts[0].isEmpty,
              !parts[1].isEmpty,
              !isPlaceholderPoint(title: parts[0], description: parts[1]) else {
            return nil
        }

        guard let count = parseCount(from: parts[2]),
              count >= minimumRepeatCount else {
            return nil
        }

        return ReflectionInsightPoint(
            title: parts[0],
            description: parts[1],
            count: count
        )
    }

    private func parseJSON(
        _ response: String,
        minimumRepeatCount: Int
    ) -> ReflectionInsightResult? {
        guard let jsonRange = response.range(
            of: #"\{[\s\S]*\}"#,
            options: .regularExpression
        ) else {
            return nil
        }

        let jsonText = String(response[jsonRange])
        guard let data = jsonText.data(using: .utf8),
              let payload = try? JSONDecoder().decode(InsightPayload.self, from: data) else {
            return nil
        }

        let reflectionPoints = payload.reflection.compactMap {
            makePoint(from: $0, minimumRepeatCount: minimumRepeatCount)
        }
        let strengthPoints = payload.strength.compactMap {
            makePoint(from: $0, minimumRepeatCount: minimumRepeatCount)
        }

        return ReflectionInsightResult(
            reflectionPoints: uniquePointsByTitle(reflectionPoints),
            strengthPoints: uniquePointsByTitle(strengthPoints)
        )
    }

    private func parseIncrementalResponse(_ response: String) -> IncrementalInsightPayload? {
        guard let jsonRange = response.range(
            of: #"\{[\s\S]*\}"#,
            options: .regularExpression
        ) else {
            return nil
        }

        let jsonText = String(response[jsonRange])
        guard let data = jsonText.data(using: .utf8) else {
            return nil
        }

        return try? JSONDecoder().decode(IncrementalInsightPayload.self, from: data)
    }

    private func normalizedKey(_ text: String) -> String {
        text
            .lowercased()
            .filter { !$0.isWhitespace && !$0.isPunctuation }
    }

    private func isPlaceholderPoint(title: String, description: String) -> Bool {
        let normalizedTitle = normalizedKey(title)
        let normalizedDescription = normalizedKey(description)
        let exactPlaceholders = [
            "제목",
            "설명",
            "새반성포인트제목",
            "새강점포인트제목",
            "반복되는공통점설명",
            "구체적사건이아니라반복되는공통점설명"
        ]
        let englishPlaceholders = [
            "title",
            "description"
        ]

        if exactPlaceholders.contains(normalizedTitle) ||
            exactPlaceholders.contains(normalizedDescription) {
            return true
        }

        return englishPlaceholders.contains { fragment in
            normalizedTitle.contains(fragment) || normalizedDescription.contains(fragment)
        }
    }

    private func parseCount(from text: String) -> Int? {
        let digitText = text.filter(\.isNumber)
        if let count = Int(digitText) {
            return count
        }

        let normalizedText = text.replacingOccurrences(of: " ", with: "")
        let koreanCounts = [
            "한": 1,
            "하나": 1,
            "두": 2,
            "둘": 2,
            "세": 3,
            "셋": 3,
            "네": 4,
            "넷": 4,
            "다섯": 5
        ]

        return koreanCounts.first { normalizedText.contains($0.key) }?.value
    }

    private func formatDate(_ date: Date) -> String {
        date.formatted(.dateTime.year().month(.twoDigits).day(.twoDigits))
    }

    private func formatPercentage(_ value: Double) -> String {
        String(format: "%.0f", value)
    }

    private func formatScore(_ value: Double) -> String {
        String(format: "%.1f", value)
    }
}
