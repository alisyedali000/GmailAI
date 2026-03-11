//
//  GmailAuthServiceImpl.swift
//  AIReply
//

import Foundation
import GoogleSignIn
import UIKit

final class GmailAuthServiceImpl: GmailAuthServiceProtocol {

    private let clientID: String
    private var _accessToken: String?

    var currentAccessToken: String? { _accessToken }

    init(clientID: String = "930250145839-moq17pg2impku18upcrpfubo2dss7jhi.apps.googleusercontent.com") {
        self.clientID = clientID
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
    }

    func restorePreviousSignIn() async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            GIDSignIn.sharedInstance.restorePreviousSignIn { [weak self] _, error in
                Task { @MainActor in
                    if error == nil, let user = GIDSignIn.sharedInstance.currentUser {
                        self?._accessToken = user.accessToken.tokenString
                    }
                    continuation.resume()
                }
            }
        }
    }

    func signIn() async throws {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = scene.windows.first?.rootViewController else {
            return
        }
        let scopes = [
            "https://www.googleapis.com/auth/gmail.readonly",
            "https://www.googleapis.com/auth/gmail.send"
        ]
        do {
            let result = try await GIDSignIn.sharedInstance.signIn(
                withPresenting: rootVC,
                hint: nil,
                additionalScopes: scopes
            )
            _accessToken = result.user.accessToken.tokenString
        } catch {
            throw error
        }
    }

    func signOut() {
        GIDSignIn.sharedInstance.signOut()
        _accessToken = nil
    }
}
