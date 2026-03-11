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
    @StateObject private var speechRecognizer = SpeechRecognizer()

    private var emails: [Email] { vm.generatedEmails.emails }

    var body: some View {
        screenView
            .padding()
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .overlay {
                if isGenerating {
                    ZStack {
                        Color.black.opacity(0.2)
                            .ignoresSafeArea()
                        VStack(spacing: 12) {
                            
                            Spinner()
                            
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
                
                VStack(alignment: .leading, spacing: 8){

                    Text("How would you like to reply? (Optional)")
                        .font(.semiBold(size: 15.4))
                    
                    ZStack(alignment: .bottomTrailing){
                        
                        CustomTextEditor(
                            text: $notes,
                            placeholder: "e.g., Keep it brief, mention I'll need more time, sound enthusiastic..."
                        )
                        
                        voicePromptButton
                            .padding()
                    }
                        
                

                    
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
        if let first = emails.first {
            onReplyGenerated?(first.content)
        }
    }

    private func toggleRecording() {
        speechRecognizer.toggleRecording { transcript in
            // Append the latest transcript to existing notes in a lightweight way.
            let trimmed = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return }
            if notes.isEmpty {
                notes = trimmed
            } else {
                // Overwrite with the latest full transcript to avoid duplication.
                notes = trimmed
            }
        }
    }

    var voicePromptButton: some View {
        Button(action: toggleRecording) {
            VoiceBarsView(isActive: speechRecognizer.isRecording)
                .frame(width: 40, height: 28)
        }
        .accessibilityLabel("Voice instructions")
    }
}

/// Animated audio-style bars used for voice prompting.
private struct VoiceBarsView: View {
    let isActive: Bool
    @State private var levels: [CGFloat] = [0.2, 0.6, 1.0, 0.6, 0.2]

    private let timer = Timer.publish(every: 0.18, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: 4) {
            ForEach(levels.indices, id: \.self) { index in
                Capsule()
                    .fill(isActive ? Color.blue : Color.secondary)
                    .frame(width: 3, height: barHeight(for: levels[index]))
            }
        }
        .onReceive(timer) { _ in
            guard isActive else {
                withAnimation(.easeOut(duration: 0.2)) {
                    levels = [0.2, 0.4, 0.6, 0.4, 0.2]
                }
                return
            }
            withAnimation(.easeInOut(duration: 0.18)) {
                levels = levels.indices.map { i in
                    // Middle bars a bit higher, edges smaller.
                    let base: CGFloat = (i == 2) ? 1.0 : (i == 1 || i == 3 ? 0.8 : 0.6)
                    return base * CGFloat.random(in: 0.4...1.0)
                }
            }
        }
    }

    private func barHeight(for level: CGFloat) -> CGFloat {
        let minH: CGFloat = 8
        let maxH: CGFloat = 24
        return minH + (maxH - minH) * max(0, min(level, 1))
    }
}


#Preview {
    ReplyBottomSheet(gmail: GmailViewModel.makeDefault(), message: GmailMessage.mock, vm: OpenAIViewModel(), onReplyGenerated: nil)
}
