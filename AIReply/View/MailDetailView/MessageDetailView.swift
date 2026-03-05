//
//  MessageDetailView.swift
//  AIReply
//
//  Created by Syed Ahmad  on 07/02/2026.
//

import SwiftUI
import SDWebImageSwiftUI

struct MessageDetailView: View {
    @ObservedObject var gmail: GmailViewModel
    let message: GmailMessage
    @StateObject var vm = OpenAIViewModel()
    
    @State private var threadMessages: [GmailMessage] = []
//    @State private var isLoadingThread = true
    @State private var summaryText = ""
    @State private var showSummary = true
    @State private var showReplySheet = false
    @State private var htmlHeights: [String: CGFloat] = [:]
    
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
            ReplyBottomSheet(gmail: gmail, message: message, vm: vm)
        }
        .toolbarRole(.editor)
        .task {
            await loadThread()
            vm.email = message.bodyPlain ?? message.snippet
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
                ScrollView {
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
                showReplySheet = true
            }

        }
        
    }
    

    private func threadBubble(_ msg: GmailMessage, isFirst: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            
            
        
            HStack(alignment: .top){
                
                WebImage(url: message.gravatarURL) { image in
                        image
                            .resizable()
    //                        .indicator(.activity)
                            .frame(width: 44, height: 44)
                            .clipShape(Circle())
                    
                } placeholder : {
                    Circle()
                        .fill(Color.secondary.opacity(0.3))
                        .frame(width: 44, height: 44)
                        .overlay {
                            Text(String(message.from.prefix(1)).uppercased())
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                }
                
                VStack(alignment: .leading){
                    
                    
                    Text(msg.from)
                        .font(.semiBold(size: 15.5))
                    
                    Text(msg.fromEmail)
                        .font(.regular(size: 13.5))
                    
                    if let date = msg.internalDate {
                        Text(dateFormatter.string(from: date))
                            .font(.regular(size: 11))
                            .foregroundColor(.secondary)
                            .padding(.top, 3)
                    }
                    
                }
                

                
        
                
                
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
}
#Preview{
    MessageDetailView(gmail: GmailViewModel(), message: GmailMessage.mock)
}
