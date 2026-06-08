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

final class ReflectionInsightService {
    private enum Section {
        case reflection
        case strength
    }

    private let foundationModelService: FoundationModelServicing
    private let calendar: Calendar

    init(
        foundationModelService: FoundationModelServicing = FoundationModelService(),
        calendar: Calendar = .current
    ) {
        self.foundationModelService = foundationModelService
        self.calendar = calendar
    }

    func generateInsights(
        from records: [SentimentRecord],
        days: Int = 30,
        minimumRepeatCount: Int = 3,
        referenceDate: Date = Date()
    ) async throws -> ReflectionInsightResult {
        let recentRecords = recordsInPeriod(
            records,
            days: days,
            referenceDate: referenceDate
        )

        guard !recentRecords.isEmpty else {
            return .empty
        }

        let prompt = makePrompt(
            records: recentRecords,
            days: days,
            minimumRepeatCount: minimumRepeatCount
        )
        let response = try await foundationModelService.respond(to: prompt)
        let parsedResult = parse(response)

        if parsedResult.reflectionPoints.isEmpty && parsedResult.strengthPoints.isEmpty {
            return makeRuleBasedFallback(
                from: recentRecords,
                minimumRepeatCount: minimumRepeatCount
            )
        }

        return parsedResult
    }

    private func recordsInPeriod(
        _ records: [SentimentRecord],
        days: Int,
        referenceDate: Date
    ) -> [SentimentRecord] {
        guard let startDate = calendar.date(
            byAdding: .day,
            value: -days,
            to: referenceDate
        ) else {
            return records
        }

        return records
            .filter { $0.createdAt >= startDate && $0.createdAt <= referenceDate }
            .sorted { $0.createdAt < $1.createdAt }
    }

    private func makePrompt(
        records: [SentimentRecord],
        days: Int,
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

        return """
        너는 한국어 회고 앱의 분석 엔진이야.
        아래 최근 \(days)일 회고를 의미 단위로 묶어서 반복 인사이트를 만들어줘.

        기준:
        - 비슷한 의미가 \(minimumRepeatCount)회 이상 반복되면 포인트로 제시해.
        - 부정적이거나 해결되지 않은 패턴은 반성 포인트로 분류해.
        - 긍정적이고 계속 잘하고 있는 패턴은 강점 포인트로 분류해.
        - 같은 단어 반복이 아니라 의미가 비슷한 내용을 묶어.
        - 사용자를 비난하지 말고 다정한 제안형으로 말해.
        - 각 섹션은 최대 2개까지만 작성해.

        출력 형식은 반드시 아래 형식만 사용해. 다른 설명은 쓰지 마.
        [REFLECTION]
        - 제목 | 설명 | 횟수
        [STRENGTH]
        - 제목 | 설명 | 횟수

        회고:
        \(recordText)
        """
    }

    private func parse(_ response: String) -> ReflectionInsightResult {
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

            guard let currentSection,
                  let point = parsePoint(from: line) else {
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
            reflectionPoints: Array(reflectionPoints.prefix(2)),
            strengthPoints: Array(strengthPoints.prefix(2))
        )
    }

    private func parsePoint(from line: String) -> ReflectionInsightPoint? {
        let cleanedLine = line
            .trimmingCharacters(in: CharacterSet(charactersIn: "-• "))
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = cleanedLine
            .components(separatedBy: "|")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        guard parts.count >= 3,
              !parts[0].isEmpty,
              !parts[1].isEmpty else {
            return nil
        }

        return ReflectionInsightPoint(
            title: parts[0],
            description: parts[1],
            count: Int(parts[2].filter(\.isNumber)) ?? 1
        )
    }

    private func makeRuleBasedFallback(
        from records: [SentimentRecord],
        minimumRepeatCount: Int
    ) -> ReflectionInsightResult {
        let negativeCount = records.filter { $0.negativePercentage >= 50 }.count
        let positiveCount = records.filter { $0.positivePercentage >= 60 }.count

        let reflectionPoints: [ReflectionInsightPoint] = negativeCount >= minimumRepeatCount
            ? [
                ReflectionInsightPoint(
                    title: "부정 감정 반복",
                    description: "부정 비율이 높은 회고가 반복되고 있어요. 최근 어려움이 이어지는 지점을 조금 더 작게 나눠보면 좋아요.",
                    count: negativeCount
                )
            ]
            : []

        let strengthPoints: [ReflectionInsightPoint] = positiveCount >= minimumRepeatCount
            ? [
                ReflectionInsightPoint(
                    title: "긍정 흐름 유지",
                    description: "긍정 비율이 높은 회고가 꾸준히 보여요. 지금 잘 작동하는 습관을 강점으로 이어가도 좋아요.",
                    count: positiveCount
                )
            ]
            : []

        return ReflectionInsightResult(
            reflectionPoints: reflectionPoints,
            strengthPoints: strengthPoints
        )
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
