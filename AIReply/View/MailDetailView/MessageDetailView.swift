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
    @State private var summaryText = ""
    @State private var showReplySheet = false

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
                Text("Summary of the email")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)

                Text(summaryText)
                    .font(.body)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)

                Button {
                    showReplySheet = true
                } label: {
                    Text("Reply")
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .padding()
            .background(Color(.systemBackground))
        }
        .sheet(isPresented: $showReplySheet) {
            ReplyBottomSheet(message: message, vm: vm)
                .environmentObject(gmail)
        }
        .navigationTitle(message.subject)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadThread()
            vm.email = message.bodyPlain ?? message.snippet
            await vm.generateEmailSummary {
                summaryText = vm.emailSummary.content
            }
        }
    }

    private func threadBubble(_ msg: GmailMessage) -> some View {
        VStack(alignment: .leading, spacing: 8) {
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

            if let html = msg.bodyHtml, !html.isEmpty {
                HTMLWebView(html: html)
                    .frame(height: UIScreen.main.bounds.height / 2)
            } else if let plain = msg.bodyPlain, !plain.isEmpty {
                Text(plain)
                    .font(.body)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Text(msg.snippet)
                    .font(.body)
                    .foregroundColor(.primary)
            }
        }
        .padding(12)
        .frame(height: UIScreen.main.bounds.height / 2)
//        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }

    private func loadThread() async {
        isLoadingThread = true
        threadMessages = await gmail.fetchThread(threadId: message.threadId)
        if threadMessages.isEmpty {
            threadMessages = [message]
        }
        isLoadingThread = false
    }
}
#Preview{
    MessageDetailView(message: GmailMessage())
}
