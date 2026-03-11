//
//  GmailUseCases.swift
//  AIReply
//

import Foundation

protocol GmailHistoryIdStorage {
    func getHistoryId() -> String?
    func saveHistoryId(_ id: String)
    func clearHistoryId()
}

final class UserDefaultsGmailHistoryIdStorage: GmailHistoryIdStorage {
    private let key = "gmail_last_history_id"
    func getHistoryId() -> String? {
        let v = UserDefaults.standard.string(forKey: key)
        return (v?.isEmpty == true) ? nil : v
    }
    func saveHistoryId(_ id: String) { UserDefaults.standard.set(id, forKey: key) }
    func clearHistoryId() { UserDefaults.standard.removeObject(forKey: key) }
}

protocol GmailInboxPageTokenStorage {
    func getNextPageToken() -> String?
    func saveNextPageToken(_ token: String?)
    func clearNextPageToken()
}

final class UserDefaultsGmailInboxPageTokenStorage: GmailInboxPageTokenStorage {
    private let key = "gmail_inbox_next_page_token"
    func getNextPageToken() -> String? {
        let v = UserDefaults.standard.string(forKey: key)
        return (v?.isEmpty == true) ? nil : v
    }
    func saveNextPageToken(_ token: String?) {
        if let t = token, !t.isEmpty { UserDefaults.standard.set(t, forKey: key) }
        else { UserDefaults.standard.removeObject(forKey: key) }
    }
    func clearNextPageToken() { UserDefaults.standard.removeObject(forKey: key) }
}

let kInboxStorageLimit = 20

protocol FetchInboxUseCase {
    func loadFromStorage(limit: Int) -> [GmailMessage]
    /// Pass currentNextPageToken so it can be returned on delta refresh (keeps pagination working after relaunch).
    /// Pass existingMessages when the ViewModel already has a list (e.g. after load more or when navigating back) so the refresh merges into it instead of replacing with only the first page.
    func execute(currentNextPageToken: String?, existingMessages: [GmailMessage]?) async -> Result<(messages: [GmailMessage], nextPageToken: String?), RequestError>
}

@MainActor
final class DefaultFetchInboxUseCase: FetchInboxUseCase {
    private let repository: GmailRepository
    private let authService: GmailAuthService
    private let historyIdStorage: GmailHistoryIdStorage
    private let inboxStorage: GmailInboxStorage

    init(repository: GmailRepository, authService: GmailAuthService, historyIdStorage: GmailHistoryIdStorage, inboxStorage: GmailInboxStorage) {
        self.repository = repository
        self.authService = authService
        self.historyIdStorage = historyIdStorage
        self.inboxStorage = inboxStorage
    }

    func loadFromStorage(limit: Int) -> [GmailMessage] {
        inboxStorage.loadMessages(limit: limit)
    }

