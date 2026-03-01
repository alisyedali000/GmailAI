//
//  OpenAIEndpoints.swift
//  AIReply
//
//  Created by Syed Ahmad  on 07/02/2026.
//


import Foundation

let API_Key = "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"

enum OpenAIEndpoints {
    
    case generateContext(prompt: String)
    case generateReplies(prompt: String)

    
}
extension OpenAIEndpoints : Endpoint {
    
    
    var path: String {
        
        switch self {
            
        case .generateContext:
            return "api.openai.com/v1/chat/completions"
            
        case .generateReplies:
            return "api.openai.com/v1/chat/completions"
            

        }
    }
    
    var method: RequestMethod {
        
        switch self {
            
        case .generateContext:
            return .post
            
        case .generateReplies:
            return .post
            
            
        }
    }
    
    var header: [String: String]? {
        
        switch self {
            
        case .generateContext:
            
            return  [
                "Authorization": "Bearer \(API_Key)",
                "Content-Type": "application/json"
            ]
            
        case .generateReplies:
            
            return  [
                "Authorization": "Bearer \(API_Key)",
                "Content-Type": "application/json"
            ]

        }
    }
    
    var body: [String : Any?]? {
        switch self {
            
            
        case .generateContext(let prompt):
            
            return [
                "model": "gpt-4o",
                "messages": [
                    ["role": "system", "content": "You are a professional email responder."],
                    ["role": "user", "content": prompt]
                ],
                "temperature": 0.0
            ]
            
        case .generateReplies(let prompt):
            
            return [
                "model": "gpt-4o",
                "messages": [
                    ["role": "system", "content": "You are a professional email responder."],
                    ["role": "user", "content": prompt]
                ],
                "temperature": 0.0
            ]
            
        }
        
    }
    
    
}

