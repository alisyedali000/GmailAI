//
//  ContentView.swift
//  AIReply
//
//  Created by Syed Ahmad  on 05/02/2026.
//

import SwiftUI

struct ContentView: View {
    @StateObject var gmail = GmailViewModel.makeDefault()
//    @State var status : AppState = .
    @State private var checkingSession = true

    var body: some View {
//        NavigationStack {x
            Group {
                if checkingSession{
                    Spinner()
                } else if gmail.isSignedIn {
                    InboxView(gmail: gmail)
                } else {
                    SignInView(gmail: gmail)
                }
            }
            .task {
                await gmail.restorePreviousSignIn()
                self.checkingSession = false
            }
        
    }
}