    func execute(currentNextPageToken: String?, existingMessages: [GmailMessage]?) async -> Result<(messages: [GmailMessage], nextPageToken: String?), RequestError> {
        guard let token = authService.accessToken else { return .failure(.unauthorized(reason: "Missing access token")) }
        let cached: [GmailMessage]
        let useExistingAsCache: Bool
        if let existing = existingMessages, !existing.isEmpty {
            cached = existing
            useExistingAsCache = true
        } else {
            cached = inboxStorage.loadMessages(limit: kInboxStorageLimit)
            useExistingAsCache = false
        }
        let storedHistoryId = historyIdStorage.getHistoryId()
        if !cached.isEmpty, let startHistoryId = storedHistoryId {
            let result = await repository.fetchHistorySince(token: token, startHistoryId: startHistoryId)
            if case .success(let delta) = result {
                historyIdStorage.saveHistoryId(delta.newHistoryId)
                var byThread = Dictionary(
                    cached.lazy.map { ($0.threadId, $0) },
                    uniquingKeysWith: { existing, incoming in
                        let existingDate = existing.internalDate ?? .distantPast
                        let incomingDate = incoming.internalDate ?? .distantPast
                        return incomingDate > existingDate ? incoming : existing
                    }
                )
                for tid in delta.removedThreadIds { byThread.removeValue(forKey: tid) }
                for message in delta.added { byThread[message.threadId] = message }
                let merged = byThread.values.sorted { ($0.internalDate ?? .distantPast) > ($1.internalDate ?? .distantPast) }
                let toKeep: [GmailMessage]
                if useExistingAsCache {
                    toKeep = Array(merged)
                } else {
                    toKeep = Array(merged.prefix(kInboxStorageLimit))
                }
                let saveLimit = min(max(toKeep.count, kInboxStorageLimit), 100)
                inboxStorage.saveMessages(toKeep, keepLatest: saveLimit)
                return .success((messages: toKeep, nextPageToken: currentNextPageToken))
            }
        }
        let fullResult = await repository.fetchInbox(token: token, pageToken: nil, maxResults: kInboxStorageLimit)
        switch fullResult {
        case .success(let page):
            if case .success(let profile) = await repository.getProfile(token: token), let historyId = profile.historyId {
                historyIdStorage.saveHistoryId(historyId)
            }
            let toKeep: [GmailMessage]
            if useExistingAsCache, !cached.isEmpty {
                var byId = Dictionary(uniqueKeysWithValues: cached.lazy.map { ($0.id, $0) })
                for message in page.messages {
                    byId[message.id] = message
                }
                toKeep = byId.values.sorted { ($0.internalDate ?? .distantPast) > ($1.internalDate ?? .distantPast) }
            } else {
                toKeep = Array(page.messages.prefix(kInboxStorageLimit))
            }
            let saveLimit = min(max(toKeep.count, kInboxStorageLimit), 100)
            inboxStorage.saveMessages(toKeep, keepLatest: saveLimit)
            let nextToken = useExistingAsCache ? currentNextPageToken : page.nextPageToken
            return .success((messages: toKeep, nextPageToken: nextToken))
        case .failure(let error):
            return .failure(error)
        }
    }
}

protocol LoadMoreInboxUseCase {
    func execute(pageToken: String) async -> Result<(messages: [GmailMessage], nextPageToken: String?), RequestError>
}

@MainActor
final class DefaultLoadMoreInboxUseCase: LoadMoreInboxUseCase {
    private let repository: GmailRepository
    private let authService: GmailAuthService
    init(repository: GmailRepository, authService: GmailAuthService) {
        self.repository = repository
        self.authService = authService
    }
    func execute(pageToken: String) async -> Result<(messages: [GmailMessage], nextPageToken: String?), RequestError> {
        guard let token = authService.accessToken else { return .failure(.unauthorized(reason: "Missing access token")) }
        return await repository.fetchInbox(token: token, pageToken: pageToken, maxResults: 20)
    }
}

protocol FetchThreadUseCase {
    func execute(threadId: String) async -> Result<[GmailMessage], RequestError>
}

final class DefaultFetchThreadUseCase: FetchThreadUseCase {
    private let repository: GmailRepository
    private let authService: GmailAuthService
    init(repository: GmailRepository, authService: GmailAuthService) {
        self.repository = repository
        self.authService = authService
    }
    func execute(threadId: String) async -> Result<[GmailMessage], RequestError> {
        guard let token = authService.accessToken else { return .failure(.unauthorized(reason: "Missing access token")) }
        return await repository.fetchThread(threadId: threadId, token: token)
    }
}

protocol SendReplyUseCase {
    func execute(original: GmailMessage, body: String) async -> Result<Void, RequestError>
}

final class DefaultSendReplyUseCase: SendReplyUseCase {
    private let repository: GmailRepository
    private let authService: GmailAuthService
    init(repository: GmailRepository, authService: GmailAuthService) {
        self.repository = repository
        self.authService = authService
    }
    func execute(original: GmailMessage, body: String) async -> Result<Void, RequestError> {
        guard let token = authService.accessToken else { return .failure(.unauthorized(reason: "Missing access token")) }
        return await repository.sendReply(to: original, body: body, token: token)
    }
}
