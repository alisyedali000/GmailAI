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
    @State private var selectedStyle: ReplyStyle = .concise
    @State private var isSending = false
    @State private var sendSuccess = false

    private var replies: [Email] {
        Array(vm.generatedEmails.emails.prefix(3))
    }

    private var currentReplyContent: String {
        let index = selectedStyle.rawValue
        guard index < replies.count else { return replyContent }
        return replies[index].content
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
            .onChange(of: selectedStyle) { _, _ in
                replyContent = currentReplyContent
            }
            .onAppear {
                replyContent = currentReplyContent
            }
    }
}

private enum ReplyStyle: Int, CaseIterable {
    case concise = 0
    case balanced = 1
    case detailed = 2

    var title: String {
        switch self {
        case .concise: return "Concise"
        case .balanced: return "Balanced"
        case .detailed: return "Detailed"
        }
    }
}

extension GeneratedReplySheet {

    var screenView: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Picker("Reply style", selection: $selectedStyle) {
                    ForEach(ReplyStyle.allCases, id: \.rawValue) { style in
                        Text(style.title).tag(style)
                    }
                }
                .pickerStyle(.segmented)

                SelfSizingTextEditor(
                    text: $replyContent,
                    placeholder: "",
                    font: .regular(size: 15.3),
                    minHeight: 80,
                    maxHeight: 500
                )
                .cornerRadius(8)
            }

            AppButton(title: "Send", action: {
                Task {
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
