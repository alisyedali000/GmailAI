//
//  GmailAPIServiceImpl.swift
//  AIReply
//

import Foundation

final class GmailAPIServiceImpl: GmailAPIServiceProtocol {

    private let network: NetworkManagerService

    init(network: NetworkManagerService = DefaultNetworkService()) {
        self.network = network
    }

    func fetchInbox(accessToken: String) async -> Result<([GmailMessage], historyId: String?), RequestError> {
        let endpoint = GmailEndpoints.listThreads(accessToken: accessToken, pageToken: nil, maxResults: 20)
        let result = await network.sendRequest(endpoint: endpoint, responseModel: GmailThreadListResponse.self)
        switch result {
        case .failure(let error):
            return .failure(error)
        case .success(let threadList):
            var fetched: [GmailMessage] = []
            for threadItem in threadList.threads ?? [] {
                let threadEndpoint = GmailEndpoints.getThread(threadId: threadItem.id, accessToken: accessToken)
                let threadResult = await network.sendRequest(endpoint: threadEndpoint, responseModel: GmailThreadResponse.self)
                if case .success(let thread) = threadResult {
                    let apiMessages = thread.messages ?? []
                    let sorted = apiMessages.sorted { ($0.internalDateMs ?? 0) < ($1.internalDateMs ?? 0) }
                    if let latest = sorted.last, let rowMessage = GmailMessage(from: latest) {
                        fetched.append(rowMessage)
                    }
                }
            }
            let profileEndpoint = GmailEndpoints.profile(accessToken: accessToken)
            let profileResult = await network.sendRequest(endpoint: profileEndpoint, responseModel: GmailProfileResponse.self)
            let historyId: String? = (try? profileResult.get()).flatMap(\.historyId)
            return .success((fetched, historyId))
        }
    }

    func fetchNewEmails(accessToken: String, startHistoryId: String) async -> Result<GmailIncrementalResult, RequestError> {
        let endpoint = GmailEndpoints.history(accessToken: accessToken, startHistoryId: startHistoryId, pageToken: nil)
        let result = await network.sendRequest(endpoint: endpoint, responseModel: GmailHistoryListResponse.self)
        switch result {
        case .failure(let error):
            return .failure(error)
        case .success(let historyResponse):
            let newIds = collectNewMessageIds(from: historyResponse)
            guard let nextHistoryId = historyResponse.historyId else {
                return .failure(.unknown)
            }
            if newIds.isEmpty {
                return .success(GmailIncrementalResult(messages: [], nextHistoryId: nextHistoryId))
            }
            var newMessages: [GmailMessage] = []
            for messageId in newIds {
                let msgEndpoint = GmailEndpoints.getMessage(messageId: messageId, accessToken: accessToken, format: "metadata")
                let msgResult = await network.sendRequest(endpoint: msgEndpoint, responseModel: GmailAPIMessage.self)
                if case .success(let apiMessage) = msgResult, let row = GmailMessage(from: apiMessage) {
                    newMessages.append(row)
                }
            }
            let byDate = newMessages.sorted { ($0.internalDate ?? .distantPast) > ($1.internalDate ?? .distantPast) }
            return .success(GmailIncrementalResult(messages: byDate, nextHistoryId: nextHistoryId))
        }
    }

    func fetchThread(threadId: String, accessToken: String) async -> Result<[GmailMessage], RequestError> {
        let endpoint = GmailEndpoints.getThread(threadId: threadId, accessToken: accessToken)
        let result = await network.sendRequest(endpoint: endpoint, responseModel: GmailThreadResponse.self)
        switch result {
        case .failure(let error):
            return .failure(error)
        case .success(let thread):
            let apiMessages = thread.messages ?? []
            let parsed = apiMessages.compactMap { GmailMessage(from: $0) }
            return .success(parsed.sorted { ($0.internalDate ?? .distantPast) < ($1.internalDate ?? .distantPast) })
        }
    }

    func sendReply(to original: GmailMessage, body: String, accessToken: String) async -> Result<Void, RequestError> {
        let mime = MessageComposer.buildReply(
            to: original.fromEmail,
            subject: original.subject,
            messageId: original.messageIdHeader,
            body: body
        )
        let encodedRaw = MessageComposer.base64URLEncode(Data(mime.utf8))
        let endpoint = GmailEndpoints.sendMessage(
            accessToken: accessToken,
            raw: encodedRaw,
            threadId: original.threadId
        )
        let result = await network.sendRequest(endpoint: endpoint, responseModel: GmailSendResponse.self)
        return result.map { _ in () }
    }

    private func collectNewMessageIds(from response: GmailHistoryListResponse) -> [String] {
        var ids: [String] = []
        var seen = Set<String>()
        for record in response.history ?? [] {
            for added in record.messagesAdded ?? [] {
                guard let id = added.message?.id, !seen.contains(id) else { continue }
                seen.insert(id)
                ids.append(id)
            }
        }
        return ids
    }
}
