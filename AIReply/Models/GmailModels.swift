//
//  GmailModels.swift
//  AIReply
//
//  Created by Syed Ahmad on 06/02/2026.
//

import Foundation

struct GmailListResponse: Codable {
    struct Item: Codable {
        let id: String
        let threadId: String?
    }

    let messages: [Item]?
    let nextPageToken: String?
}

/// Response from threads.list (inbox by thread, not by message).
struct GmailThreadListResponse: Codable {
    struct ThreadItem: Codable {
        let id: String
        let historyId: String?
    }

    let threads: [ThreadItem]?
    let nextPageToken: String?
}

struct GmailThreadResponse: Codable {
    let id: String?
    let messages: [GmailAPIMessage]?
}

struct GmailProfileResponse: Codable {
    let historyId: String?
    let emailAddress: String?
    let messagesTotal: Int?
    let threadsTotal: Int?
}

struct GmailHistoryMessageRef: Codable {
    let id: String?
    let threadId: String?
}

struct GmailHistoryRecord: Codable {
    let id: String?
    let messagesAdded: [GmailHistoryMessageAdded]?
    let messagesDeleted: [GmailHistoryMessageDeleted]?
}

struct GmailHistoryMessageAdded: Codable {
    let message: GmailHistoryMessageRef?
}

struct GmailHistoryMessageDeleted: Codable {
    let message: GmailHistoryMessageRef?
}

struct GmailHistoryListResponse: Codable {
    let history: [GmailHistoryRecord]?
    let nextPageToken: String?
    let historyId: String?
}

struct GmailAPIMessage: Codable {
    struct Header: Codable {
        let name: String
        let value: String
    }

    struct PayloadBody: Codable {
        let data: String?
        let attachmentId: String?
    }

    struct PayloadPart: Codable {
        let mimeType: String?
        let body: PayloadBody?
        let parts: [PayloadPart]?
    }

    struct Payload: Codable {
        let headers: [Header]?
        let body: PayloadBody?
        let parts: [PayloadPart]?
        let mimeType: String?
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

struct GmailMessage: Identifiable, Equatable {
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
    /// Full HTML body when available (for rich emails).
    let bodyHtml: String?
    /// Full plain-text body when available.
    let bodyPlain: String?

    /// Convenience initializer used for mocks and manual construction.
    init(
        id: String,
        threadId: String,
        subject: String,
        from: String,
        fromEmail: String,
        snippet: String,
        messageIdHeader: String,
        internalDate: Date?,
        isUnread: Bool,
        bodyHtml: String?,
        bodyPlain: String?
    ) {
        self.id = id
        self.threadId = threadId
        self.subject = subject
        self.from = from
        self.fromEmail = fromEmail
        self.snippet = snippet
        self.messageIdHeader = messageIdHeader
        self.internalDate = internalDate
        self.isUnread = isUnread
        self.bodyHtml = bodyHtml
        self.bodyPlain = bodyPlain
    }

    /// Inbox-style received date: today → time; this week → day; else month+date; >1yr → MM/dd/yyyy.
    var inboxReceivedDateString: String {
        guard let date = internalDate else { return "" }
        let cal = Calendar.current
        let now = Date()
        if cal.isDateInToday(date) {
            let f = DateFormatter()
            f.dateFormat = "h:mm a"
            return f.string(from: date)
        }
        if cal.isDateInYesterday(date) || cal.dateComponents([.day], from: date, to: now).day ?? 0 < 7 {
            let f = DateFormatter()
            f.dateFormat = "EEE"
            return f.string(from: date)
        }
        if cal.component(.year, from: date) == cal.component(.year, from: now) {
            let f = DateFormatter()
            f.dateFormat = "MMM d"
            return f.string(from: date)
        }
        let f = DateFormatter()
        f.dateFormat = "MM/dd/yyyy"
        return f.string(from: date)
    }

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

        let extracted = Self.extractBody(from: api.payload)
        self.bodyHtml = extracted.html
        self.bodyPlain = extracted.plain

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

    /// Extracts HTML and plain-text body from Gmail API payload.
    private static func extractBody(from payload: GmailAPIMessage.Payload) -> (html: String?, plain: String?) {
        var html: String?
        var plain: String?

        func decodeBase64URL(_ encoded: String?) -> String? {
            guard let encoded = encoded, !encoded.isEmpty else { return nil }
            var s = encoded
                .replacingOccurrences(of: "-", with: "+")
                .replacingOccurrences(of: "_", with: "/")
            let pad = s.count % 4
            if pad > 0 { s += String(repeating: "=", count: 4 - pad) }
            guard let data = Data(base64Encoded: s) else { return nil }
            return String(data: data, encoding: .utf8)
        }

        func extractFromPart(_ part: GmailAPIMessage.PayloadPart) {
            if let nested = part.parts, !nested.isEmpty {
                for p in nested { extractFromPart(p) }
                return
            }
            guard let mime = part.mimeType?.lowercased(), let bodyData = part.body?.data else { return }
            guard let decoded = decodeBase64URL(bodyData) else { return }
            if mime.contains("text/html") { html = html ?? decoded }
            else if mime.contains("text/plain") { plain = plain ?? decoded }
        }

        if let data = payload.body?.data, let decoded = decodeBase64URL(data) {
            if payload.mimeType?.lowercased().contains("text/html") == true {
                html = html ?? decoded
            } else {
                plain = plain ?? decoded
            }
        }

        for part in payload.parts ?? [] {
            extractFromPart(part)
        }

        return (html, plain)
    }
    
