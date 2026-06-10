//
//  AppDataStore.swift
//  Retrospective-Rulersalmon
//
//  Created by DevPaul on 6/8/26.
//

import Foundation
import SwiftData

@MainActor
final class AppDataStore {
    static let shared = AppDataStore()

    let container: ModelContainer

    private init() {
        do {
            container = try ModelContainer(
                for: StoredUserProfile.self,
                StoredReflectionSession.self,
                StoredReflectionMemoryRecord.self,
                StoredReflectionReport.self,
                SentimentRecord.self,
                ReflectionInsightRecord.self
            )
            logStorageLocation()
            seedDevelopmentReflectionDataIfNeeded()
        } catch {
            fatalError("Failed to initialize SwiftData container: \(error)")
        }
    }

    private var context: ModelContext {
        container.mainContext
    }

    func loadCurrentProfile() -> StoredUserProfile? {
        let descriptor = FetchDescriptor<StoredUserProfile>()
        return try? context.fetch(descriptor).first
    }

    func saveProfile(
        nickname: String,
        job: Job,
        ageGroup: AgeGroup,
        mentor: Mentor?,
        appleIntelligencePermissionGranted: Bool? = nil,
        onboardingCompleted: Bool? = nil
    ) {
        let profile = loadCurrentProfile() ?? StoredUserProfile()
        profile.nickname = nickname
        profile.jobRawValue = job.rawValue
        profile.ageGroupRawValue = ageGroup.rawValue

        if let mentor {
            profile.mentorID = mentor.id
            profile.mentorName = mentor.name
            profile.mentorImageName = mentor.imageName
            profile.mentorPromptStyle = mentor.promptStyle
        }

        if let appleIntelligencePermissionGranted {
            profile.appleIntelligencePermissionGranted = appleIntelligencePermissionGranted
        }

        if let onboardingCompleted {
            profile.onboardingCompleted = onboardingCompleted
        }

        profile.updatedAt = .now

        if profile.modelContext == nil {
            context.insert(profile)
        }

        saveContext(reason: "saveProfile")
    }

    func hasCompletedOnboarding() -> Bool {
        loadCurrentProfile()?.onboardingCompleted == true
    }

    func createReflectionSessionIfNeeded(id: UUID, mentorName: String?) {
        if session(for: id) != nil {
            return
        }

        let record = StoredReflectionSession(
            id: id,
            mentorName: mentorName ?? loadCurrentProfile()?.mentorName ?? Mentor.sampleMentors.first?.name ?? "Mentor"
        )
        context.insert(record)
        saveContext(reason: "createReflectionSessionIfNeeded")
    }

    func updateReflectionSession(
        id: UUID,
        firstUserMessage: String?,
        latestSummary: String?,
        isClosed: Bool
    ) {
        let session = session(for: id) ?? StoredReflectionSession(
            id: id,
            mentorName: loadCurrentProfile()?.mentorName ?? Mentor.sampleMentors.first?.name ?? "Mentor"
        )

        if session.modelContext == nil {
            context.insert(session)
        }

        if let firstUserMessage, session.firstUserMessage == nil {
            session.firstUserMessage = firstUserMessage
        }

        if let latestSummary, !latestSummary.isEmpty {
            session.latestSummary = latestSummary
        }

        session.isClosed = isClosed
        session.updatedAt = .now
        saveContext(reason: "updateReflectionSession")
    }

    func appendMemoryEntry(_ entry: ReflectionMemoryEntry) {
        guard memoryRecord(for: entry.id) == nil else { return }
        context.insert(StoredReflectionMemoryRecord(entry: entry))
        saveContext(reason: "appendMemoryEntry")
    }

    func allMemoryEntries() -> [ReflectionMemoryEntry] {
        let descriptor = FetchDescriptor<StoredReflectionMemoryRecord>(
            sortBy: [SortDescriptor(\.createdAt)]
        )
        let records = (try? context.fetch(descriptor)) ?? []
        return records.map(\.asEntry)
    }

