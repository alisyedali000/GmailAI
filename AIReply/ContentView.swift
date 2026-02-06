//
//  ContentView.swift
//  AIReply
//
//  Created by Syed Ahmad  on 05/02/2026.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var gmail: GmailViewModel

    var body: some View {
        NavigationStack {
            Group {
                if gmail.isSignedIn {
                    InboxView()
                } else {
                    SignInView()
                }
            }
            .navigationTitle("AIReply")
            .task {
                await gmail.restorePreviousSignIn()
            }
        }
    }
}

