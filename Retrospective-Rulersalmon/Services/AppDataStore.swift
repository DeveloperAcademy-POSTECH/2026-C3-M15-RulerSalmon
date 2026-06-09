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
        var calender = Calendar(identifier: .gregorian)
        calender.timeZone = .current
        
        let components = DateComponents(year: year, month: month)
        guard
            let startDate = calender.date(from: components),
            let endDate = calender.date(byAdding: .month, value: 1, to: startDate)
        else { return [] }
        
        let predicate = #Predicate<SentimentRecord> { record in
            record.createdAt >= startDate && record.createdAt < endDate
        }
        
        let descriptor = FetchDescriptor<SentimentRecord>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.createdAt)]
        )
        
        return(try? context.fetch(descriptor)) ?? []
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
        let descriptor = FetchDescriptor<StoredReflectionSession>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        let sessions = (try? context.fetch(descriptor)) ?? []

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
