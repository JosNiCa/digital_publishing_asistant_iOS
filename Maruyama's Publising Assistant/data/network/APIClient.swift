//
//  APIClient.swift
//  Maruyama's Publising Assistant
//
//  Created by LJD Technology on 23/03/26.
//

import Foundation

final public class APIClient {
    
    private let baseURL: URL
    private let session: URLSession
    
    init(
        baseURL: URL = URL(string: "https://ljdit.com")!,
        session: URLSession = .shared
    ) {
        self.baseURL = baseURL
        self.session = session
    }
    
    func request<T: Decodable>(
        endpoint: Endpoint,
        body: Encodable? = nil,
        requiresAuth: Bool = false
    ) async throws -> T {
        
        guard let url = URL(string: endpoint.path, relativeTo: baseURL) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Auth
        if requiresAuth, let token = SessionManager.shared.token {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Body
        if let body = body {
            do {
                request.httpBody = try JSONEncoder().encode(body)
            } catch {
                throw APIError.networkError(error)
            }
        }
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.unknown
            }
            
            if httpResponse.statusCode == 401 {
                await MainActor.run {
                    SessionManager.shared.handleUnauthorized()
                }
                throw APIError.unauthorized
            }
            
            do {
                return try JSONDecoder.apiDecoder.decode(T.self, from: data)
            } catch {
                print("❌ DECODING ERROR:", error)
                print("📦 RAW:", String(data: data, encoding: .utf8) ?? "nil")
                throw APIError.decodingError(error)
            }

        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }
}