    func memoryEntries(in sessionID: UUID) -> [ReflectionMemoryEntry] {
        let predicate = #Predicate<StoredReflectionMemoryRecord> { record in
            record.sessionID == sessionID
        }
        let descriptor = FetchDescriptor<StoredReflectionMemoryRecord>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.createdAt)]
        )
        let records = (try? context.fetch(descriptor)) ?? []
        return records.map(\.asEntry)
    }

    // MARK: 분석결과

    func saveReport(_ report: StoredReflectionReport) {
        if let existing = reflectionReport(for: report.id) {
            context.delete(existing)
        }
        context.insert(report)
        saveContext(reason: "saveReport")
    }

    func allReports() -> [StoredReflectionReport] {
        let descriptor = FetchDescriptor<StoredReflectionReport>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    func deleteReport(id: UUID) {
        guard let report = reflectionReport(for: id) else { return }
        context.delete(report)
        saveContext(reason: "deleteReport")
    }

    private func reflectionReport(for id: UUID) -> StoredReflectionReport? {
        let predicate = #Predicate<StoredReflectionReport> { $0.id == id }
        let descriptor = FetchDescriptor<StoredReflectionReport>(predicate: predicate)
        return try? context.fetch(descriptor).first
    }

    func saveSentimentRecord(_ record: SentimentRecord) {
        context.insert(record)
        saveContext(reason: "saveSentimentRecord")
    }

    private func sentimentRecord(for id: UUID) -> SentimentRecord? {
        let predicate = #Predicate<SentimentRecord> { $0.id == id }
        let descriptor = FetchDescriptor<SentimentRecord>(predicate: predicate)
        return try? context.fetch(descriptor).first
    }

    func allSentimentRecords() -> [SentimentRecord] {
        let descriptor = FetchDescriptor<SentimentRecord>(
            sortBy: [SortDescriptor(\.createdAt)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    func allInsightRecords() -> [ReflectionInsightRecord] {
        let descriptor = FetchDescriptor<ReflectionInsightRecord>(
            sortBy: [
                SortDescriptor(\.updatedAt, order: .reverse),
                SortDescriptor(\.count, order: .reverse)
            ]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    func insightRecords(year: Int, month: Int) -> [ReflectionInsightRecord] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current

        let components = DateComponents(year: year, month: month)
        guard
            let startDate = calendar.date(from: components),
            let endDate = calendar.date(byAdding: .month, value: 1, to: startDate)
        else { return [] }

        let predicate = #Predicate<ReflectionInsightRecord> { record in
            record.updatedAt >= startDate && record.updatedAt < endDate
        }

        let descriptor = FetchDescriptor<ReflectionInsightRecord>(
            predicate: predicate,
            sortBy: [
                SortDescriptor(\.updatedAt, order: .reverse),
                SortDescriptor(\.count, order: .reverse)
            ]
        )

        return (try? context.fetch(descriptor)) ?? []
    }

    func applyInsightUpdate(_ update: ReflectionInsightUpdate, sourceRecordID: UUID) {
        let existingRecords = allInsightRecords()
        let matchedIDs = Set(update.matchedInsightIDs)

        existingRecords
            .filter { matchedIDs.contains($0.id) }
            .forEach { record in
                record.addSourceRecord(id: sourceRecordID)
                record.count = max(record.count + 1, record.sourceIDs.count)
                record.updatedAt = .now
            }

        update.newReflectionPoints.forEach { point in
            context.insert(
                ReflectionInsightRecord(
                    kind: "reflection",
                    title: point.title,
                    insightDescription: point.description,
                    count: point.count,
                    sourceRecordIDs: [sourceRecordID]
                )
            )
        }

        update.newStrengthPoints.forEach { point in
            context.insert(
                ReflectionInsightRecord(
                    kind: "strength",
                    title: point.title,
                    insightDescription: point.description,
                    count: point.count,
                    sourceRecordIDs: [sourceRecordID]
                )
            )
        }

        saveContext(reason: "applyInsightUpdate")
    }

    func makeMainPageContent() -> MainPageContent {
        let profile = loadCurrentProfile()
        let mentorName = profile?.mentorName ?? Mentor.sampleMentors.first?.name ?? "Mentor"
        let mentorImageName = profile?.mentorImageName ?? Mentor.sampleMentors.first?.imageName ?? "Howard"
        let userName = profile?.nickname.nonEmpty ?? "사용자"
        let retrospectives = recentRetrospectiveItems(limit: 8)

        return MainPageContent(
            userName: userName,
            encouragementMessage: encouragementMessage(for: retrospectives.count),
            mentorBadgeTitle: "오늘 함께할 멘토",
            mentorName: mentorName,
            mentorImageName: mentorImageName,
            mentorGreeting: mentorGreeting(for: mentorName),
            retrospectives: retrospectives
        )
    }
    
    func sentimentRecords(year: Int, month: Int) -> [SentimentRecord] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        
        let components = DateComponents(year: year, month: month)
        guard
            let startDate = calendar.date(from: components),
            let endDate = calendar.date(byAdding: .month, value: 1, to: startDate)
        else { return [] }
        
        let predicate = #Predicate<SentimentRecord> { record in
            record.createdAt >= startDate && record.createdAt < endDate
        }
        
        let descriptor = FetchDescriptor<SentimentRecord>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.createdAt)]
        )
        
        return (try? context.fetch(descriptor)) ?? []
    }

    func sentimentRecords(startDate: Date, endDate: Date) -> [SentimentRecord] {
        let predicate = #Predicate<SentimentRecord> { record in
            record.createdAt >= startDate && record.createdAt < endDate
        }

        let descriptor = FetchDescriptor<SentimentRecord>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.createdAt)]
        )

        return (try? context.fetch(descriptor)) ?? []
    }

    private func recentRetrospectiveItems(limit: Int) -> [RetrospectiveItem] {
        let reportDescriptor = FetchDescriptor<StoredReflectionReport>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let reports = (try? context.fetch(reportDescriptor)) ?? []
        if !reports.isEmpty {
            return Array(reports.prefix(limit)).map { report in
                RetrospectiveItem(
                    date: report.createdAt.compactKoreanDate,
                    title: String(report.todaySummary.prefix(20))
                )
            }
        }

        let sessionDescriptor = FetchDescriptor<StoredReflectionSession>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        let sessions = (try? context.fetch(sessionDescriptor)) ?? []

        return Array(sessions.prefix(limit)).map { session in
            RetrospectiveItem(
                date: session.updatedAt.compactKoreanDate,
                title: session.displayTitle
            )
        }
    }

    private func session(for id: UUID) -> StoredReflectionSession? {
        let predicate = #Predicate<StoredReflectionSession> { session in
            session.id == id
        }
        let descriptor = FetchDescriptor<StoredReflectionSession>(predicate: predicate)
        return try? context.fetch(descriptor).first
    }

    private func memoryRecord(for id: UUID) -> StoredReflectionMemoryRecord? {
        let predicate = #Predicate<StoredReflectionMemoryRecord> { record in
            record.id == id
        }
        let descriptor = FetchDescriptor<StoredReflectionMemoryRecord>(predicate: predicate)
        return try? context.fetch(descriptor).first
    }

    private func encouragementMessage(for retrospectiveCount: Int) -> String {
        if retrospectiveCount == 0 {
            return "오늘의 첫 회고를 가볍게 시작해 봐요."
        }

        return "지난 회고가 \(retrospectiveCount)개 쌓였어요.\n오늘도 흐름을 이어서 정리해 봐요."
    }

    private func mentorGreeting(for mentorName: String) -> String {
        switch mentorName {
        case "Howard":
            return "좋아, 오늘도 시원하게 정리해보자!"
        case "Gommin":
            return "천천히 괜찮아. 오늘 감정부터 같이 정리해보자."
        case "MK":
            return "오늘 있었던 일 중 바로 정리해볼 포인트부터 보자."
        default:
            return "오늘 회고를 함께 정리해보자."
        }
    }

    private func saveContext(reason: String) {
        do {
            try context.save()
            print("[Storage][SwiftData] save succeeded reason=\(reason)")
        } catch {
            print("[Storage][SwiftData] save failed reason=\(reason) error=\(error)")
        }
    }

    private func logStorageLocation() {
        if let applicationSupportURL = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first {
            print("[Storage][SwiftData] applicationSupport=\(applicationSupportURL.path)")
        }
    }

    private func seedDevelopmentReflectionDataIfNeeded() {
        #if DEBUG
        let samples = DevelopmentReflectionSample.samples
        let analyzer = RetrospectiveSentimentAnalyzer()
        var didSeed = false

        for sample in samples {
            if reflectionReport(for: sample.id) == nil {
                context.insert(
                    StoredReflectionReport(
                        id: sample.id,
                        createdAt: sample.date,
                        todaySummary: sample.summary,
                        refinedReflection: sample.transcript,
                        fourLItemsRaw: sample.fourLItemsRaw,
                        coreKeywordsRaw: sample.coreKeywords.joined(separator: "|"),
                        emotionKeywordsRaw: sample.emotionKeywords.joined(separator: "|"),
                        actionItemsRaw: sample.actionItems.joined(separator: "|")
                    )
                )
                didSeed = true
            }

            if sentimentRecord(for: sample.id) == nil {
                let result = analyzer.analyze(sample.transcript)
                context.insert(
                    SentimentRecord(
                        id: sample.id,
                        createdAt: sample.date,
                        transcript: sample.transcript,
                        result: result
                    )
                )
                didSeed = true
            }
        }

        if didSeed {
            saveContext(reason: "seedDevelopmentReflectionDataIfNeeded")
        }
        #endif
    }
}

