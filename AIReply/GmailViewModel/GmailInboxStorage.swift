//
//  GmailInboxStorage.swift
//  AIReply
//

import Foundation
import SwiftData

protocol GmailInboxStorage {
    func loadMessages(limit: Int) -> [GmailMessage]
    func saveMessages(_ messages: [GmailMessage], keepLatest: Int)
    func clear()
}

@MainActor
final class SwiftDataGmailInboxStorage: GmailInboxStorage {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func loadMessages(limit: Int) -> [GmailMessage] {
        var descriptor = FetchDescriptor<StoredInboxMessage>(sortBy: [SortDescriptor(\.internalDate, order: .reverse)])
        descriptor.fetchLimit = limit
        guard let stored = try? modelContext.fetch(descriptor) else { return [] }
        return stored.map { GmailMessage(stored: $0) }
    }

    func saveMessages(_ messages: [GmailMessage], keepLatest: Int) {
        let descriptor = FetchDescriptor<StoredInboxMessage>()
        let existing = (try? modelContext.fetch(descriptor)) ?? []
        for item in existing { modelContext.delete(item) }
        let sorted = messages.sorted { ($0.internalDate ?? .distantPast) > ($1.internalDate ?? .distantPast) }
        for message in Array(sorted.prefix(keepLatest)) {
            modelContext.insert(StoredInboxMessage(from: message))
        }
        try? modelContext.save()
    }

    func clear() {
        let descriptor = FetchDescriptor<StoredInboxMessage>()
        let existing = (try? modelContext.fetch(descriptor)) ?? []
        for item in existing { modelContext.delete(item) }
        try? modelContext.save()
    }
}
