//
//  AuthRepositoryImpl.swift
//  Maruyama's Publising Assistant
//
//  Created by LJD Technology on 23/03/26.
//

import Foundation

final class AuthRepositoryImpl: AuthRepository {
    
    private let apiClient: APIClient
    
    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }
    
    func login(username: String, password: String) async throws -> AuthSession {
        
        let request = LoginRequestDTO(
            username: username,
            password: password
        )
        
        let response: LoginResponseDTO
        do {
            response = try await apiClient.request(
                endpoint: .login,
                body: request,
                requiresAuth: false
            )
        } catch let error as APIError {
            if case .serverError(let code, let message) = error {
                switch code {
                case "invalid_credentials":
                    throw AuthError.invalidCredentials
                case "not_approved":
                    throw AuthError.notApproved
                case "must_change_password":
                    throw AuthError.mustChangePassword
                default:
                    throw AuthError.server(message)
                }
            }

            throw AuthError.server(error.localizedDescription)
        }
        
        if !response.ok {
            guard let error = response.error else {
                throw AuthError.server("Unknown error")
            }
            
            switch error.code {
            case "invalid_credentials":
                throw AuthError.invalidCredentials
                
            case "not_approved":
                throw AuthError.notApproved
                
            case "must_change_password":
                throw AuthError.mustChangePassword
                
            default:
                throw AuthError.server(error.message)
            }
        }
        
        guard let data = response.data else {
            throw AuthError.server("Missing data")
        }
        
        let session = data.toDomain()
        
        await MainActor.run {
            SessionManager.shared.save(session: session)
        }
        
        return session
    }
}