private struct DevelopmentReflectionSample {
    let id: UUID
    let date: Date
    let transcript: String
    let summary: String
    let coreKeywords: [String]
    let emotionKeywords: [String]
    let actionItems: [String]
    let fourLItemsRaw: String

    static let samples: [DevelopmentReflectionSample] = [
        DevelopmentReflectionSample(
            id: UUID(uuidString: "20260601-0000-0000-0000-000000000001") ?? UUID(),
            date: makeDate(month: 6, day: 1),
            transcript: """
            오늘은 Git 충돌을 해결하는 데 많은 시간을 썼다.
            처음에는 원인을 찾지 못했지만 커밋 기록을 하나씩 따라가며 결국 해결했다.
            덕분에 cherry-pick과 revert 흐름을 이전보다 훨씬 잘 이해하게 되었다.
            다만 작업을 시작하기 전에 브랜치 상태를 충분히 확인하지 못한 점은 아쉽다.
            다음에는 작업 전에 현재 브랜치와 base 브랜치를 먼저 점검해야겠다.
            """,
            summary: "Git 충돌을 해결하며 cherry-pick과 revert 흐름을 익혔고, 다음에는 브랜치 상태를 먼저 확인하기로 했다.",
            coreKeywords: ["Git 충돌", "커밋 기록", "cherry-pick", "revert", "브랜치 점검"],
            emotionKeywords: ["아쉬움", "뿌듯함", "이해", "집중"],
            actionItems: ["브랜치 상태 확인하기", "base 브랜치 점검하기"],
            fourLItemsRaw: [
                "Liked:커밋 기록을 따라가며 Git 충돌을 해결한 점이 좋았다.",
                "Learned:cherry-pick과 revert 흐름을 더 잘 이해하게 되었다.",
                "Lacked:작업 전 브랜치 상태를 충분히 확인하지 못한 점이 아쉬웠다.",
                "Longed for:다음에는 현재 브랜치와 base 브랜치를 먼저 점검하고 싶다."
            ].joined(separator: "|")
        ),
        DevelopmentReflectionSample(
            id: UUID(uuidString: "20260602-0000-0000-0000-000000000002") ?? UUID(),
            date: makeDate(month: 6, day: 2),
            transcript: """
            오늘은 분석 탭과 감정 분석 데이터를 연결하는 작업을 진행했다.
            예상보다 구조가 복잡했지만 데이터 흐름을 직접 따라가며 이해할 수 있었다.
            막히는 부분이 있었지만 문서를 찾아보고 여러 방법을 시도하면서 해결했다.
            혼자 고민하는 시간이 길어져 팀원에게 질문하는 시점이 조금 늦었다.
            다음에는 어려운 문제가 생기면 더 빨리 의견을 구하고 싶다.
            """,
            summary: "분석 탭과 감정 분석 데이터를 연결하며 데이터 흐름을 이해했고, 다음에는 더 빨리 팀원에게 의견을 구하기로 했다.",
            coreKeywords: ["분석 탭", "감정 분석", "데이터 흐름", "문서 탐색", "팀원 질문"],
            emotionKeywords: ["복잡함", "이해", "막힘", "아쉬움"],
            actionItems: ["막히면 빠르게 질문하기", "데이터 흐름 먼저 정리하기"],
            fourLItemsRaw: [
                "Liked:여러 방법을 시도하며 문제를 해결한 점이 좋았다.",
                "Learned:분석 탭과 감정 분석 데이터의 흐름을 이해하게 되었다.",
                "Lacked:혼자 고민하는 시간이 길어져 질문이 늦어진 점이 아쉬웠다.",
                "Longed for:어려운 문제가 생기면 더 빨리 의견을 구하고 싶다."
            ].joined(separator: "|")
        ),
        DevelopmentReflectionSample(
            id: UUID(uuidString: "20260608-0000-0000-0000-000000000008") ?? UUID(),
            date: makeDate(month: 6, day: 8),
            transcript: """
            오늘은 만족도 점수 계산 로직을 정리했다.
            구현 과정에서 기존 코드 구조를 다시 살펴보며 배울 점이 많았다.
            특히 SwiftData와 ViewModel 연결 방식을 더 명확하게 이해할 수 있었다.
            하지만 작업 범위를 명확하게 나누지 않고 시작해서 중간에 방향이 흔들렸다.
            다음에는 해야 할 일을 먼저 정리한 뒤 구현을 시작해야겠다.
            """,
            summary: "만족도 점수 계산 로직을 정리하며 SwiftData와 ViewModel 연결을 이해했고, 다음에는 작업 범위를 먼저 정리하기로 했다.",
            coreKeywords: ["만족도 점수", "계산 로직", "SwiftData", "ViewModel", "작업 범위"],
            emotionKeywords: ["배움", "이해", "흔들림", "아쉬움"],
            actionItems: ["해야 할 일 먼저 정리하기", "작업 범위 명확히 나누기"],
            fourLItemsRaw: [
                "Liked:기존 코드 구조를 다시 살펴보며 배울 점이 많았던 점이 좋았다.",
                "Learned:SwiftData와 ViewModel 연결 방식을 더 명확하게 이해하게 되었다.",
                "Lacked:작업 범위를 명확하게 나누지 않아 중간에 방향이 흔들린 점이 아쉬웠다.",
                "Longed for:다음에는 해야 할 일을 먼저 정리한 뒤 구현을 시작하고 싶다."
            ].joined(separator: "|")
        ),
        DevelopmentReflectionSample(
            id: UUID(uuidString: "20260609-0000-0000-0000-000000000009") ?? UUID(),
            date: makeDate(month: 6, day: 9),
            transcript: """
            오늘은 PR을 정리하고 리뷰를 준비했다.
            실수로 잘못된 브랜치에 작업을 반영했지만 문제를 복구하는 과정에서 Git 사용 경험이 늘었다.
            문제가 생겼을 때 끝까지 원인을 찾아 해결한 점은 만족스럽다.
            다만 상황을 정리해서 팀에 공유하기까지 시간이 꽤 걸렸다.
            앞으로는 이슈가 발생하면 바로 공유하면서 진행해야겠다.
            """,
            summary: "PR 정리와 리뷰 준비 중 브랜치 문제를 복구하며 Git 경험을 쌓았고, 앞으로는 이슈를 더 빠르게 공유하기로 했다.",
            coreKeywords: ["PR 정리", "리뷰 준비", "브랜치 복구", "Git 경험", "팀 공유"],
            emotionKeywords: ["만족", "긴장", "회복", "아쉬움"],
            actionItems: ["이슈 발생 시 바로 공유하기", "브랜치 확인 후 작업 반영하기"],
            fourLItemsRaw: [
                "Liked:문제가 생겼을 때 끝까지 원인을 찾아 해결한 점이 만족스러웠다.",
                "Learned:잘못된 브랜치 작업을 복구하며 Git 사용 경험이 늘었다.",
                "Lacked:상황을 정리해서 팀에 공유하기까지 시간이 걸린 점이 아쉬웠다.",
                "Longed for:앞으로는 이슈가 발생하면 바로 공유하면서 진행하고 싶다."
            ].joined(separator: "|")
        ),
        DevelopmentReflectionSample(
            id: UUID(uuidString: "20260610-0000-0000-0000-000000000010") ?? UUID(),
            date: makeDate(month: 6, day: 10),
            transcript: """
            오늘은 실제 회고 데이터를 분석 화면에 표시하는 작업을 마무리했다.
            데이터가 연결되는 과정을 확인하면서 앱 구조에 대한 이해도가 높아졌다.
            예상치 못한 오류가 있었지만 여러 시도를 통해 해결 방법을 찾았다.
            초반 설계를 충분히 하지 못해 나중에 수정해야 하는 부분이 생겼다.
            다음에는 구현 전에 전체 흐름을 먼저 그려보고 시작하고 싶다.
            """,
            summary: "실제 회고 데이터를 분석 화면에 표시하며 앱 구조를 더 이해했고, 다음에는 전체 흐름을 먼저 설계하기로 했다.",
            coreKeywords: ["회고 데이터", "분석 화면", "앱 구조", "오류 해결", "초반 설계"],
            emotionKeywords: ["이해", "성취", "당황", "아쉬움"],
            actionItems: ["구현 전 전체 흐름 그려보기", "초반 설계 충분히 하기"],
            fourLItemsRaw: [
                "Liked:여러 시도를 통해 예상치 못한 오류의 해결 방법을 찾은 점이 좋았다.",
                "Learned:데이터가 연결되는 과정을 확인하며 앱 구조에 대한 이해도가 높아졌다.",
                "Lacked:초반 설계를 충분히 하지 못해 나중에 수정이 생긴 점이 아쉬웠다.",
                "Longed for:다음에는 구현 전에 전체 흐름을 먼저 그려보고 시작하고 싶다."
            ].joined(separator: "|")
        )
    ]

