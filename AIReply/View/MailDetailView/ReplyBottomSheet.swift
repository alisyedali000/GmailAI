//
//  ReplyBottomSheet.swift
//  AIReply
//

import SwiftUI

struct ReplyBottomSheet: View {
    @EnvironmentObject var gmail: GmailViewModel
    @Environment(\.dismiss) private var dismiss

    let message: GmailMessage
    @ObservedObject var vm: OpenAIViewModel

    @State private var notes = ""
    @State private var isGenerating = false
    @State private var isSending = false
    @State private var sendSuccess = false

    private var thirdEmail: Email? {
        guard vm.generatedEmails.emails.count >= 3 else { return nil }
        return vm.generatedEmails.emails[2]
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Add specific notes for your reply")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)

                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.secondary.opacity(0.3))
                        )
                }

                Button {
                    Task { await generateReply() }
                } label: {
                    HStack {
                        if isGenerating {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        }
                        Text("Generate Reply")
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .disabled(notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isGenerating)

                if let email = thirdEmail {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Generated reply (Detailed)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)

                        ScrollView {
                            Text(email.content)
                                .font(.body)
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(12)
                        }
                        .frame(maxHeight: 200)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(8)
                    }
                }

                Spacer()

                if thirdEmail != nil {
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
            .padding()
            .navigationTitle("Reply")
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

    private func generateReply() async {
        isGenerating = true
        vm.email = message.bodyPlain ?? message.snippet
        vm.userPrompt = notes
        await vm.generateEmails { }
        isGenerating = false
    }

    private func sendReply() async {
        guard let email = thirdEmail else { return }
        isSending = true
        sendSuccess = false
        await gmail.sendReply(to: message, body: email.content)
        isSending = false
        if !gmail.showError {
            sendSuccess = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                dismiss()
            }
        }
    }
}
