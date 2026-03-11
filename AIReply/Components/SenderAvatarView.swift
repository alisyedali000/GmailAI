//
//  SenderAvatarView.swift
//  AIReply
//

import SwiftUI
import SDWebImageSwiftUI

/// Extracts a single initial for avatar: letters only, no special characters.
private func initialForAvatar(displayName: String, email: String) -> String {
    let namePart = displayName.trimmingCharacters(in: .whitespaces)
    let lettersOnly = namePart.unicodeScalars.filter { CharacterSet.letters.contains($0) }
    if let first = lettersOnly.first {
        return String(first).uppercased()
    }
    let localPart = email.split(separator: "@").first.map(String.init) ?? email
    let localLetters = localPart.unicodeScalars.filter { CharacterSet.letters.contains($0) }
    if let first = localLetters.first {
        return String(first).uppercased()
    }
    if let fallback = namePart.first ?? localPart.first {
        return String(fallback).uppercased()
    }
    return "?"
}

struct SenderAvatarView: View {
    @ObservedObject var gmail: GmailViewModel
    let email: String
    let displayName: String
    var size: CGFloat = 44

    private var cacheKey: String { domainFromEmail(email) }
    private var logoURL: URL? { gmail.bimiLogoCache[cacheKey] }
    private var initial: String { initialForAvatar(displayName: displayName, email: email) }

    var body: some View {
        ZStack {
           
            if let url = logoURL {
                WebImage(url: url)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else {
                
                placeholderCircle
                
            }
        }
        .frame(width: size, height: size)
        .onAppear { Task { await gmail.loadBimiLogoIfNeeded(email: email) } }
    }

    private var placeholderCircle: some View {
        Circle()
            .fill(Color(hex: "0094FF"))
            .frame(width: size, height: size)
            .overlay {
                Text(initial)
                    .font(.bold(size: 18))
                    .foregroundColor(.white)
            }
    }
}

private func domainFromEmail(_ email: String) -> String {
    let trimmed = email.trimmingCharacters(in: .whitespaces).lowercased()
    guard let at = trimmed.firstIndex(of: "@") else { return trimmed }
    return String(trimmed[trimmed.index(after: at)...])
}
