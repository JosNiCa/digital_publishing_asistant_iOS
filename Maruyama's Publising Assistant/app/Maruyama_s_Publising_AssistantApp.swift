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
    
    init() {
        self.authRepository = AuthRepositoryImpl(apiClient: apiClient)
    }
        
    var body: some Scene {
        WindowGroup {
            Group {
                if session.isLoggedIn {
                    //ListView()
                } else {
                    //LoginView()
                }
            }
            .task {
                await session.validateSession(apiClient: apiClient)
            }
        }
    }
}
