//
//  StoredInboxMessage.swift
//  AIReply
//

import Foundation
import SwiftData

@Model
final class StoredInboxMessage {
    @Attribute(.unique) var id: String
    var threadId: String
    var subject: String
    var from: String
    var fromEmail: String
    var snippet: String
    var messageIdHeader: String
    var internalDate: Date?
    var isUnread: Bool
    var bodyHtml: String?
    var bodyPlain: String?

    init(id: String, threadId: String, subject: String, from: String, fromEmail: String, snippet: String, messageIdHeader: String, internalDate: Date?, isUnread: Bool, bodyHtml: String?, bodyPlain: String?) {
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

    convenience init(from message: GmailMessage) {
        self.init(id: message.id, threadId: message.threadId, subject: message.subject, from: message.from, fromEmail: message.fromEmail, snippet: message.snippet, messageIdHeader: message.messageIdHeader, internalDate: message.internalDate, isUnread: message.isUnread, bodyHtml: message.bodyHtml, bodyPlain: message.bodyPlain)
    }
}

extension GmailMessage {
    init(stored: StoredInboxMessage) {
        self.init(id: stored.id, threadId: stored.threadId, subject: stored.subject, from: stored.from, fromEmail: stored.fromEmail, snippet: stored.snippet, messageIdHeader: stored.messageIdHeader, internalDate: stored.internalDate, isUnread: stored.isUnread, bodyHtml: stored.bodyHtml, bodyPlain: stored.bodyPlain)
    }
}
