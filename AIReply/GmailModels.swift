import Foundation

struct GmailListResponse: Codable {
    struct Item: Codable {
        let id: String
        let threadId: String?
    }

    let messages: [Item]?
}

/// Response from threads.list (inbox by thread, not by message).
struct GmailThreadListResponse: Codable {
    struct ThreadItem: Codable {
        let id: String
        let historyId: String?
    }

    let threads: [ThreadItem]?
}

struct GmailThreadResponse: Codable {
    let id: String?
    let messages: [GmailAPIMessage]?
}

struct GmailAPIMessage: Codable {
    struct Header: Codable {
        let name: String
        let value: String
    }

    struct Payload: Codable {
        let headers: [Header]?
    }

    let id: String
    let threadId: String
    let snippet: String?
    let payload: Payload
    let labelIds: [String]?
    /// Milliseconds since epoch (Gmail API may return as string or number).
    let internalDateMs: Double?

    enum CodingKeys: String, CodingKey {
        case id, threadId, snippet, payload, labelIds
        case internalDateMs = "internalDate"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        threadId = try c.decode(String.self, forKey: .threadId)
        snippet = try c.decodeIfPresent(String.self, forKey: .snippet)
        payload = try c.decode(Payload.self, forKey: .payload)
        labelIds = try c.decodeIfPresent([String].self, forKey: .labelIds)
        if let s = try? c.decodeIfPresent(String.self, forKey: .internalDateMs), let d = Double(s) {
            internalDateMs = d
        } else if let n = try? c.decodeIfPresent(Double.self, forKey: .internalDateMs) {
            internalDateMs = n
        } else {
            internalDateMs = nil
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(threadId, forKey: .threadId)
        try c.encodeIfPresent(snippet, forKey: .snippet)
        try c.encode(payload, forKey: .payload)
        try c.encodeIfPresent(labelIds, forKey: .labelIds)
        try c.encodeIfPresent(internalDateMs, forKey: .internalDateMs)
    }
}

struct GmailMessage: Identifiable {
    let id: String
    let threadId: String
    let subject: String
    let from: String
    let fromEmail: String
    let snippet: String
    let messageIdHeader: String
    let internalDate: Date?
    /// True when the message has the UNREAD label (Gmail-style highlight in inbox).
    let isUnread: Bool

    init?(from api: GmailAPIMessage) {
        id = api.id
        threadId = api.threadId
        snippet = api.snippet ?? ""
        isUnread = api.labelIds?.contains("UNREAD") ?? false
        if let ms = api.internalDateMs {
            internalDate = Date(timeIntervalSince1970: ms / 1000)
        } else {
            internalDate = nil
        }

        guard let headers = api.payload.headers else { return nil }

        func header(_ name: String) -> String? {
            headers.first { $0.name.caseInsensitiveCompare(name) == .orderedSame }?.value
        }

        guard let subject = header("Subject"),
              let from = header("From"),
              let messageIdHeader = header("Message-ID") ?? header("Message-Id") else {
            return nil
        }

        self.subject = subject
        self.from = from
        self.messageIdHeader = messageIdHeader

        if let range = from.range(of: #"<(.+)>"#, options: .regularExpression) {
            let inner = from[range]
            fromEmail = inner
                .replacingOccurrences(of: "<", with: "")
                .replacingOccurrences(of: ">", with: "")
        } else {
            fromEmail = from
        }
    }
}

