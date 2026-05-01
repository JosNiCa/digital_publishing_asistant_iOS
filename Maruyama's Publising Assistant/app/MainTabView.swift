//
//  MainTabView.swift
//  Maruyama's Publising Assistant
//
//  Created by LJD Technology on 01/05/26.
//

import SwiftUI

struct MainTabView: View {

    let mediaRepository: MediaRepository
    
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
                HistoryView()
            }
            .tabItem {
                Label("Historial", systemImage: "clock.fill")
            }

            // MARK: - Conexiones (placeholder)
            NavigationStack {
                ConnectionsView()
            }
            .tabItem {
                Label("Conexión", systemImage: "link")
            }
        }
        .tint(.red) // opcional estilo iOS como tu imagen
    }
}

