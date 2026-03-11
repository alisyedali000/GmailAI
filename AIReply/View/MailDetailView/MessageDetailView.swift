//
//  MessageDetailView.swift
//  AIReply
//
//  Created by Syed Ahmad  on 07/02/2026.
//

import SwiftUI

struct MessageDetailView: View {
    @ObservedObject var gmail: GmailViewModel
    let message: GmailMessage
    @StateObject var vm = OpenAIViewModel()
    
    @State private var threadMessages: [GmailMessage] = []
//    @State private var isLoadingThread = true
    @State private var summaryText = ""
    @State private var showSummary = true
    @State private var showReplySheet = false
    @State private var showGeneratedReplySheet = false
    @State private var generatedReplyText = ""
    @State private var htmlHeights: [String: CGFloat] = [:]
    /// When non-nil, reply sheet uses this message (e.g. from per-message reply icon). When nil, big Reply uses the thread's main message.
    @State private var replyTargetMessage: GmailMessage?
    
    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = .short
        return f
    }
    
    var body: some View {
        screenView
            .padding(.horizontal)
        .sheet(isPresented: $showReplySheet) {
            NavigationStack {
                ReplyBottomSheet(gmail: gmail, message: replyTargetMessage ?? message, vm: vm) { replyText in
                    generatedReplyText = replyText
                    showReplySheet = false
                    showGeneratedReplySheet = true
                }
                .presentationDetents([.medium])
                
            }
        }
        .sheet(isPresented: $showGeneratedReplySheet) {
            NavigationStack {
                GeneratedReplySheet(gmail: gmail, vm: vm, message: message, replyContent: generatedReplyText)
                    .presentationDetents([.medium, .large])
            }
        }
        .toolbarRole(.editor)
        .task {
            await loadThread()
            let combinedContent = combinedThreadContent(threadMessages)
            vm.email = combinedContent
            await vm.generateEmailSummary {
                summaryText = vm.emailSummary.content
            }
        }
    }
    
}

extension MessageDetailView{
    
    var screenView: some View {
        
        VStack(alignment: .leading, spacing: 0) {
//            if isLoadingThread {//
//                ProgressView("Loading thread…")
//                    .frame(maxWidth: .infinity, maxHeight: .infinity)
//                    .padding()
//            } else {
            ScrollView(showsIndicators: false){
                    VStack(alignment: .leading){
                        Text(message.subject)
                            .font(.semiBold(size: 17))
                            .multilineTextAlignment(.leading)
                            .padding(.bottom)
                        
                        LazyVStack(alignment: .leading, spacing: 12) {
                            ForEach(Array(threadMessages.enumerated()), id: \.element.id) { index, msg in
                                threadBubble(msg, isFirst: index == 0)
                                
                                Divider()
                            }
                        }
                    }
                }
//            }

            
            AppButton(title: "Reply") {
                replyTargetMessage = nil
                showReplySheet = true
            }

        }
        
    }
    

    private func threadBubble(_ msg: GmailMessage, isFirst: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            
            
        
            HStack(alignment: .top) {
                SenderAvatarView(gmail: gmail, email: msg.fromEmail, displayName: msg.from, size: 44)
                VStack(alignment: .leading) {
                    Text(msg.from)
                        .font(.semiBold(size: 13.5))
                    Text(msg.fromEmail)
                        .font(.regular(size: 12.5))
                    if let date = msg.internalDate {
                        Text(dateFormatter.string(from: date))
                            .font(.regular(size: 11))
                            .foregroundColor(.secondary)
                            .padding(.top, 3)
                    }
                }
                Spacer(minLength: 8)
                Button {
                    replyTargetMessage = msg
                    showReplySheet = true
                } label: {
                    Image(.replyIcon)
                        .renderingMode(.template)
                        .rotationEffect(Angle(degrees: 90))
                        .font(.system(size: 16))
                        .foregroundColor(Color.appPrimary)
                        .padding(.horizontal)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Reply to this message")
            }

            if isFirst{
                
                summaryView(isShowing: showSummary)
            
            }
            
            if let html = msg.bodyHtml, !html.isEmpty {
                HTMLWebView(
                    html: html,
                    height: Binding(
                        get: { htmlHeights[msg.id] ?? 0 },
                        set: { htmlHeights[msg.id] = $0 }
                    )
                )
                .frame(height: htmlHeights[msg.id] ?? 0)
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
        
//        .frame(height: UIScreen.main.bounds.height)
//        .frame(maxWidth: .infinity, alignment: .leading)
//        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)

    }

    
    func summaryView(isShowing: Bool) -> some View {
        
        VStack{
            

            VStack(alignment:.leading){
                
                HStack{
                    
                    Image(.magicStar)
                    
                    Text("Show AI Summary")
                        .font(.regular(size: 12))
                    
                    Spacer()
                    
                    if vm.emailSummary.content.isEmpty{
                        
                        ProgressView()
                        
                    }else{
                        
                        Image(systemName: "chevron.down")
                            .rotationEffect(Angle(degrees: showSummary ? 180 : 0))
                    }


                }
                .onTapGesture {
                    
                    withAnimation {
                        self.showSummary.toggle()
                    }
                   
                }
         
                
                if isShowing && !vm.emailSummary.content.isEmpty{
                    
                    Text(vm.emailSummary.content)
                        .multilineTextAlignment(.leading)
                        .font(.regular(size: 12))
                    
                }
            }
            .padding()
        }.background(
            
            Rectangle()
                .foregroundStyle(Color(hex: "#EFF6FF"))
            
        )
            

            
        
        
    }
    
    private func loadThread() async {
//        isLoadingThread = true
        threadMessages = await gmail.fetchThread(threadId: message.threadId)
        if threadMessages.isEmpty {
            threadMessages = [message]
        }
//        isLoadingThread = false
    }

    /// Builds a single string of the full conversation for summary/context (oldest to newest).
    private func combinedThreadContent(_ messages: [GmailMessage]) -> String {
        guard !messages.isEmpty else { return message.bodyPlain ?? message.snippet }
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return messages.enumerated().map { index, msg in
            let dateStr = msg.internalDate.map { formatter.string(from: $0) } ?? ""
            let body = msg.bodyPlain ?? msg.snippet
            return "--- Message \(index + 1) ---\nFrom: \(msg.from)\nDate: \(dateStr)\n\n\(body)"
        }.joined(separator: "\n\n")
    }
}
#Preview {
    MessageDetailView(gmail: GmailViewModel.makeDefault(), message: GmailMessage.mock)
}
