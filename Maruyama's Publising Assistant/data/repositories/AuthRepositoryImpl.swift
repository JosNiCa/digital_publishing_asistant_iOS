//
//  AuthRepositoryImpl.swift
//  Maruyama's Publising Assistant
//
//  Created by LJD Technology on 23/03/26.
//

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
        
        let response: LoginResponseDTO = try await apiClient.request(
            endpoint: .login,
            body: request,
            requiresAuth: false
        )
        
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
        
        return data.toDomain()
    }
}
