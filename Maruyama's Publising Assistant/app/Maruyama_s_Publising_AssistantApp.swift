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
    private let photoListViewModel: PhotoListViewModel
    
    init() {
        self.authRepository = AuthRepositoryImpl(apiClient: apiClient)
        self.mediaRepository = MediaRepositoryImpl(apiClient: apiClient)
        self.photoListViewModel = PhotoListViewModel(mediaRepository: mediaRepository)
    }
        
    var body: some Scene {
        WindowGroup {
            Group {
                 if session.isLoggedIn {
                     PhotoListView(photoListViewModel: photoListViewModel)
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

