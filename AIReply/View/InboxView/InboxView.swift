//
//  InboxView.swift
//  AIReply
//
//  Created by Syed Ahmad on 06/02/2026.
//

import SwiftUI
import SDWebImageSwiftUI

struct InboxView: View {
    @EnvironmentObject var gmail: GmailViewModel

    var body: some View {
        List {
            ForEach(gmail.messages) { message in
                NavigationLink {
                    MessageDetailView(message: message)
                } label: {
                    inboxRow(message)
                }
                .listRowBackground(message.isUnread ? Color.accentColor.opacity(0.08) : Color.clear)
            }
        }
        .overlay {
            if gmail.showLoader {
                ProgressView("Loading inbox…")
            }
        }
        .task {
            await gmail.fetchInbox()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    Task { await gmail.fetchInbox() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Sign out") {
                    gmail.signOut()
                }
            }
        }
        .listStyle(.plain)
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

    private func inboxRow(_ message: GmailMessage) -> some View {
        HStack(alignment: .top, spacing: 12) {
            WebImage(url: message.gravatarURL)
                .resizable()
//                .placeholder {
//                    Circle()
//                        .fill(Color.secondary.opacity(0.3))
//                        .overlay {
//                            Text(String(message.from.prefix(1)).uppercased())
//                                .font(.headline)
//                                .foregroundColor(.secondary)
//                        }
//                }
//                .indicator(.activity)
                .frame(width: 44, height: 44)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(message.subject)
                    .font(message.isUnread ? .headline : .body)
                    .fontWeight(message.isUnread ? .semibold : .regular)
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
}

#Preview {
    InboxView()
}