    private static func makeDate(month: Int, day: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        return calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: 12)) ?? Date()
    }
}

@Model
final class StoredUserProfile {
    @Attribute(.unique) var storageKey: String
    var nickname: String
    var jobRawValue: String
    var ageGroupRawValue: String
    var mentorID: UUID?
    var mentorName: String?
    var mentorImageName: String?
    var mentorPromptStyle: String?
    var appleIntelligencePermissionGranted: Bool
    var onboardingCompleted: Bool
    var updatedAt: Date

    init() {
        storageKey = "current-user-profile"
        nickname = ""
        jobRawValue = Job.student.rawValue
        ageGroupRawValue = AgeGroup.twenties.rawValue
        mentorID = nil
        mentorName = nil
        mentorImageName = nil
        mentorPromptStyle = nil
        appleIntelligencePermissionGranted = false
        onboardingCompleted = false
        updatedAt = .now
    }
}

@Model
final class StoredReflectionSession {
    @Attribute(.unique) var id: UUID
    var mentorName: String
    var firstUserMessage: String?
    var latestSummary: String?
    var isClosed: Bool
    var createdAt: Date
    var updatedAt: Date

    init(id: UUID, mentorName: String) {
        self.id = id
        self.mentorName = mentorName
        firstUserMessage = nil
        latestSummary = nil
        isClosed = false
        createdAt = .now
        updatedAt = .now
    }

