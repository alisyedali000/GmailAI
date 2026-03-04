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
    @AppStorage("showOnboarding") var onboardingShown = false
    var body: some Scene {
        WindowGroup {
            NavigationStack{
                Group{
                    if !onboardingShown{
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
}

enum AppState{
    case checkingSession
    case signedIn
    case signedOut
    case splash
}
