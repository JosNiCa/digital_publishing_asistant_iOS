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
    @Published private(set) var isAdmin: Bool = false
    @Published private(set) var distributorId: Int?
    @Published private(set) var distributorName: String?
    
    private enum Keys {
        static let token = "auth_token"
        static let tokenType = "auth_token_type"
        static let isAdmin = "auth_is_admin"
        static let distributorId = "auth_distributor_id"
        static let distributorName = "auth_distributor_name"
    }
    
    private init() {
        let savedToken = KeychainManager.shared.read(key: Keys.token)
        let savedTokenType = KeychainManager.shared.read(key: Keys.tokenType)
        let savedIsAdmin = KeychainManager.shared.read(key: Keys.isAdmin) == "true"
        let savedDistributorId = KeychainManager.shared.read(key: Keys.distributorId).flatMap(Int.init)
        let savedDistributorName = KeychainManager.shared.read(key: Keys.distributorName)
        self.token = savedToken
        self.tokenType = savedTokenType
        self.isLoggedIn = savedToken != nil
        self.isAdmin = savedIsAdmin
        self.distributorId = savedDistributorId
        self.distributorName = savedDistributorName
    }
    
    // MARK: - Save
    func save(session: AuthSession) {
        self.token = session.token
        self.tokenType = session.tokenType
        self.isAdmin = session.user.isAdmin
        self.distributorId = session.profile.distributorId > 0 ? session.profile.distributorId : nil
        self.distributorName = session.profile.distributorName
        self.isLoggedIn = true
        KeychainManager.shared.save(key: Keys.token, value: session.token)
        KeychainManager.shared.save(key: Keys.tokenType, value: session.tokenType)
        KeychainManager.shared.save(key: Keys.isAdmin, value: session.user.isAdmin ? "true" : "false")
        if let distributorId {
            KeychainManager.shared.save(key: Keys.distributorId, value: String(distributorId))
        } else {
            KeychainManager.shared.delete(key: Keys.distributorId)
        }
        KeychainManager.shared.save(key: Keys.distributorName, value: session.profile.distributorName)
    }
    
    // MARK: - Logout
    func logout() {
        token = nil
        tokenType = nil
        isAdmin = false
        distributorId = nil
        distributorName = nil
        isLoggedIn = false
        KeychainManager.shared.delete(key: Keys.token)
        KeychainManager.shared.delete(key: Keys.tokenType)
        KeychainManager.shared.delete(key: Keys.isAdmin)
        KeychainManager.shared.delete(key: Keys.distributorId)
        KeychainManager.shared.delete(key: Keys.distributorName)
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
