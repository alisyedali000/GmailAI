//
//  OpenAIAPIServiceImpl.swift
//  AIReply
//

import Foundation

final class OpenAIAPIServiceImpl: OpenAIAPIServiceProtocol {

    private let network: NetworkManagerService

    init(network: NetworkManagerService = DefaultNetworkService()) {
        self.network = network
    }

    func generateReplies(prompt: String) async -> Result<OpenAIResponse, RequestError> {
        let endpoint = OpenAIEndpoints.generateReplies(prompt: prompt)
        return await network.sendRequest(endpoint: endpoint, responseModel: OpenAIResponse.self)
    }

    func generateContext(prompt: String) async -> Result<OpenAIResponse, RequestError> {
        let endpoint = OpenAIEndpoints.generateContext(prompt: prompt)
        return await network.sendRequest(endpoint: endpoint, responseModel: OpenAIResponse.self)
    }
}
