//
//  ReflectionInsightRecord.swift
//  Retrospective-Rulersalmon
//
//  Created by chaem on 6/9/26.
//

import Foundation
import SwiftData

@Model
final class ReflectionInsightRecord {
    @Attribute(.unique) var id: UUID
    var kind: String
    var title: String
    var insightDescription: String
    var count: Int
    var sourceRecordIDs: String
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        kind: String,
        title: String,
        insightDescription: String,
        count: Int,
        sourceRecordIDs: [UUID] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.insightDescription = insightDescription
        self.count = count
        self.sourceRecordIDs = sourceRecordIDs.map(\.uuidString).joined(separator: ",")
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var sourceIDs: Set<String> {
        get {
            Set(
                sourceRecordIDs
                    .split(separator: ",")
                    .map(String.init)
            )
        }
        set {
            sourceRecordIDs = newValue.sorted().joined(separator: ",")
        }
    }

    func containsSourceRecord(_ record: SentimentRecord) -> Bool {
        sourceIDs.contains(record.id.uuidString)
    }

    func addSourceRecord(_ record: SentimentRecord) {
        var ids = sourceIDs
        ids.insert(record.id.uuidString)
        sourceIDs = ids
    }

    func removeSourceRecord(_ record: SentimentRecord) {
        var ids = sourceIDs
        ids.remove(record.id.uuidString)
        sourceIDs = ids
    }
}
