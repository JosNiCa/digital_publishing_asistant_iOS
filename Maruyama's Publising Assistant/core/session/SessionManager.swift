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
    @Published private(set) var isLoggedIn: Bool = false
    
    private enum Keys {
        static let token = "auth_token"
    }
    
    private init() {
        let savedToken = KeychainManager.shared.read(key: Keys.token)
        self.token = savedToken
        self.isLoggedIn = savedToken != nil
    }
    
    // MARK: - Save
    func save(session: AuthSession) {
        self.token = session.token
        self.isLoggedIn = true
        KeychainManager.shared.save(key: Keys.token, value: session.token)
    }
    
    // MARK: - Logout
    func logout() {
        token = nil
        isLoggedIn = false
        KeychainManager.shared.delete(key: Keys.token)
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
