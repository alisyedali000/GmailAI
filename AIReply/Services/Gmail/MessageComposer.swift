//
//  MessageComposer.swift
//  AIReply
//

import Foundation

/// Builds MIME reply and encodes for Gmail API (Single Responsibility).
enum MessageComposer {

    static func buildReply(to recipient: String, subject: String, messageId: String, body: String) -> String {
        """
        To: \(recipient)
        Subject: Re: \(subject)
        In-Reply-To: \(messageId)
        References: \(messageId)
        Content-Type: text/plain; charset=utf-8

        \(body)
        """
    }

    static func base64URLEncode(_ data: Data) -> String {
        var encoded = data.base64EncodedString()
        encoded = encoded
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        return encoded
    }
}
