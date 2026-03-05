//
//  InboxView.swift
//  AIReply
//
//  Created by Syed Ahmad on 06/02/2026.
//

import SwiftUI
import SDWebImageSwiftUI

struct InboxView: View {
    @ObservedObject var gmail: GmailViewModel
    @State private var searchText: String = ""
    
    var body: some View {
        screenView

//            .toolbar {
//                ToolbarItem(placement: .navigationBarLeading) {
//                    Button {
//                        Task { await gmail.fetchInbox() }
//                    } label: {
//                        Image(systemName: "arrow.clockwise")
//                    }
//                }
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    Button("Sign out") {
//                        gmail.signOut()
//                    }
//                }
//            }
            .task {
                await gmail.fetchInbox()
            }
            .alert(isPresented: Binding(
                get: { gmail.showError },
                set: { _ in gmail.showError = false; gmail.errorMessage = "" }
            )) {
                Alert(
                    title: Text("Error"),
                    message: Text(gmail.errorMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
    }
}
extension InboxView{
    
    var screenView: some View{
        
        VStack{
            
            HStack{
                
                Text("Inbox")
                    .font(.semiBold(size: 24))
                
                Spacer()
                
                Button{
                    
                }label:{
                    
                    Image(.threeBars)
                    
                }
                
                
            }
            .padding(.horizontal)
            
            SearchBar(query: $searchText, placeholder: "Search in mails")
                .padding(.horizontal)
        
            List {
                ForEach(filteredMessages) { message in
                    NavigationLink {
                        MessageDetailView(gmail: gmail, message: message)
                    } label: {
                        inboxRow(message)
                    }
                    .listRowBackground(message.isUnread ? Color.accentColor.opacity(0.08) : Color.clear)
                }
            }
            .listStyle(.plain)
            .overlay {
                if gmail.showLoader {
                    ProgressView("Loading inbox…")
                }
            }
        }

        
    }
    
    private func inboxRow(_ message: GmailMessage) -> some View {
        
        HStack(alignment: .top, spacing: 12) {
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
            .indicator(.activity)


            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .top) {
                    Text(message.subject)
                        .font(message.isUnread ? .headline : .body)
                        .fontWeight(message.isUnread ? .semibold : .regular)
                        .lineLimit(1)
                    Spacer(minLength: 8)
                    Text(message.inboxReceivedDateString)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Text(message.from)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(message.snippet)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            .padding(.vertical, 4)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    
    private var filteredMessages: [GmailMessage] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            return gmail.messages
        }
        let lowercasedQuery = query.lowercased()
        return gmail.messages.filter { message in
            let combined = (message.subject + " " + message.from + " " + message.snippet).lowercased()
            return combined.contains(lowercasedQuery)
        }
    }
}

#Preview {
    InboxView(gmail: {
        let vm = GmailViewModel()
        vm.messages = GmailMessage.mockInbox
        return vm
    }())
}
