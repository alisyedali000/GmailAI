//
//  GmailAuthService.swift
//  AIReply
//

import Foundation

/// Abstraction for Gmail authentication (Single Responsibility; Dependency Inversion).
protocol GmailAuthServiceProtocol: AnyObject {
    /// Restores the previous Google Sign-In session. Call on app launch.
    func restorePreviousSignIn() async
    /// Signs in with Google; presents UI as needed. Throws on failure.
    func signIn() async throws
    /// Signs out and clears session.
    func signOut()
    /// Current OAuth access token, or nil if not signed in.
    var currentAccessToken: String? { get }
}
