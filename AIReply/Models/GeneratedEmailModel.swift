//
//  Welcome.swift
//  AIReply
//
//  Created by Syed Ahmad  on 07/02/2026.
//


import Foundation

// MARK: - Welcome
struct GeneratedEmailModel: Codable {
    let emails: [Email]
}

// MARK: - Email
struct Email: Codable {
    let subject, content: String
    
    init(subject: String, content: String) {
        self.subject = subject
        self.content = content
    }
    init() {
        self.subject = ""
        self.content = ""
    }
    
}
