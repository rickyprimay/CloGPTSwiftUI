//
//  OpenAIViewModel.swift
//  CloGPT
//
//  Created by Ricky Primayuda Putra on 02/12/24.
//

import SwiftUI
import Alamofire
import Combine

class OpenAIViewModel: ObservableObject {
    let baseUrl = "https://api.openai.com/v1/"
    
    func sendMessage(message: String) -> AnyPublisher<OpenAICompletionsResponse, Error> {
        let body = OpenAICompletionsBody(model: "davinci-002", prompt: message, temperature: 0.7)
        
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(Constants.openAIAPIKey)"
        ]
        
        return Future { [weak self] promise in
            guard let self = self else { return }
            
            AF.request(self.baseUrl + "completions", method: .post, parameters: body, encoder: .json, headers: headers)
                .response { response in
                    switch response.result {
                    case .success(let data):
                        if let json = try? JSONSerialization.jsonObject(with: data!, options: []) {
                            print("Raw JSON Response: \(json)")
                        } else {
                            print("Invalid JSON Response")
                        }
                    case .failure(let error):
                        print("Request Error: \(error)")
                    }
                }
                .responseDecodable(of: OpenAICompletionsResponse.self) { response in
                    switch response.result {
                    case .success(let result):
                        promise(.success(result))
                    case .failure(let error):
                        print("Decoding Error: \(error)")
                        promise(.failure(error))
                    }
                }
            
        }
        .eraseToAnyPublisher()
    }
}

struct OpenAICompletionsBody: Encodable {
    let model: String
    let prompt: String
    let temperature: Float?
}

struct OpenAICompletionsResponse: Decodable {
    let id: String
    let object: String
    let created: Int
    let model: String
    let choices: [OpenAICompletionsOptions]
    let usage: OpenAIUsage?
}

struct OpenAICompletionsOptions: Decodable {
    let text: String
    let index: Int
    let logprobs: String?
    let finish_reason: String
}

struct OpenAIUsage: Decodable {
    let prompt_tokens: Int
    let completion_tokens: Int
    let total_tokens: Int
}
