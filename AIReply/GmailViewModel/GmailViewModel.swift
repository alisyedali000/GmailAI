//
//  GmailViewModel.swift
//  AIReply
//

import Foundation
import BackgroundTasks
import SwiftData

@MainActor
final class GmailViewModel: ViewModel {
    static weak var currentForBackgroundSync: GmailViewModel?

    @Published var messages: [GmailMessage] = []
    @Published var isSignedIn = false
    @Published var searchQuery: String = ""
    @Published var inboxNextPageToken: String?
    @Published var isLoadingMore = false
    @Published var bimiLogoCache: [String: URL] = [:]

    private let authService: GmailAuthService
    private let fetchInboxUseCase: FetchInboxUseCase
    private let loadMoreInboxUseCase: LoadMoreInboxUseCase
    private let fetchThreadUseCase: FetchThreadUseCase
    private let sendReplyUseCase: SendReplyUseCase
    private let bimiLookupService: BimiLookupServiceProtocol
    private let historyIdStorage: GmailHistoryIdStorage
    private let inboxStorage: GmailInboxStorage
    private let pageTokenStorage: GmailInboxPageTokenStorage

    init(authService: GmailAuthService, fetchInboxUseCase: FetchInboxUseCase, loadMoreInboxUseCase: LoadMoreInboxUseCase, fetchThreadUseCase: FetchThreadUseCase, sendReplyUseCase: SendReplyUseCase, bimiLookupService: BimiLookupServiceProtocol, historyIdStorage: GmailHistoryIdStorage, inboxStorage: GmailInboxStorage, pageTokenStorage: GmailInboxPageTokenStorage) {
        self.authService = authService
        self.fetchInboxUseCase = fetchInboxUseCase
        self.loadMoreInboxUseCase = loadMoreInboxUseCase
        self.fetchThreadUseCase = fetchThreadUseCase
        self.sendReplyUseCase = sendReplyUseCase
        self.bimiLookupService = bimiLookupService
        self.historyIdStorage = historyIdStorage
        self.inboxStorage = inboxStorage
        self.pageTokenStorage = pageTokenStorage
        super.init()
        isSignedIn = authService.isSignedIn
    }

    private static let backgroundRefreshIdentifier = "com.aireply.inboxrefresh"

    func scheduleBackgroundRefreshIfNeeded() {
        Self.currentForBackgroundSync = self
        let request = BGAppRefreshTaskRequest(identifier: Self.backgroundRefreshIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
        try? BGTaskScheduler.shared.submit(request)
    }
}

extension GmailViewModel {
    var filteredMessages: [GmailMessage] {
        let q = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return messages }
        let lower = q.lowercased()
        return messages.filter { message in (message.subject + " " + message.from + " " + message.snippet).lowercased().contains(lower) }
    }
}

extension GmailViewModel {
    func restorePreviousSignIn() async {
        await authService.restorePreviousSignIn()
        isSignedIn = authService.isSignedIn
    }

    func signIn() async {
        await authService.signIn()
        isSignedIn = authService.isSignedIn
        if !isSignedIn { showAlert(message: "Sign-in failed. Please try again.") }
    }

    func signOut() {
        authService.signOut()
        historyIdStorage.clearHistoryId()
        inboxStorage.clear()
        pageTokenStorage.clearNextPageToken()
        messages = []
        inboxNextPageToken = nil
        bimiLogoCache = [:]
        isSignedIn = false
    }
}

extension GmailViewModel {
    func fetchInbox(silent: Bool = false) async {
        let hadMessagesInMemory = !messages.isEmpty
        if !hadMessagesInMemory {
            messages = fetchInboxUseCase.loadFromStorage(limit: kInboxStorageLimit)
        }
        inboxNextPageToken = pageTokenStorage.getNextPageToken()
        let existingForMerge = hadMessagesInMemory ? messages : (messages.isEmpty ? nil : messages)
        let showLoader = !silent && messages.isEmpty
        await perform(showLoader: showLoader) {
            let result = await self.fetchInboxUseCase.execute(currentNextPageToken: self.inboxNextPageToken, existingMessages: existingForMerge)
            switch result {
            case .success(let page):
                self.messages = page.messages
                self.inboxNextPageToken = page.nextPageToken
                self.pageTokenStorage.saveNextPageToken(page.nextPageToken)
            case .failure(let error):
                if !silent { self.showRequestError(error) }
            }
        }
    }

    func loadBimiLogoIfNeeded(email: String) async {
        let domain = email.trimmingCharacters(in: .whitespaces).lowercased()
            .split(separator: "@").dropFirst().first.map(String.init) ?? ""
        guard !domain.isEmpty, bimiLogoCache[domain] == nil else { return }
        guard let logoURL = await bimiLookupService.fetchLogoURL(domain: domain) else { return }
        bimiLogoCache[domain] = logoURL
    }

    func loadMoreInbox() async {
        guard let token = inboxNextPageToken, !isLoadingMore else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }
        if case .success(let page) = await loadMoreInboxUseCase.execute(pageToken: token) {
            messages.append(contentsOf: page.messages)
            inboxNextPageToken = page.nextPageToken
            pageTokenStorage.saveNextPageToken(page.nextPageToken)
        }
    }

    func fetchThread(threadId: String) async -> [GmailMessage] {
        switch await fetchThreadUseCase.execute(threadId: threadId) {
        case .success(let list): return list
        case .failure: return []
        }
    }

    func sendReply(to original: GmailMessage, body: String) async {
        if case .failure(let error) = await sendReplyUseCase.execute(original: original, body: body) {
            showRequestError(error)
        }
    }
}

extension GmailViewModel {
    static func makeDefault() -> GmailViewModel {
        let clientID = "770896531160-54sfgs5hsj7a4qa6tk3qmlbhquu960n2.apps.googleusercontent.com"
        let authService = GoogleSignInGmailAuthService(clientID: clientID)
        let repository = DefaultGmailRepository()
        let historyIdStorage = UserDefaultsGmailHistoryIdStorage()
        let container: ModelContainer
        do {
            container = try ModelContainer(for: StoredInboxMessage.self)
        } catch {
            container = try! ModelContainer(for: StoredInboxMessage.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        }
        let modelContext = ModelContext(container)
        let inboxStorage = SwiftDataGmailInboxStorage(modelContext: modelContext)
        let fetchInbox = DefaultFetchInboxUseCase(repository: repository, authService: authService, historyIdStorage: historyIdStorage, inboxStorage: inboxStorage)
        let loadMoreInbox = DefaultLoadMoreInboxUseCase(repository: repository, authService: authService)
        let fetchThread = DefaultFetchThreadUseCase(repository: repository, authService: authService)
        let sendReply = DefaultSendReplyUseCase(repository: repository, authService: authService)
        let bimiLookupService = BimiLookupService()
        let pageTokenStorage = UserDefaultsGmailInboxPageTokenStorage()
        return GmailViewModel(authService: authService, fetchInboxUseCase: fetchInbox, loadMoreInboxUseCase: loadMoreInbox, fetchThreadUseCase: fetchThread, sendReplyUseCase: sendReply, bimiLookupService: bimiLookupService, historyIdStorage: historyIdStorage, inboxStorage: inboxStorage, pageTokenStorage: pageTokenStorage)
    }

    static func makeForPreview() -> GmailViewModel {
        let vm = makeDefault()
        vm.messages = GmailMessage.mockInbox
        vm.isSignedIn = true
        return vm
    }
}
