//
//  GeneratedReplySheet.swift
//  AIReply
//

import SwiftUI

struct GeneratedReplySheet: View {
    @ObservedObject var gmail: GmailViewModel
    @ObservedObject var vm: OpenAIViewModel
    @Environment(\.dismiss) private var dismiss

    let message: GmailMessage
    @State var replyContent: String
    @State private var currentIndex: Int = 0
    @State private var isSending = false
    @State private var sendSuccess = false

    private var replies: [Email] {
        Array(vm.generatedEmails.emails.prefix(3))
    }

    var body: some View {
        screenView
            .padding()
            .navigationTitle("Generated Reply")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Dismiss") {
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
                HStack {

                    Spacer()
                if replies.count > 1 {
                    Button {
                        shuffleReply()
                    }label:{
      
                        Image(systemName: "shuffle")
                            .renderingMode(.template)
                            .scaleEffect(1.25)
                            .foregroundStyle(Color.appPrimary)
                        
                    }
                }
//                        .buttonStyle(.borderless)
                    }
                

                SelfSizingTextEditor(
                    text: $replyContent,
                    placeholder: "",
                    font: .regular(size: 15.3),
                    minHeight: 80,
                    maxHeight: 500
                )
                .cornerRadius(8)
            }

//            Button {
//                Task { await sendReply() }
//            } label: {
//                HStack {
//                    if isSending {
//                        Spinner()
//                    }
//                    Text("Send Reply")
//                }
//                .frame(maxWidth: .infinity)
//                .frame(height: 44)
//                .background(Color.blue)
//                .foregroundColor(.white)
//                .cornerRadius(8)
//            }
            
            AppButton(title: "Send", action: {
                Task{
                    await sendReply()
                }
            })
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

    private func shuffleReply() {
        guard !replies.isEmpty else { return }
        let count = replies.count
        currentIndex = (currentIndex + 1) % count // 0 -> 1 -> 2 -> 0 ...
        replyContent = replies[currentIndex].content
    }
}

#Preview {
    NavigationStack {
        GeneratedReplySheet(
            gmail: GmailViewModel.makeDefault(),
            vm: OpenAIViewModel(),
            message: GmailMessage.mock,
            replyContent: "Thank you for your email. I'll get back to you shortly with more details."
        )
    }
}
