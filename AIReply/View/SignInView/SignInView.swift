//
//  SignInView.swift
//  AIReply
//
//  Created by Syed Ahmad  on 07/02/2026.
//


import SwiftUI

struct SignInView: View {
    @ObservedObject var gmail: GmailViewModel

    var body: some View {
        VStack(spacing: 24) {
            
            Text("Client ID : 930250145839-moq17pg2impku18upcrpfubo2dss7jhi.apps.googleusercontent.com")
            
            Text("Sign in to Gmail")
                .font(.title2)

            Button {
                Task { await gmail.signIn() }
            } label: {
                Text("Sign in with Google")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .padding(.horizontal, 32)
            }
        }
    }
}

#Preview {
    SignInView(gmail: GmailViewModel.makeDefault())
}
