import SwiftUI

struct SignInView: View {
    @EnvironmentObject var gmail: GmailService

    var body: some View {
        VStack(spacing: 24) {
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

