//
//  OpenAIResponseParser.swift
//  AIReply
//
//  Created by Syed Ahmad  on 07/02/2026.
//




import Foundation

class OpenAIResponseParser: Decodable{
    static  func parse<T: Decodable>(data response: OpenAIResponse,responseModel: T.Type) -> Result<T, RequestError>  {
       do {
               if let contentString = response.choices.first?.message.content {
               let pattern = "\\{[\\s\\S]*\\}"
               if let regex = try? NSRegularExpression(pattern: pattern, options: .dotMatchesLineSeparators),
                  let match = regex.firstMatch(in: contentString, range: NSRange(contentString.startIndex..., in: contentString)) {
                   
                   if let range = Range(match.range, in: contentString) {
                       let jsonString = String(contentString[range])
                       print(jsonString)
                       
                       if let jsonData = jsonString.data(using: .utf8) {
                           
                           do {
                               // Decode into a generic dictionary first to check for errors
                               if let parsedJson = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any],
                                  let isError = parsedJson["error"] as? Bool, isError {
                                   let errorMessage = parsedJson["message"] as? String ?? "Unknown error occurred."
                                   DispatchQueue.main.async {
//                                        self.isError = true
//                                        self.errorMessage = errorMessage
                                       "Error: \(errorMessage)"
                                       
                                   }
                                  
                                   return .failure(.custom(message: errorMessage))
                               }else {
                                   let decodedData = try JSONDecoder().decode(responseModel, from: jsonData)
                                   return .success(decodedData)
                               }
                               
                               
                           } catch {
                            
                                   
                                  print( "JSON Decoding Error: \(error.localizedDescription)")
                                   return .failure(.unknown)
                               
                           }
                       }
                   }
                   
               }
           }
           
           return .failure(.unknown)
           
       
           /// force logout here if needed
       } catch let error {
           debugPrint(error)
           debugPrint("❌ ❌ ❌ ❌ ❌ ❌ ❌ ❌ ❌ ❌ ❌ ❌")
           return .failure(.unknown)
       }
      
       
   }
}