//
//  MainTabView.swift
//  Maruyama's Publising Assistant
//
//  Created by LJD Technology on 01/05/26.
//

import SwiftUI

struct MainTabView: View {

    let mediaRepository: MediaRepository
    let authRepository: AuthRepository
    private let apiClient = APIClient()
    @StateObject private var fusionSession = FusionSession()
    @StateObject private var publishingActivity = PublishingActivityCenter()
    
    var body: some View {
        TabView {

            // MARK: - Home
            NavigationStack {
                PhotoListView(
                    photoListViewModel: PhotoListViewModel(mediaRepository: mediaRepository),
                    fusionSession: fusionSession,
                    publishingActivity: publishingActivity
                )
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }

            // MARK: - Historial
            NavigationStack {
                HistoryView(
                    mediaRepository: mediaRepository,
                    fusionRepository: FusionRepositoryImpl(apiClient: apiClient),
                    publishingRepository: PublishingRepositoryImpl(apiClient: apiClient),
                    fusionSession: fusionSession,
                    publishingActivity: publishingActivity
                )
            }
            .tabItem {
                Label("Historial", systemImage: "clock.fill")
            }

            // MARK: - Conexiones (placeholder)
            NavigationStack {
                ConnectionsView(
                    publishingRepository: PublishingRepositoryImpl(apiClient: apiClient),
                    authRepository: authRepository
                )
            }
            .tabItem {
                Label("Conexión", systemImage: "link")
            }
        }
        .tint(AppColors.brand)
        .overlay(alignment: .top) {
            PublishingActivityOverlay(activity: publishingActivity)
        }
    }
}
