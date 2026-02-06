import Foundation
import GoogleSignIn
import UIKit

@MainActor
final class GmailService: ObservableObject {
    @Published var isSignedIn = false
    @Published var messages: [GmailMessage] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var accessToken: String? {
        didSet {
            isSignedIn = accessToken != nil
            debugPrint(accessToken ?? "")
        }
    }

    // TODO: Replace with your actual iOS OAuth client ID from Google Cloud Console.
    private let clientID = "930250145839-moq17pg2impku18upcrpfubo2dss7jhi.apps.googleusercontent.com"

    init() {
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
    }

    // MARK: - Sign in / out

    func signIn() async {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = scene.windows.first?.rootViewController else {
            errorMessage = "Unable to find root view controller."
            return
        }

        do {
            // Request Gmail scopes so the access token can call Gmail API.
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
            errorMessage = "Sign-in failed: \(error.localizedDescription)"
        }
    }

    func signOut() {
        GIDSignIn.sharedInstance.signOut()
        accessToken = nil
        messages = []
    }

    // MARK: - Gmail API

    /// Fetches inbox by thread: one row per conversation (no duplicate "Hello 2" / "Re: Hello 2").
    func fetchInbox() async {
        guard let token = accessToken else { return }

        isLoading = true
        errorMessage = nil

        do {
            let threadsURL = URL(string: "https://gmail.googleapis.com/gmail/v1/users/me/threads?maxResults=20&labelIds=INBOX")!
            var threadsRequest = URLRequest(url: threadsURL)
            threadsRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

            let (threadsData, threadsResponse) = try await URLSession.shared.data(for: threadsRequest)

            if let http = threadsResponse as? HTTPURLResponse,
               !(200..<300).contains(http.statusCode) {
                let body = String(data: threadsData, encoding: .utf8) ?? ""
                throw NSError(
                    domain: "GmailService",
                    code: http.statusCode,
                    userInfo: [NSLocalizedDescriptionKey: "HTTP \(http.statusCode): \(body)"]
                )
            }

            let threadList = try JSONDecoder().decode(GmailThreadListResponse.self, from: threadsData)
            var fetched: [GmailMessage] = []

            for threadItem in threadList.threads ?? [] {
                let threadURL = URL(string: "https://gmail.googleapis.com/gmail/v1/users/me/threads/\(threadItem.id)?format=full")!
                var threadRequest = URLRequest(url: threadURL)
                threadRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

                let (threadData, threadURLResponse) = try await URLSession.shared.data(for: threadRequest)

                if let http = threadURLResponse as? HTTPURLResponse,
                   !(200..<300).contains(http.statusCode) {
                    continue
                }

                let thread = try JSONDecoder().decode(GmailThreadResponse.self, from: threadData)
                let apiMessages = thread.messages ?? []
                let sorted = apiMessages.sorted { (a, b) in
                    (a.internalDateMs ?? 0) < (b.internalDateMs ?? 0)
                }
                guard let latest = sorted.last, let rowMessage = GmailMessage(from: latest) else { continue }
                fetched.append(rowMessage)
            }

            messages = fetched
        } catch {
            errorMessage = "Failed to load inbox: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// Fetches all messages in a thread, sorted by date (oldest first).
    func fetchThread(threadId: String) async -> [GmailMessage] {
        guard let token = accessToken else { return [] }

        do {
            let url = URL(string: "https://gmail.googleapis.com/gmail/v1/users/me/threads/\(threadId)?format=full")!
            var request = URLRequest(url: url)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

            let (data, response) = try await URLSession.shared.data(for: request)

            if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
                return []
            }

            let thread = try JSONDecoder().decode(GmailThreadResponse.self, from: data)
            let apiMessages = thread.messages ?? []
            let parsed = apiMessages.compactMap { GmailMessage(from: $0) }
            return parsed.sorted { (a, b) in
                (a.internalDate ?? .distantPast) < (b.internalDate ?? .distantPast)
            }
        } catch {
            return []
        }
    }

    func sendReply(to original: GmailMessage, body: String) async {
        guard let token = accessToken else { return }
        errorMessage = nil

        do {
            let mime = buildReplyMessage(
                to: original.fromEmail,
                subject: original.subject,
                messageId: original.messageIdHeader,
                body: body
            )

            let encodedRaw = base64URLEncode(Data(mime.utf8))

            let payload: [String: Any] = [
                "raw": encodedRaw,
                "threadId": original.threadId
            ]

            let sendURL = URL(string: "https://gmail.googleapis.com/gmail/v1/users/me/messages/send")!
            var request = URLRequest(url: sendURL)
            request.httpMethod = "POST"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])

            _ = try await URLSession.shared.data(for: request)
        } catch {
            errorMessage = "Failed to send reply: \(error.localizedDescription)"
        }
    }

    // MARK: - Helpers

    private func buildReplyMessage(to: String,
                                   subject: String,
                                   messageId: String,
                                   body: String) -> String {
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

