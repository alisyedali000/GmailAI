//
//  InboxView.swift
//  AIReply
//

import SwiftUI

struct InboxView: View {
    @ObservedObject var gmail: GmailViewModel
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        screenView
            .onChange(of: scenePhase) { _, newValue in
                if newValue == .active { Task { await gmail.fetchInbox(silent: true) } }
            }
            .onReceive(Timer.publish(every: 15, on: .main, in: .common).autoconnect()) { _ in
                Task { await gmail.fetchInbox(silent: true) }
            }
            .task { await gmail.fetchInbox() }
            .onAppear { gmail.scheduleBackgroundRefreshIfNeeded() }
            .alert(for: gmail)
            .loaderOverlay(visible: gmail.showLoader, message: "Loading inbox…")
    }
}

extension InboxView {
    var screenView: some View {
        VStack {
            HStack {
                Text("Inbox").font(.semiBold(size: 24))
                Spacer()
                Button { gmail.signOut() } label: { Image(.threeBars) }
            }
            .padding(.horizontal)

            SearchBar(query: $gmail.searchQuery, placeholder: "Search in mails")
                .padding(.horizontal)
//            LazyVStack{
            List {

                    ForEach(Array(gmail.filteredMessages.enumerated()), id: \.element.id) { index, message in
                        
                        NavigationLink {
                            MessageDetailView(gmail: gmail, message: message)
                        } label: { inboxRow(message) }
                            .listRowBackground(message.isUnread ? Color.accentColor.opacity(0.08) : Color.clear)
                            .onAppear {
                                let count = gmail.filteredMessages.count
                                let triggerIndex = count - 5
                                if count >= 5, index == triggerIndex, gmail.inboxNextPageToken != nil, !gmail.isLoadingMore {
                                    Task { await gmail.loadMoreInbox() }
                                }
                            }
//                    }
                }
                if gmail.inboxNextPageToken != nil && gmail.isLoadingMore {
                    Section {
                        
                        HStack{
                            
                            Spacer()
                            //                        if gmail.isLoadingMore {
                            Spinner()
                            
                            Spacer()
                            
                            }
                        }
                    .padding()
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
            }
            .listStyle(.plain)
            .refreshable { await gmail.fetchInbox(silent: true) }
        }
    }

    private func inboxRow(_ message: GmailMessage) -> some View {
        HStack(alignment: .top, spacing: 12) {
            SenderAvatarView(gmail: gmail, email: message.fromEmail, displayName: message.from, size: 44)
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .top) {
                    Text(message.subject)
                        .font(message.isUnread ? .headline : .body)
                        .fontWeight(message.isUnread ? .semibold : .regular)
                        .lineLimit(1)
                    Spacer(minLength: 8)
                    Text(message.inboxReceivedDateString).font(.caption).foregroundColor(.secondary)
                }
                Text(message.from).font(.subheadline).foregroundColor(.secondary)
                Text(message.snippet).font(.caption).foregroundColor(.secondary).lineLimit(2)
            }
            .padding(.vertical, 4)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview {
    InboxView(gmail: GmailViewModel.makeForPreview())
}
