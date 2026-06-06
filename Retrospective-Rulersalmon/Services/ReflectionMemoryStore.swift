//
//  ReflectionMemoryStore.swift
//  Retrospective-Rulersalmon
//
//  Created by DevPaul on 6/6/26.
//

import Foundation

final class ReflectionMemoryStore {
    private var entries: [ReflectionMemoryEntry] = []

    func append(_ entry: ReflectionMemoryEntry) {
        entries.append(entry)
    }

    func allEntries() -> [ReflectionMemoryEntry] {
        entries
    }

    func entries(in sessionID: UUID) -> [ReflectionMemoryEntry] {
        entries.filter { $0.sessionID == sessionID }
    }
}
