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

    func loadStoredReport(id: UUID) -> StoredReflectionReport? {
        reflectionReport(for: id)
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

    private func insightRecord(for id: UUID) -> ReflectionInsightRecord? {
        let predicate = #Predicate<ReflectionInsightRecord> { $0.id == id }
        let descriptor = FetchDescriptor<ReflectionInsightRecord>(predicate: predicate)
        return try? context.fetch(descriptor).first
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

    func replaceInsights(
        with result: ReflectionInsightResult,
        scope: String,
        periodStartDate: Date,
        periodEndDate: Date,
        updatedAt: Date,
        sourceRecordIDs: [UUID]
    ) {
        allInsightRecords()
            .filter { record in
                record.scope == scope &&
                    record.updatedAt >= periodStartDate &&
                    record.updatedAt < periodEndDate
            }
            .forEach { context.delete($0) }

        result.reflectionPoints.forEach { point in
            context.insert(
                ReflectionInsightRecord(
                    kind: "reflection",
                    title: point.title,
                    insightDescription: point.description,
                    count: point.count,
                    sourceRecordIDs: sourceRecordIDs,
                    scopeRawValue: scope,
                    createdAt: updatedAt,
                    updatedAt: updatedAt
                )
            )
        }

        result.strengthPoints.forEach { point in
            context.insert(
                ReflectionInsightRecord(
                    kind: "strength",
                    title: point.title,
                    insightDescription: point.description,
                    count: point.count,
                    sourceRecordIDs: sourceRecordIDs,
                    scopeRawValue: scope,
                    createdAt: updatedAt,
                    updatedAt: updatedAt
                )
            )
        }

        #if DEBUG
        print("[Storage][SwiftData] replacing insights scope=\(scope) reflection=\(result.reflectionPoints.count) strength=\(result.strengthPoints.count) sourceRecords=\(sourceRecordIDs.count) updatedAt=\(updatedAt)")
        #endif

        saveContext(reason: "replaceInsights")
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
                    id: report.id,
                    date: report.createdAt.compactKoreanDate,
                    title: String(report.todaySummary.prefix(20)),
                    subtitle: splitKeywords(report.coreKeywordsRaw).joined(separator: ", ")
                )
            }
        }

        let sessionDescriptor = FetchDescriptor<StoredReflectionSession>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        let sessions = (try? context.fetch(sessionDescriptor)) ?? []

        return Array(sessions.prefix(limit)).map { session in
            RetrospectiveItem(
                id: session.id,
                date: session.updatedAt.compactKoreanDate,
                title: session.displayTitle,
                subtitle: nil
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
            return Self.firstRetrospectiveMessages.randomElement() ?? "오늘은 어떤 일이 있으셨는지 편하게 얘기해주세요."
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

    private static let firstRetrospectiveMessages: [String] = [
        "오늘은 어떤 일이 있으셨는지 편하게 얘기해주세요.",
        "오늘 하루에서 가장 먼저 떠오르는 장면부터 들려주세요.",
        "오늘 있었던 일 중 마음에 남은 순간을 편하게 말해주세요.",
        "오늘 하루를 돌아보면서 가장 이야기하고 싶은 일을 꺼내주세요.",
        "오늘은 어떤 흐름으로 하루가 지나갔는지 천천히 들려주세요.",
        "오늘 있었던 일 중 좋았던 점이나 아쉬웠던 점부터 편하게 말해주세요.",
        "오늘 하루를 지나며 어떤 생각이 들었는지 가볍게 이야기해주세요.",
        "오늘 겪은 일 중 가장 기억에 남는 순간부터 시작해보아요.",
        "오늘은 어떤 일이 있었는지 부담 없이 하나씩 꺼내주세요.",
        "오늘 하루를 돌아보며 지금 가장 먼저 말하고 싶은 이야기를 들려주세요."
    ]

    private func splitKeywords(_ raw: String) -> [String] {
        raw
            .split(separator: "|")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
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
