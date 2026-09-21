//
//  GeminiService.swift
//  TelegramMac
//
//  Cherrygram macOS Gemini API Client
//

import Foundation
import SwiftSignalKit
import TelegramCore

public final class GeminiService {
    public static let shared = GeminiService()
    
    private let apiKey: String = "YOUR_GEMINI_API_KEY_HERE"
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro:generateContent"
    
    public func generateContent(prompt: String, completion: @escaping (String?) -> Void) {
        // Prevent invocation if user has disabled Gemini via Cherrygram Settings
        guard CherrygramConfiguration.shared.isGeminiEnabled else {
            completion("Gemini AI is disabled in Cherrygram settings.")
            return
        }
        
        guard let url = URL(string: "\(baseURL)?key=\(apiKey)") else {
            completion(nil)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ]
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        } catch {
            completion(nil)
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                completion(nil)
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let candidates = json["candidates"] as? [[String: Any]],
                   let firstCandidate = candidates.first,
                   let content = firstCandidate["content"] as? [String: Any],
                   let parts = content["parts"] as? [[String: Any]],
                   let firstPart = parts.first,
                   let text = firstPart["text"] as? String {
                    DispatchQueue.main.async {
                        completion(text)
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }
        
        task.resume()
    }
}
