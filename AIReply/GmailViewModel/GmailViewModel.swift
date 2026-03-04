//
//  GmailViewModel.swift
//  AIReply
//
//  Created by Syed Ahmad  on 06/02/2026.
//


import Foundation
import GoogleSignIn
import UIKit

@MainActor
final class GmailViewModel: ViewModel {

    @Published var messages: [GmailMessage] = []
    @Published var isSignedIn = false

    /// Token from Google Sign-In session; refreshed by SDK when needed.
    private var accessToken: String? {
        didSet {
            isSignedIn = accessToken != nil
        }
    }

    private let clientID = "930250145839-moq17pg2impku18upcrpfubo2dss7jhi.apps.googleusercontent.com"

    override init() {
        super.init()
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
    }
}

    // MARK: - Sign in / out

extension GmailViewModel: NetworkManagerService {

    /// Restores the previous Google Sign-In session. Call on app launch.
    func restorePreviousSignIn() async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            GIDSignIn.sharedInstance.restorePreviousSignIn { [weak self] _, error in
                Task { @MainActor in
                    if error == nil, let user = GIDSignIn.sharedInstance.currentUser {
                        self?.accessToken = user.accessToken.tokenString
                    }
                    continuation.resume()
                }
            }
        }
    }

    func signIn() async {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = scene.windows.first?.rootViewController else {
            showAlert(message: "Unable to find root view controller.")
            return
        }

        do {
            let scopes = [
                "https://www.googleapis.com/auth/gmail.readonly",
                "https://www.googleapis.com/auth/gmail.send"
            ]
            let result = try await GIDSignIn.sharedInstance.signIn(
                withPresenting: rootVC,
                hint: nil,
                additionalScopes: scopes
            )
            accessToken = result.user.accessToken.tokenString
        } catch {
            showAlert(message: "Sign-in failed: \(error.localizedDescription)")
        }
    }

    func signOut() {
        GIDSignIn.sharedInstance.signOut()
        accessToken = nil
        messages = []
    }

    // MARK: - Gmail API (via NetworkManagerService)

    func fetchInbox() async {
        guard let token = accessToken else { return }

        showLoader = true
        errorMessage = ""

        let endpoint = GmailEndpoints.listThreads(accessToken: token)
        let result = await sendRequest(endpoint: endpoint, responseModel: GmailThreadListResponse.self)

        switch result {
        case .success(let threadList):
            var fetched: [GmailMessage] = []
            for threadItem in threadList.threads ?? [] {
                let threadEndpoint = GmailEndpoints.getThread(threadId: threadItem.id, accessToken: token)
                let threadResult = await sendRequest(endpoint: threadEndpoint, responseModel: GmailThreadResponse.self)
                if case .success(let thread) = threadResult {
                    let apiMessages = thread.messages ?? []
                    let sorted = apiMessages.sorted { ($0.internalDateMs ?? 0) < ($1.internalDateMs ?? 0) }
                    if let latest = sorted.last, let rowMessage = GmailMessage(from: latest) {
                        fetched.append(rowMessage)
                    }
                }
            }
            messages = fetched

        case .failure(let error):
            showAlert(message: error.customMessage)
        }

        showLoader = false
    }

    func fetchThread(threadId: String) async -> [GmailMessage] {
        guard let token = accessToken else { return [] }

        let endpoint = GmailEndpoints.getThread(threadId: threadId, accessToken: token)
        let result = await sendRequest(endpoint: endpoint, responseModel: GmailThreadResponse.self)

        switch result {
        case .success(let thread):
            let apiMessages = thread.messages ?? []
            let parsed = apiMessages.compactMap { GmailMessage(from: $0) }
            return parsed.sorted { ($0.internalDate ?? .distantPast) < ($1.internalDate ?? .distantPast) }
        case .failure:
            return []
        }
    }

    func sendReply(to original: GmailMessage, body: String) async {
        guard let token = accessToken else { return }

        let mime = buildReplyMessage(
            to: original.fromEmail,
            subject: original.subject,
            messageId: original.messageIdHeader,
            body: body
        )
        let encodedRaw = base64URLEncode(Data(mime.utf8))

        let endpoint = GmailEndpoints.sendMessage(accessToken: token, raw: encodedRaw, threadId: original.threadId)
        let result = await sendRequest(endpoint: endpoint, responseModel: GmailSendResponse.self)

        switch result {
        case .success:
            break
        case .failure(let error):
            showAlert(message: error.customMessage)
        }
    }

    // MARK: - Helpers

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
        encoded = encoded
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        return encoded
    }
}

/// Gmail API send response (id, threadId, etc.) - we only need decode success.
struct GmailSendResponse: Codable {
    let id: String?
    let threadId: String?
}


let dummyMails: [GmailMessage] = [
    GmailMessage(
        id: "1",
        threadId: "t1",
        subject: "Welcome to AIReply 🚀",
        from: "Google Team <no-reply@google.com>",
        fromEmail: "no-reply@google.com",
        snippet: "Thanks for signing up to AIReply. We're excited to have you on board!",
        messageIdHeader: "<msg1@google.com>",
        internalDate: Date(),
        isUnread: true,
        bodyHtml: "<h1>Welcome!</h1><p>Thanks for signing up to <b>AIReply</b>.</p>",
        bodyPlain: "Welcome!\n\nThanks for signing up to AIReply."
    ),
    
    GmailMessage(
        id: "2",
        threadId: "t2",
        subject: "Your Weekly Report",
        from: "GitHub <notifications@github.com>",
        fromEmail: "notifications@github.com",
        snippet: "Here’s what happened across your repositories this week.",
        messageIdHeader: "<msg2@github.com>",
        internalDate: Calendar.current.date(byAdding: .day, value: -1, to: Date()),
        isUnread: false,
        bodyHtml: nil,
        bodyPlain: "Your repositories had 5 new commits and 2 pull requests."
    ),
    
    GmailMessage(
        id: "3",
        threadId: "t3",
        subject: "Meeting Reminder",
        from: "John Appleseed <john@company.com>",
        fromEmail: "john@company.com",
        snippet: "Reminder about tomorrow’s product sync at 10 AM.",
        messageIdHeader: "<msg3@company.com>",
        internalDate: Calendar.current.date(byAdding: .day, value: -3, to: Date()),
        isUnread: true,
        bodyHtml: nil,
        bodyPlain: "Hi,\n\nJust a reminder about tomorrow’s product sync at 10 AM.\n\nBest,\nJohn"
    ),
    
    GmailMessage(
        id: "4",
        threadId: "t4",
        subject: "Invoice for February",
        from: "Stripe Billing <billing@stripe.com>",
        fromEmail: "billing@stripe.com",
        snippet: "Your invoice for February is now available.",
        messageIdHeader: "<msg4@stripe.com>",
        internalDate: Calendar.current.date(byAdding: .month, value: -2, to: Date()),
        isUnread: false,
        bodyHtml: "<p>Your invoice total is <b>$49.00</b>.</p>",
        bodyPlain: "Your invoice total is $49.00."
    ),
    
    GmailMessage(
        id: "5",
        threadId: "t5",
        subject: "Happy New Year! 🎉",
        from: "Jane Doe <jane@example.com>",
        fromEmail: "jane@example.com",
        snippet: "Wishing you a fantastic year ahead filled with success.",
        messageIdHeader: "<msg5@example.com>",
        internalDate: Calendar.current.date(byAdding: .year, value: -1, to: Date()),
        isUnread: false,
        bodyHtml: nil,
        bodyPlain: "Happy New Year!\n\nWishing you a fantastic year ahead."
    )
]
