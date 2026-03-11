//
//  GmailAuthService.swift
//  AIReply
//

import Foundation
import GoogleSignIn
import UIKit

protocol GmailAuthService {
    var isSignedIn: Bool { get }
    var accessToken: String? { get }
    func restorePreviousSignIn() async
    func signIn() async
    func signOut()
}

@MainActor
final class GoogleSignInGmailAuthService: GmailAuthService {
    private(set) var accessToken: String?
    var isSignedIn: Bool { accessToken != nil }

    init(clientID: String) {
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
    }

    func restorePreviousSignIn() async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            GIDSignIn.sharedInstance.restorePreviousSignIn { [weak self] _, error in
                Task { @MainActor in
                    if error == nil, let user = GIDSignIn.sharedInstance.currentUser {
                        self?.accessToken = user.accessToken.tokenString
                    } else {
                        self?.accessToken = nil
                    }
                    continuation.resume()
                }
            }
        }
    }

    func signIn() async {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = scene.windows.first?.rootViewController else { return }
        do {
            let scopes = [
                "https://www.googleapis.com/auth/gmail.readonly",
                "https://www.googleapis.com/auth/gmail.send",
                "https://www.googleapis.com/auth/contacts.other.readonly"
            ]
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootVC, hint: nil, additionalScopes: scopes)
            accessToken = result.user.accessToken.tokenString
        } catch {}
    }

    func signOut() {
        GIDSignIn.sharedInstance.signOut()
        accessToken = nil
    }
}
