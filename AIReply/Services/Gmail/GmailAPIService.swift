//
//  GmailAPIService.swift
//  AIReply
//

import Foundation

/// Result of incremental fetch: new messages and the historyId to use for the next sync.
struct GmailIncrementalResult {
    let messages: [GmailMessage]
    let nextHistoryId: String
}

/// Abstraction for Gmail API operations (Single Responsibility; Dependency Inversion).
protocol GmailAPIServiceProtocol: AnyObject {
    /// Full inbox fetch (threads.list + each thread). Returns messages and the current historyId for incremental sync.
    func fetchInbox(accessToken: String) async -> Result<([GmailMessage], historyId: String?), RequestError>
    /// Fetches only new emails since startHistoryId. If startHistoryId is nil, returns .failure so caller can full fetch.
    func fetchNewEmails(accessToken: String, startHistoryId: String) async -> Result<GmailIncrementalResult, RequestError>
    /// Fetches a single thread’s messages.
    func fetchThread(threadId: String, accessToken: String) async -> Result<[GmailMessage], RequestError>
    /// Sends a reply.
    func sendReply(to original: GmailMessage, body: String, accessToken: String) async -> Result<Void, RequestError>
}
