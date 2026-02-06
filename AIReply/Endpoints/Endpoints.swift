//
//  Endpoints.swift
//  AIReply
//
//  Created by Syed Ahmad  on 06/02/2026.
//

import Foundation

// MARK: - Gmail API Endpoints

enum GmailEndpoints {
    case listThreads(accessToken: String)
    case getThread(threadId: String, accessToken: String)
    case sendMessage(accessToken: String, raw: String, threadId: String)
}

extension GmailEndpoints: Endpoint {
    var scheme: String { "https" }
    var host: String { "gmail.googleapis.com" }

    var path: String {
        switch self {
        case .listThreads:
            return "/gmail/v1/users/me/threads"
        case .getThread(let threadId, _):
            return "/gmail/v1/users/me/threads/\(threadId)"
        case .sendMessage:
            return "/gmail/v1/users/me/messages/send"
        }
    }

    var method: RequestMethod {
        switch self {
        case .listThreads, .getThread:
            return .get
        case .sendMessage:
            return .post
        }
    }

    var header: [String: String]? {
        let token: String
        switch self {
        case .listThreads(let t), .getThread(_, let t), .sendMessage(let t, _, _):
            token = t
        }
        return [
            "Authorization": "Bearer \(token)",
            "Content-Type": "application/json"
        ]
    }

    var queryItems: [URLQueryItem]? {
        switch self {
        case .listThreads:
            return [
                URLQueryItem(name: "maxResults", value: "20"),
                URLQueryItem(name: "labelIds", value: "INBOX")
            ]
        case .getThread(_, _):
            return [URLQueryItem(name: "format", value: "full")]
        case .sendMessage:
            return nil
        }
    }

    var body: [String: Any?]? {
        switch self {
        case .listThreads, .getThread:
            return nil
        case .sendMessage(_, let raw, let threadId):
            return [
                "raw": raw,
                "threadId": threadId
            ]
        }
    }
}

