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
    @Published var generatedEmails = GeneratedEmailModel(emails: [])
}

extension OpenAIViewModel: NetworkManagerService{
    
    @MainActor func generateEmails(completion: @escaping () -> Void) async {
        
        self.showLoader = true
        let prompt = PromptGenerator.generateReplies(emailContent: self.email)
        let endPoint: OpenAIEndpoints = .generateReplies(prompt: prompt)
        let request = await sendRequest(endpoint: endPoint, responseModel: OpenAIResponse.self)

        showLoader = false
        
        switch request {
            
        case .success(let data):

            let parsedResult = OpenAIResponseParser.parse(data: data, responseModel: GeneratedEmailModel.self)
            
            switch parsedResult {
                
            case .success(let parsedData):
                
                debugPrint(parsedData)
                self.generatedEmails = parsedData
                completion()
                
            case .failure(let error):
                
//                showAlert(message: error.customMessage)
                showAlert(message: error.customMessage) //GPT returns failure OCR message
            }
        case .failure(let error):
            
            debugPrint(error.customMessage)
            self.showAlert(message: error.customMessage)
        }

        
    }
    
}
