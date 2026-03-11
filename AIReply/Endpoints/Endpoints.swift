//
//  Endpoints.swift
//  AIReply
//
//  Created by Syed Ahmad  on 06/02/2026.
//

import Foundation

// MARK: - Gmail API Endpoints

enum GmailEndpoints {
    case listThreads(accessToken: String, pageToken: String?, maxResults: Int)
    case listMessages(accessToken: String, pageToken: String?, maxResults: Int)
    case getThread(threadId: String, accessToken: String)
    case getMessage(messageId: String, accessToken: String, format: String)
    case sendMessage(accessToken: String, raw: String, threadId: String)
    case profile(accessToken: String)
    case history(accessToken: String, startHistoryId: String, pageToken: String?)
}

extension GmailEndpoints: Endpoint {
    var scheme: String { "https" }
    var host: String { "gmail.googleapis.com" }

    var path: String {
        switch self {
        case .listThreads:
            return "/gmail/v1/users/me/threads"
        case .listMessages:
            return "/gmail/v1/users/me/messages"
        case .getThread(let threadId, _):
            return "/gmail/v1/users/me/threads/\(threadId)"
        case .getMessage(let messageId, _, _):
            return "/gmail/v1/users/me/messages/\(messageId)"
        case .sendMessage:
            return "/gmail/v1/users/me/messages/send"
        case .profile:
            return "/gmail/v1/users/me/profile"
        case .history:
            return "/gmail/v1/users/me/history"
        }
    }

    var method: RequestMethod {
        switch self {
        case .listThreads, .listMessages, .getThread, .getMessage, .profile, .history:
            return .get
        case .sendMessage:
            return .post
        }
    }

    var header: [String: String]? {
        let token: String
        switch self {
        case .listThreads(let t, _, _), .listMessages(let t, _, _), .getThread(_, let t), .getMessage(_, let t, _), .sendMessage(let t, _, _), .profile(let t), .history(let t, _, _):
            token = t
        }
        return [
            "Authorization": "Bearer \(token)",
            "Content-Type": "application/json"
        ]
    }

    var queryItems: [URLQueryItem]? {
        switch self {
        case .listThreads(_, let pageToken, let maxResults):
            var items = [
                URLQueryItem(name: "maxResults", value: String(maxResults)),
                URLQueryItem(name: "labelIds", value: "INBOX")
            ]
            if let t = pageToken, !t.isEmpty { items.append(URLQueryItem(name: "pageToken", value: t)) }
            return items
        case .listMessages(_, let pageToken, let maxResults):
            var items = [
                URLQueryItem(name: "maxResults", value: String(maxResults)),
                URLQueryItem(name: "labelIds", value: "INBOX")
            ]
            if let t = pageToken, !t.isEmpty { items.append(URLQueryItem(name: "pageToken", value: t)) }
            return items
        case .getThread(_, _):
            return [URLQueryItem(name: "format", value: "full")]
        case .getMessage(_, _, let format):
            return [URLQueryItem(name: "format", value: format)]
        case .sendMessage, .profile:
            return nil
        case .history(_, let startHistoryId, let pageToken):
            var items = [
                URLQueryItem(name: "startHistoryId", value: startHistoryId),
                URLQueryItem(name: "labelIds", value: "INBOX"),
                URLQueryItem(name: "maxResults", value: "100")
            ]
            if let t = pageToken, !t.isEmpty { items.append(URLQueryItem(name: "pageToken", value: t)) }
            return items
        }
    }

    var body: [String: Any?]? {
        switch self {
        case .listThreads, .listMessages, .getThread, .getMessage, .profile, .history:
            return nil
        case .sendMessage(_, let raw, let threadId):
            return [
                "raw": raw,
                "threadId": threadId
            ]
        }
    }
}

