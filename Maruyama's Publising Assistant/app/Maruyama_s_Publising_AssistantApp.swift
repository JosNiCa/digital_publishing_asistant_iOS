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
        
    var body: some Scene {
        WindowGroup {
            Group {
                if session.isLoggedIn {
                    ContentView()
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
