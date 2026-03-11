//
//  Endpoint.swift
//  AIReply
//
//  Created by Syed Ahmad  on 06/02/2026.
//


import Foundation

func getParamsFromCodable<T:Codable>(object:T) -> [String : Any]? {
    
    var param : [String : Any] = [:]
    
    let jsonEncoder = JSONEncoder()
    if let jsonData = try? jsonEncoder.encode(object){
        let jsonString = String(data: jsonData, encoding: String.Encoding.utf8)
        
        if let json = jsonString {
            param =  convertJsonToDictionary(text: json) ?? [:]
        }
        
    }
    
    return param
}
func convertJsonToDictionary(text: String) -> [String: Any]? {
    if let data = text.data(using: .utf8) {
        do {
            return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        } catch {
            print(error.localizedDescription)
        }
    }
    return nil
}

protocol Endpoint {
    var scheme: String { get }
    var host: String { get }
    var path: String { get }
    var method: RequestMethod { get }
    var header: [String: String]? { get }
    var body: [String: Any?]? { get }
    
    var queryItems: [URLQueryItem]? { get }
}

extension Endpoint {
    
    var body: [String: Any?]? {
        return nil
    }
    
    var scheme: String {
        return AppUrl.SCHEME
    }
    
    var host: String {
        return AppUrl.BASEURL
    }
    
    var header: [String: String]? {
        
        
        
        
        return ["Content-Type": "application/json",
                "keyhich": "hich0101"]
        
        
    }
    
    var queryItems:[URLQueryItem]? {
        nil
    }
    
}

enum RequestMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
}

enum RequestError: Error {
    case decode
    case invalidURL
    case noResponse
    case unauthorized(reason:String?)
    case sessionExpried
    case unexpectedStatusCode
    case custom(message:String)
    case unknown
    
    var customMessage: String {
        switch self {
        case .decode:
            return "Oops! Please try again with a closer view. (DE)"
        case .unauthorized (let reason):
            return reason ?? "Oops! Please try again with a closer view. (SE)"
            
        case .custom(let message):
            return message
        default:
            return "Oops! Please try again with a closer view. (UE)"
        }
    }
}

protocol NetworkManagerService {
    func sendRequest<T: Decodable>(endpoint: Endpoint, responseModel: T.Type) async -> Result<T, RequestError>
}
extension NetworkManagerService {
    func sendRequest<T: Decodable>(endpoint: Endpoint, responseModel: T.Type) async -> Result<T, RequestError> {
        
        var urlComponents = URLComponents()
        urlComponents.scheme = endpoint.scheme
        urlComponents.host = endpoint.host.isEmpty ? nil : endpoint.host
        urlComponents.path = endpoint.path.hasPrefix("/") || endpoint.host.isEmpty ? endpoint.path : "/" + endpoint.path
        urlComponents.queryItems = endpoint.queryItems
        
        guard let url = urlComponents.url else {
            return .failure(.invalidURL)
        }
        
        var request = URLRequest(url: url)
//        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        debugPrint("⚠️ ⚠️ ⚠️ ⚠️ ⚠️ ⚠️ ⚠️ ⚠️ ⚠️ ⚠️ ⚠️ ⚠️")
        debugPrint(url)
        
        request.httpMethod = endpoint.method.rawValue
        request.allHTTPHeaderFields = endpoint.header
        request.timeoutInterval = 240
        if let body = endpoint.body {
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: body, options: [])
                request.httpBody = jsonData
                debugPrint("params \(String(decoding: jsonData, as: UTF8.self))")
            } catch {
                return .failure(.unknown)
            }
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request, delegate: nil)
            guard let response = response as? HTTPURLResponse else {
                return .failure(.noResponse)
            }
            
            debugPrint(String(data: data, encoding: String.Encoding.utf8) ?? "")
            
            switch response.statusCode {
            case 200...299:
                do {
                    let decodedResponse = try JSONDecoder().decode(responseModel, from: data)
                    return .success(decodedResponse)
                    
                } catch let error {
                    debugPrint(error)
                    debugPrint("❌ ❌ ❌ ❌ ❌ ❌ ❌ ❌ ❌ ❌ ❌ ❌")
                    return .failure(.decode)
                }
                
            case 401:
                let error = try parseJSON(from: data)
                debugPrint("❌ ❌ ❌ ❌ ❌ ❌ ❌ ❌ ❌ ❌ ❌ ❌")
                debugPrint(error)
                DispatchQueue.main.async {
                    if error.message == "Unauthenticated."{
                        debugPrint("API Failure!")
                    }
                }
                return .failure(.unauthorized(reason: error.message))
                
            default:
                debugPrint("❌ ❌ ❌ ❌ ❌ ❌ ❌ ❌ ❌ ❌ ❌ ❌")
                let response = try parseJSON(from: data)
                return .failure(.unauthorized(reason: response.message))
            }
        } catch let error {
            debugPrint("❌ ❌ ❌ ❌ ❌ ❌ ❌ ❌ ❌ ❌ ❌ ❌")
            return .failure(.unauthorized(reason: error.localizedDescription))
        }
    }
    
    private func parseJSON(from data: Data) throws -> GenericResponse {
        do {
            let decode = try JSONDecoder().decode(GenericResponse.self, from: data)
            debugPrint(decode)
            return decode
            /// force logout here if needed
        } catch let error {
            debugPrint(error)
            debugPrint("❌ ❌ ❌ ❌ ❌ ❌ ❌ ❌ ❌ ❌ ❌ ❌")
        }
        return GenericResponse()
    }
}