    init() {
        self.id = ""
        self.threadId = ""
        self.subject = ""
        self.from = ""
        self.fromEmail = ""
        self.snippet = ""
        self.messageIdHeader = ""
        self.internalDate = Date()
        self.isUnread = false
        self.bodyHtml = nil
        self.bodyPlain = nil
    }
}

// MARK: - Mock Data for Previews

extension GmailMessage {
    /// A single mock message for use in previews.
    static var mock: GmailMessage {
        GmailMessage(
            id: "mock-id-1",
            threadId: "thread-1",
            subject: "Welcome to AIReply 👋",
            from: "Ali from AIReply <ali@example.com>",
            fromEmail: "ali@example.com",
            snippet: "This is a short preview of how your inbox items will look inside the app.",
            messageIdHeader: "<mock-message-1@aireply.local>",
            internalDate: Date().addingTimeInterval(-3600),
            isUnread: true,
            bodyHtml: """
            <html>
              <body>
                <p>Hey there,</p>
                <p>This is an example HTML body used only for SwiftUI previews.</p>
                <p>It lets you see how rich emails will be rendered in the detail screen.</p>
                <p>Best,<br/>AIReply Team</p>
              </body>
            </html>
            """,
            bodyPlain: """
            Hey there,

            This is an example plain-text body used only for SwiftUI previews.

            Best,
            AIReply Team
            """
        )
    }

    /// A collection of mock inbox messages to drive the inbox preview.
    static var mockInbox: [GmailMessage] {
        [
            GmailMessage(
                id: "mock-id-1",
                threadId: "thread-1",
                subject: "Welcome to AIReply 👋",
                from: "Ali from AIReply <ali@example.com>",
                fromEmail: "ali@example.com",
                snippet: "Thanks for trying the AIReply Gmail assistant. Here’s a quick overview of what you can do…",
                messageIdHeader: "<mock-message-1@aireply.local>",
                internalDate: Date().addingTimeInterval(-3600),
                isUnread: true,
                bodyHtml: nil,
                bodyPlain: "Full welcome email body for previewing the detail screen."
            ),
            GmailMessage(
                id: "mock-id-2",
                threadId: "thread-2",
                subject: "Your weekly summary",
                from: "Reports <reports@example.com>",
                fromEmail: "reports@example.com",
                snippet: "Here’s what happened this week in your projects. You closed 12 tasks and replied to 34 emails.",
                messageIdHeader: "<mock-message-2@aireply.local>",
                internalDate: Date().addingTimeInterval(-86400 * 2),
                isUnread: false,
                bodyHtml: nil,
                bodyPlain: "Weekly summary content for preview purposes."
            ),
            GmailMessage(
                id: "mock-id-3",
                threadId: "thread-3",
                subject: "Flight booking confirmation",
                from: "Airline <no-reply@airline.com>",
                fromEmail: "no-reply@airline.com",
                snippet: "Your trip to San Francisco is confirmed. Tap to see your itinerary and boarding details.",
                messageIdHeader: "<mock-message-3@aireply.local>",
                internalDate: Date().addingTimeInterval(-86400 * 7),
                isUnread: false,
                bodyHtml: nil,
                bodyPlain: "Flight details for your upcoming trip (preview only)."
            )
        ]
    }

    /// A small thread of messages for previewing the conversation view.
    static var mockThread: [GmailMessage] {
        [
            GmailMessage(
                id: "mock-thread-id-1",
                threadId: "thread-42",
                subject: "Project kickoff details",
                from: "Client <client@example.com>",
                fromEmail: "client@example.com",
                snippet: "Looking forward to getting started. Here are a few agenda items for our kickoff call…",
                messageIdHeader: "<mock-thread-message-1@aireply.local>",
                internalDate: Date().addingTimeInterval(-86400 * 3),
                isUnread: false,
                bodyHtml: nil,
                bodyPlain: """
                Hi,

                Excited to get started on this project. For our kickoff call, let’s cover:
                - Scope & goals
                - Timeline
                - Communication channels

                Talk soon!
                """
            ),
            GmailMessage(
                id: "mock-thread-id-2",
                threadId: "thread-42",
                subject: "Re: Project kickoff details",
                from: "You <you@example.com>",
                fromEmail: "you@example.com",
                snippet: "Thanks for the details. I’ve added a few notes and will share a draft timeline shortly.",
                messageIdHeader: "<mock-thread-message-2@aireply.local>",
                internalDate: Date().addingTimeInterval(-86400 * 2),
                isUnread: false,
                bodyHtml: nil,
                bodyPlain: """
                Thanks for the outline!

                I’ll prepare a draft timeline and share it ahead of the meeting so we can review together.

                Best,
                You
                """
            )
        ]
    }
}
