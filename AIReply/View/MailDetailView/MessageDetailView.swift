//
//  MessageDetailView.swift
//  AIReply
//
//  Created by Syed Ahmad  on 07/02/2026.
//

import SwiftUI

struct MessageDetailView: View {
    @EnvironmentObject var gmail: GmailViewModel
    let message: GmailMessage
    @StateObject var vm = OpenAIViewModel()

    @State private var threadMessages: [GmailMessage] = []
    @State private var isLoadingThread = true
    @State private var replyText = ""
    @State private var isSending = false
    @State private var sendSuccess = false

    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = .short
        return f
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if isLoadingThread {
                ProgressView("Loading thread…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(threadMessages) { msg in
                            threadBubble(msg)
                        }
                    }
                    .padding()
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("Reply")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)

                TextEditor(text: $replyText)
                    .frame(minHeight: 80)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary.opacity(0.3))
                    )

                HStack(spacing: 12) {
                    if sendSuccess {
                        Text("Reply sent!")
                            .foregroundColor(.green)
                            .font(.subheadline)
                    }
                    Spacer()
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
                        .frame(minWidth: 120)
                        .frame(height: 44)
                        .background(canSend ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .disabled(!canSend || isSending)
                }
            }
            .padding()
            .background(Color(.systemBackground))
        }
        .navigationTitle(message.subject)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadThread()
            vm.email = self.message.snippet
            await vm.generateEmails {
                
                self.replyText = vm.generatedEmails.emails.first?.content ?? ""
                
            }
        }
    }

    private func threadBubble(_ msg: GmailMessage) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(msg.from)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                if let date = msg.internalDate {
                    Text(dateFormatter.string(from: date))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Text(msg.snippet)
                .font(.body)
                .foregroundColor(.primary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }

    private var canSend: Bool {
        !replyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func loadThread() async {
        isLoadingThread = true
        threadMessages = await gmail.fetchThread(threadId: message.threadId)
        if threadMessages.isEmpty {
            threadMessages = [message]
        }
        isLoadingThread = false
    }

    private func sendReply() async {
        guard canSend else { return }
        isSending = true
        sendSuccess = false
        await gmail.sendReply(to: message, body: replyText)
        isSending = false
        if !gmail.showError {
            sendSuccess = true
            replyText = ""
            await loadThread()
        }
    }
}
#Preview{
    MessageDetailView(message: GmailMessage())
}
