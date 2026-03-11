//
//  TextEditorWithPlaceholder.swift
//  AIReply
//
//  Created by Syed Ahmad  on 05/03/2026.
//

import SwiftUI

struct CustomTextEditor: View {
    @Binding var text: String
    var placeholder: String

    /// Matches TextEditor’s effective content origin (outer padding + internal text container inset / lineFragmentPadding).
    private static let textEditorTopPadding: CGFloat = 8
    private static let textEditorLeadingPadding: CGFloat = 5
    private static let textEditorInternalTop: CGFloat = 8
    private static let textEditorInternalLeading: CGFloat = 5

    var body: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: $text)
                .padding(.top, Self.textEditorTopPadding)
                .padding(.leading, Self.textEditorLeadingPadding)
                .font(.regular(size: 15.3))

            if text.isEmpty {
                Text(placeholder)
                    .foregroundColor(.gray)
                    .font(.regular(size: 15.3))
                    .padding(.top, Self.textEditorTopPadding + Self.textEditorInternalTop)
                    .padding(.leading, Self.textEditorLeadingPadding + Self.textEditorInternalLeading)
            }
        }
        .frame(minHeight: 120)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.secondary.opacity(0.3))
        )
    }
}

#Preview{
    CustomTextEditor(text: .constant(""), placeholder: "Hello World")
}
