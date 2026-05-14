//
//  MainTabView.swift
//  Maruyama's Publising Assistant
//
//  Created by LJD Technology on 01/05/26.
//

import SwiftUI

struct MainTabView: View {

    let mediaRepository: MediaRepository
    private let apiClient = APIClient()
    @ObservedObject private var publishingActivity = PublishingActivityCenter.shared
    
    var body: some View {
        TabView {

            // MARK: - Home
            NavigationStack {
                PhotoListView(
                    photoListViewModel: PhotoListViewModel(
                        mediaRepository: mediaRepository
                    )
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
                    publishingRepository: PublishingRepositoryImpl(apiClient: apiClient)
                )
            }
            .tabItem {
                Label("Historial", systemImage: "clock.fill")
            }

            // MARK: - Conexiones (placeholder)
            NavigationStack {
                ConnectionsView(
                    publishingRepository: PublishingRepositoryImpl(apiClient: apiClient)
                )
            }
            .tabItem {
                Label("Conexión", systemImage: "link")
            }
        }
        .tint(AppColors.brand)
        .overlay(alignment: .bottom) {
            PublishingActivityOverlay(activity: publishingActivity)
        }
    }
}
