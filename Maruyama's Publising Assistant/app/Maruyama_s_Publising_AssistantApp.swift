//
//  Maruyama_s_Publising_AssistantApp.swift
//  Maruyama's Publising Assistant
//
//  Created by LJD Technology on 23/03/26.
//

import SwiftUI

@main
struct Maruyama_s_Publising_AssistantApp: App {
    @StateObject private var session = SessionManager.shared
    
    private let apiClient = APIClient()
    private let authRepository: AuthRepository
    private let mediaRepository: MediaRepository
    
    init() {
        self.authRepository = AuthRepositoryImpl(apiClient: apiClient)
        self.mediaRepository = MediaRepositoryImpl(apiClient: apiClient)
    }
        
    var body: some Scene {
        WindowGroup {
            Group {
                 if session.isLoggedIn {
                     MainTabView(mediaRepository: mediaRepository)
                 } else {
                     LoginView(authRepository: authRepository)
                 }
                
            }
            .task {
                if session.token != nil {
                    await session.validateSession(apiClient: apiClient)
                }
            }
        }
    }
}

