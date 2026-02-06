//
//  ViewModel.swift
//  AIReply
//
//  Created by Syed Ahmad  on 06/02/2026.
//

import Foundation

class ViewModel : NSObject, ObservableObject {
    
    @Published var errorMessage = ""
    @Published var showError = false
    @Published var showLoader = false
    @Published var title = ""
    func showAlert(message: String, title: String? = nil) {
        
        DispatchQueue.main.async {
            self.errorMessage = message
            self.showError = true
            self.title = title ?? ""
        }
    }
    
}
