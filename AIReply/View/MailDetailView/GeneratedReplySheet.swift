//
//  GeneratedReplySheet.swift
//  AIReply
//

import SwiftUI

struct GeneratedReplySheet: View {
    @ObservedObject var gmail: GmailViewModel
    @Environment(\.dismiss) private var dismiss

    let message: GmailMessage
    @State var replyContent: String

    @State private var isSending = false
    @State private var sendSuccess = false

    var body: some View {
        screenView
            .padding()
            .navigationTitle("Generated Reply")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
    }
}

extension GeneratedReplySheet {

    var screenView: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Generated reply (Detailed)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)

                SelfSizingTextEditor(
                    text: $replyContent,
                    placeholder: "",
                    font: .regular(size: 15.3),
                    minHeight: 80,
                    maxHeight: 500
                )
                .cornerRadius(8)
            }

            Button {
                Task { await sendReply() }
            } label: {
                HStack {
                    if isSending {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    }
                    Text("Send Reply")
                }
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .disabled(isSending)

            if sendSuccess {
                Text("Reply sent!")
                    .foregroundColor(.green)
                    .font(.subheadline)
            }
        }
    }

    private func sendReply() async {
        isSending = true
        sendSuccess = false
        await gmail.sendReply(to: message, body: replyContent)
        isSending = false
        if !gmail.showError {
            sendSuccess = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                dismiss()
            }
        }
    }
}

#Preview {
    NavigationStack {
        GeneratedReplySheet(
            gmail: GmailViewModel(),
            message: GmailMessage.mock,
            replyContent: "Thank you for your email. I'll get back to you shortly with more details."
        )
    }
}
