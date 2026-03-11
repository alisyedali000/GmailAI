//
//  OpenAIViewModel.swift
//  AIReply
//
//  Created by Syed Ahmad  on 07/02/2026.
//

import Foundation
import CoreLocation
import SwiftUI
import Vision

class OpenAIViewModel : ViewModel{
    
    @Published var email = ""
    @Published var userPrompt = ""
    @Published var emailSummary = Summary(content: "")
    @Published var generatedEmails = GeneratedEmailModel(emails: [])
}

extension OpenAIViewModel: NetworkManagerService {

    @MainActor func generateEmails(completion: @escaping () -> Void) async {
        await perform(showLoader: true) {
            let prompt = PromptGenerator.generateReplies(emailContent: self.email, userPrompt: self.userPrompt)
            let endPoint: OpenAIEndpoints = .generateReplies(prompt: prompt)
            let request = await self.sendRequest(endpoint: endPoint, responseModel: OpenAIResponse.self)
            switch request {
            case .success(let data):
                let parsedResult = OpenAIResponseParser.parse(data: data, responseModel: GeneratedEmailModel.self)
                switch parsedResult {
                case .success(let parsedData):
                    self.generatedEmails = parsedData
                    completion()
                case .failure(let error):
                    self.showRequestError(error)
                }
            case .failure(let error):
                self.showRequestError(error)
            }
        }
    }

    @MainActor func generateEmailSummary(completion: @escaping () -> Void) async {
        await perform(showLoader: true) {
            let prompt = PromptGenerator.generateSummary(emailContent: self.email)
            let endPoint: OpenAIEndpoints = .generateContext(prompt: prompt)
            let request = await self.sendRequest(endpoint: endPoint, responseModel: OpenAIResponse.self)
            switch request {
            case .success(let data):
                let parsedResult = OpenAIResponseParser.parse(data: data, responseModel: Summary.self)
                switch parsedResult {
                case .success(let parsedData):
                    self.emailSummary = parsedData
                    completion()
                case .failure(let error):
                    self.showRequestError(error)
                }
            case .failure(let error):
                self.showRequestError(error)
            }
        }
    }
}
