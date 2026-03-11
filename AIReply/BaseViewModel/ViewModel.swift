//
//  ViewModel.swift
//  AIReply
//
//  Created by Syed Ahmad  on 06/02/2026.
//

import Foundation

class ViewModel: NSObject, ObservableObject {

    @Published var errorMessage = ""
    @Published var showError = false
    @Published var showLoader = false
    @Published var title = ""

    // MARK: - Alert

    func showAlert(message: String, title: String? = nil) {
        DispatchQueue.main.async { [weak self] in
            self?.errorMessage = message
            self?.showError = true
            self?.title = title ?? ""
        }
    }

    /// Presents an alert with the message from a RequestError. Use from subclasses when a use case or API returns RequestError.
    func showRequestError(_ error: RequestError) {
        showAlert(message: error.customMessage)
    }

    /// Call when the user dismisses the error alert. Clears error state so the next alert can show correctly.
    func dismissAlert() {
        DispatchQueue.main.async { [weak self] in
            self?.showError = false
            self?.errorMessage = ""
            self?.title = ""
        }
    }

    // MARK: - Loader

    /// Runs an async task and shows the full-screen loader only when `show` is true. Loader is hidden when the task finishes (success or throw).
    /// Use for initial loads or user-triggered actions; pass `false` for silent/background refreshes.
    func perform(showLoader show: Bool, task: () async -> Void) async {
        if show {
            DispatchQueue.main.async { [weak self] in self?.showLoader = true }
        }
        defer {
            if show {
                DispatchQueue.main.async { [weak self] in self?.showLoader = false }
            }
        }
        await task()
    }
}
