//
//  SessionManager.swift
//  Maruyama's Publising Assistant
//
//  Created by LJD Technology on 24/03/26.
//

import Foundation
import Combine

@MainActor
final class SessionManager : ObservableObject{
    
    static let shared = SessionManager()
    
    @Published private(set) var token: String?
    @Published private(set) var tokenType: String?
    @Published private(set) var isLoggedIn: Bool = false
    
    private enum Keys {
        static let token = "auth_token"
        static let tokenType = "auth_token_type"
    }
    
    private init() {
        let savedToken = KeychainManager.shared.read(key: Keys.token)
        let savedTokenType = KeychainManager.shared.read(key: Keys.tokenType)
        self.token = savedToken
        self.tokenType = savedTokenType
        self.isLoggedIn = savedToken != nil
    }
    
    // MARK: - Save
    func save(session: AuthSession) {
        self.token = session.token
        self.tokenType = session.tokenType
        self.isLoggedIn = true
        KeychainManager.shared.save(key: Keys.token, value: session.token)
        KeychainManager.shared.save(key: Keys.tokenType, value: session.tokenType)
    }
    
    // MARK: - Logout
    func logout() {
        token = nil
        tokenType = nil
        isLoggedIn = false
        KeychainManager.shared.delete(key: Keys.token)
        KeychainManager.shared.delete(key: Keys.tokenType)
    }
    
    // MARK: - Interceptor
    func handleUnauthorized() {
        print("⚠️ Token inválido → logout automático")
        logout()
    }
    
    
    func validateSession(apiClient: APIClient) async {
        guard let token = token else {
            return
        }
        
        do {
            let response: MeResponseDTO = try await apiClient.request(
                endpoint: .me,
                requiresAuth: true
            )
            
            guard response.ok, let data = response.data else {
                logout()
                return
            }
            
            let session = data.toDomain(with: token)
            save(session: session)
            
        } catch {
            logout()
        }
    }
}
