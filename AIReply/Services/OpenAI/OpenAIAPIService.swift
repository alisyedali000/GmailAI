//
//  OpenAIAPIService.swift
//  AIReply
//

import Foundation

/// Abstraction for OpenAI API (Single Responsibility; Dependency Inversion).
protocol OpenAIAPIServiceProtocol: AnyObject {
    /// Generates reply options from the given prompt.
    func generateReplies(prompt: String) async -> Result<OpenAIResponse, RequestError>
    /// Generates summary/context from the given prompt.
    func generateContext(prompt: String) async -> Result<OpenAIResponse, RequestError>
}
