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

    func containsSourceRecord(id: UUID) -> Bool {
        sourceIDs.contains(id.uuidString)
    }

    func addSourceRecord(id: UUID) {
        var ids = sourceIDs
        ids.insert(id.uuidString)
        sourceIDs = ids
    }

    func removeSourceRecord(id: UUID) {
        var ids = sourceIDs
        ids.remove(id.uuidString)
        sourceIDs = ids
    }
}
