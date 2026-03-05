//
//  ReplyBottomSheet.swift
//  AIReply
//

import SwiftUI

struct ReplyBottomSheet: View {
    @ObservedObject var gmail: GmailViewModel
    @Environment(\.dismiss) private var dismiss

    let message: GmailMessage
    @ObservedObject var vm: OpenAIViewModel
    /// Called with the generated reply text when generation succeeds; parent should dismiss this sheet and present GeneratedReplySheet.
    var onReplyGenerated: ((String) -> Void)?

    @State private var notes = ""
    @State private var isGenerating = false

    private var thirdEmail: Email? {
        guard vm.generatedEmails.emails.count >= 3 else { return nil }
        return vm.generatedEmails.emails[2]
    }

    var body: some View {
        screenView
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
            .overlay {
                if isGenerating {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                        VStack(spacing: 12) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.2)
                            Text("Generating reply…")
                                .font(.subheadline)
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            .allowsHitTesting(!isGenerating)
    }
}
extension ReplyBottomSheet{
    
    var screenView: some View {
        
        VStack(alignment: .leading, spacing: 16) {
            VStack(spacing: 20){
                
                Circle()
                    .frame(width: 64)
                    .foregroundStyle(Color(hex: "#DBEAFE"))
                    .overlay {
                        Image(.magicStar)
                            .resizable()
                            .frame(width: 26.67, height: 26.67)
                    }
               
                


                Text("Add instructions to customise your reply")
                    .font(.regular(size: 13.4))
                    .foregroundStyle(Color.gray)
                
                VStack(alignment: .leading){
                    
                    Text("How would you like to reply? (Optional)")
                        .font(.semiBold(size: 15.4))
                    CustomTextEditor(text: $notes, placeholder: "e.g., Keep it brief, mention I'll need more time, sound enthusiastic...")
                }
                .padding(.top)
            }

            AppButton(title: "Generate Reply", action: {
                Task { await generateReply() }
            })
            .disabled(notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isGenerating)

            Spacer()
        }
    }

    private func generateReply() async {
        isGenerating = true
        vm.email = message.bodyPlain ?? message.snippet
        vm.userPrompt = notes
        await vm.generateEmails { }
        isGenerating = false
        if let email = thirdEmail {
            onReplyGenerated?(email.content)
        }
    }
}


#Preview {
    ReplyBottomSheet(gmail: GmailViewModel(), message: GmailMessage.mock, vm: OpenAIViewModel(), onReplyGenerated: nil)
}
