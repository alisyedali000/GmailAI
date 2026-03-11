//
//  AIReplyApp.swift
//  AIReply
//
//  Created by Syed Ahmad  on 05/02/2026.
//

import SwiftUI
import GoogleSignIn
import BackgroundTasks
import SDWebImageSwiftUI
import SDWebImageSVGNativeCoder

@main
struct AIReplyApp: App {
    @AppStorage("showOnboarding") var onboardingShown = false

    init() {
        SDImageCodersManager.shared.addCoder(SDImageSVGNativeCoder.shared)
        registerBackgroundRefresh()
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                Group {
                    if !onboardingShown {
                        OnboardingViewer()
                    } else {
                        ContentView()
                            .onOpenURL { url in
                                _ = GIDSignIn.sharedInstance.handle(url)
                            }
                    }
                }
            }
        }
    }

    private func registerBackgroundRefresh() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.aireply.inboxrefresh", using: nil) { task in
            task.expirationHandler = { task.setTaskCompleted(success: false) }
            Task { @MainActor in
                if let vm = GmailViewModel.currentForBackgroundSync {
                    await vm.fetchInbox(silent: true)
                    vm.scheduleBackgroundRefreshIfNeeded()
                }
                task.setTaskCompleted(success: true)
            }
        }
    }
}

enum AppState{
    case checkingSession
    case signedIn
    case signedOut
    case splash
}
