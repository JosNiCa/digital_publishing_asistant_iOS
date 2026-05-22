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
        let auth = await MainActor.run {
            (
                token: SessionManager.shared.token,
                tokenType: SessionManager.shared.tokenType ?? "Bearer"
            )
        }
        if requiresAuth {
            guard let token = auth.token, !token.isEmpty else {
                throw APIError.missingToken
            }
            request.addValue("\(auth.tokenType) \(token)", forHTTPHeaderField: "Authorization")
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

            guard (200..<300).contains(httpResponse.statusCode) else {
                if httpResponse.statusCode == 401, requiresAuth {
                    if requiresAuth, auth.token != nil {
                        await MainActor.run {
                            SessionManager.shared.handleUnauthorized()
                        }
                    }
                    throw APIError.unauthorized
                }

                throw Self.apiError(from: data)
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

    private static func apiError(from data: Data) -> APIError {
        guard
            let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            return APIError.unknown
        }

        if let error = object["error"] as? [String: Any] {
            return APIError.serverError(
                code: error["code"] as? String,
                message: error["message"] as? String ?? "Error del servidor"
            )
        }

        if let message = object["message"] as? String {
            return APIError.serverError(
                code: object["code"] as? String,
                message: message
            )
        }

        if let error = object["error"] as? String {
            return APIError.serverError(
                code: object["code"] as? String,
                message: error
            )
        }

        return APIError.unknown
    }
}
