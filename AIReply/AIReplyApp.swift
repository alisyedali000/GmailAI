//
//  AIReplyApp.swift
//  AIReply
//
//  Created by Syed Ahmad  on 05/02/2026.
//

import SwiftUI
import GoogleSignIn

@main
struct AIReplyApp: App {
    @StateObject private var gmailService = GmailService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(gmailService)
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
}
