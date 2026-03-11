//
//  GmailRepository.swift
//  AIReply
//

import Foundation

protocol GmailRepository {
    func fetchInbox(token: String, pageToken: String?, maxResults: Int) async -> Result<(messages: [GmailMessage], nextPageToken: String?), RequestError>
    func fetchThread(threadId: String, token: String) async -> Result<[GmailMessage], RequestError>
    func sendReply(to original: GmailMessage, body: String, token: String) async -> Result<Void, RequestError>
    func getProfile(token: String) async -> Result<GmailProfileResponse, RequestError>
    func fetchHistorySince(token: String, startHistoryId: String) async -> Result<(added: [GmailMessage], removedThreadIds: [String], newHistoryId: String), RequestError>
}

final class DefaultGmailRepository: GmailRepository, NetworkManagerService {
    /// Fetches inbox list using messages.list + getMessage(metadata) so full thread bodies are never loaded until the user opens a thread.
    func fetchInbox(token: String, pageToken: String?, maxResults: Int) async -> Result<(messages: [GmailMessage], nextPageToken: String?), RequestError> {
        let listEndpoint = GmailEndpoints.listMessages(accessToken: token, pageToken: pageToken, maxResults: maxResults)
        let listResult = await sendRequest(endpoint: listEndpoint, responseModel: GmailListResponse.self)
        guard case .success(let list) = listResult else {
            if case .failure(let err) = listResult { return .failure(err) }
            return .failure(.unknown)
        }
        let messageRefs = list.messages ?? []
        if messageRefs.isEmpty {
            return .success((messages: [], nextPageToken: list.nextPageToken))
        }
        var fetched: [GmailMessage] = []
        for ref in messageRefs {
            let msgEndpoint = GmailEndpoints.getMessage(messageId: ref.id, accessToken: token, format: "metadata")
            let msgResult = await sendRequest(endpoint: msgEndpoint, responseModel: GmailAPIMessage.self)
            if case .success(let apiMsg) = msgResult, let row = GmailMessage(from: apiMsg) {
                fetched.append(row)
            }
        }
        return .success((messages: fetched, nextPageToken: list.nextPageToken))
    }

    func fetchThread(threadId: String, token: String) async -> Result<[GmailMessage], RequestError> {
        let endpoint = GmailEndpoints.getThread(threadId: threadId, accessToken: token)
        let result = await sendRequest(endpoint: endpoint, responseModel: GmailThreadResponse.self)
        switch result {
        case .success(let thread):
            let apiMessages = thread.messages ?? []
            let parsed = apiMessages.compactMap { GmailMessage(from: $0) }
            return .success(parsed.sorted { ($0.internalDate ?? .distantPast) < ($1.internalDate ?? .distantPast) })
        case .failure(let error):
            return .failure(error)
        }
    }

    func sendReply(to original: GmailMessage, body: String, token: String) async -> Result<Void, RequestError> {
        let mime = buildReplyMessage(to: original.fromEmail, subject: original.subject, messageId: original.messageIdHeader, body: body)
        let encodedRaw = base64URLEncode(Data(mime.utf8))
        let endpoint = GmailEndpoints.sendMessage(accessToken: token, raw: encodedRaw, threadId: original.threadId)
        let result = await sendRequest(endpoint: endpoint, responseModel: GmailSendResponse.self)
        switch result {
        case .success: return .success(())
        case .failure(let error): return .failure(error)
        }
    }

    func getProfile(token: String) async -> Result<GmailProfileResponse, RequestError> {
        let endpoint = GmailEndpoints.profile(accessToken: token)
        return await sendRequest(endpoint: endpoint, responseModel: GmailProfileResponse.self)
    }

    func fetchHistorySince(token: String, startHistoryId: String) async -> Result<(added: [GmailMessage], removedThreadIds: [String], newHistoryId: String), RequestError> {
        var addedMessageRefs: [(id: String, threadId: String)] = []
        var removedThreadIds = Set<String>()
        var pageToken: String?
        var lastHistoryId = startHistoryId
        repeat {
            let endpoint = GmailEndpoints.history(accessToken: token, startHistoryId: startHistoryId, pageToken: pageToken)
            let result = await sendRequest(endpoint: endpoint, responseModel: GmailHistoryListResponse.self)
            switch result {
            case .success(let list):
                lastHistoryId = list.historyId ?? lastHistoryId
                for record in list.history ?? [] {
                    for item in record.messagesAdded ?? [] {
                        if let mid = item.message?.id, let tid = item.message?.threadId, !mid.isEmpty, !tid.isEmpty {
                            addedMessageRefs.append((id: mid, threadId: tid))
                        }
                    }
                    for item in record.messagesDeleted ?? [] {
                        if let tid = item.message?.threadId, !tid.isEmpty { removedThreadIds.insert(tid) }
                    }
                }
                pageToken = list.nextPageToken
            case .failure(let error):
                return .failure(error)
            }
        } while pageToken != nil
        var addedByThread: [String: GmailMessage] = [:]
        for ref in addedMessageRefs {
            let msgEndpoint = GmailEndpoints.getMessage(messageId: ref.id, accessToken: token, format: "metadata")
            let msgResult = await sendRequest(endpoint: msgEndpoint, responseModel: GmailAPIMessage.self)
            if case .success(let apiMsg) = msgResult, let row = GmailMessage(from: apiMsg) {
                let tid = row.threadId
                if let existing = addedByThread[tid] {
                    let existingDate = existing.internalDate ?? .distantPast
                    let newDate = row.internalDate ?? .distantPast
                    if newDate > existingDate { addedByThread[tid] = row }
                } else {
                    addedByThread[tid] = row
                }
            }
        }
        return .success((added: Array(addedByThread.values), removedThreadIds: Array(removedThreadIds), newHistoryId: lastHistoryId))
    }

    private func buildReplyMessage(to: String, subject: String, messageId: String, body: String) -> String {
        """
        To: \(to)
        Subject: Re: \(subject)
        In-Reply-To: \(messageId)
        References: \(messageId)
        Content-Type: text/plain; charset=utf-8

        \(body)
        """
    }

    private func base64URLEncode(_ data: Data) -> String {
        var encoded = data.base64EncodedString()
        encoded = encoded.replacingOccurrences(of: "+", with: "-").replacingOccurrences(of: "/", with: "_").replacingOccurrences(of: "=", with: "")
        return encoded
    }
}

struct GmailSendResponse: Codable {
    let id: String?
    let threadId: String?
}