    var displayTitle: String {
        if let latestSummary, !latestSummary.isEmpty {
            return String(latestSummary.prefix(20))
        }

        if let firstUserMessage, !firstUserMessage.isEmpty {
            return String(firstUserMessage.prefix(20))
        }

        return "회고 기록"
    }
}

@Model
final class StoredReflectionMemoryRecord {
    @Attribute(.unique) var id: UUID
    var sessionID: UUID
    var text: String
    var summary: String
    var topic: String?
    var dimensionHintsRaw: String
    var keywordsRaw: String
    var evidenceRaw: String
    var importance: Double
    var createdAt: Date

    init(entry: ReflectionMemoryEntry) {
        id = entry.id
        sessionID = entry.sessionID
        text = entry.text
        summary = entry.summary
        topic = entry.topic
        dimensionHintsRaw = entry.dimensionHints.map(\.rawValue).joined(separator: "|")
        keywordsRaw = entry.keywords.joined(separator: "|")
        evidenceRaw = entry.evidence.joined(separator: "|")
        importance = entry.importance
        createdAt = entry.createdAt
    }

    var asEntry: ReflectionMemoryEntry {
        ReflectionMemoryEntry(
            id: id,
            sessionID: sessionID,
            text: text,
            summary: summary,
            topic: topic,
            dimensionHints: dimensionHintsRaw
                .split(separator: "|")
                .compactMap { ReflectionDimension(rawValue: String($0)) },
            keywords: keywordsRaw.isEmpty ? [] : keywordsRaw.split(separator: "|").map(String.init),
            evidence: evidenceRaw.isEmpty ? [] : evidenceRaw.split(separator: "|").map(String.init),
            importance: importance,
            createdAt: createdAt
        )
    }
}

private extension Date {
    var compactKoreanDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M/d"
        return formatter.string(from: self)
    }
}

private extension String {
    var nonEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

//분석 결과
@Model
final class StoredReflectionReport {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var todaySummary: String
    var refinedReflection: String
    var fourLItemsRaw: String
    var coreKeywordsRaw: String
    var emotionKeywordsRaw: String
    var actionItemsRaw: String

    init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        todaySummary: String,
        refinedReflection: String,
        fourLItemsRaw: String,
        coreKeywordsRaw: String,
        emotionKeywordsRaw: String,
        actionItemsRaw: String
    ) {
        self.id = id
        self.createdAt = createdAt
        self.todaySummary = todaySummary
        self.refinedReflection = refinedReflection
        self.fourLItemsRaw = fourLItemsRaw
        self.coreKeywordsRaw = coreKeywordsRaw
        self.emotionKeywordsRaw = emotionKeywordsRaw
        self.actionItemsRaw = actionItemsRaw
    }
}
