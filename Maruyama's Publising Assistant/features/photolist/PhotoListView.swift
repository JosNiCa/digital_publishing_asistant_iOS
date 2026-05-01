//
//  PhotoListView.swift
//  Maruyama's Publising Assistant
//
//  Created by LJD Technology on 26/03/26.
//

import SwiftUI

struct PhotoListView: View {
    
    @StateObject private var viewModel: PhotoListViewModel
    @State private var selectedPhoto: Photo?
    @State private var showLogoutConfirm: Bool = false
    
    private let apiClient: APIClient
    private let distributorRepository: DistributorRepositoryImpl
    private let fusionRepository: FusionRepositoryImpl
    private let publishingRepository: PublishingRepositoryImpl
        
    init(photoListViewModel: PhotoListViewModel) {
        _viewModel = StateObject(wrappedValue: photoListViewModel)
        let apiClient = APIClient()
        self.apiClient = apiClient
        self.distributorRepository = DistributorRepositoryImpl(apiClient: apiClient)
        self.fusionRepository = FusionRepositoryImpl(apiClient: apiClient)
        self.publishingRepository = PublishingRepositoryImpl(apiClient: apiClient)
    }
    
    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Fotos")
                .task {
                    await viewModel.loadPhotos()
                }
                .refreshable {
                    await viewModel.refresh()
                }
                .navigationDestination(item: $selectedPhoto) { photo in
                    PhotoViewerView(
                        photo: photo,
                        distributorRepository: distributorRepository,
                        fusionRepository: fusionRepository,
                        publishingRepository: publishingRepository,
                        onFusionCompleted: {
                            FusionSession.shared.clear()
                            selectedPhoto = nil
                        }
                    )
                }
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showLogoutConfirm = true
                        } label: {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                        }
                        .accessibilityLabel("Cerrar sesión")
                    }
                }
                .alert("Cerrar sesión", isPresented: $showLogoutConfirm) {
                    Button("Cancelar", role: .cancel) {}
                    Button("Cerrar sesión", role: .destructive) {
                        SessionManager.shared.logout()
                    }
                } message: {
                    Text("Se borrarán las credenciales y tendrás que iniciar sesión de nuevo.")
                }
        }
    }
    
    @ViewBuilder
    private var content: some View {
        
        if viewModel.isLoading && viewModel.photos.isEmpty {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
        } else if let error = viewModel.errorMessage {
            errorView(message: error)
            
        } else if viewModel.photos.isEmpty {
            emptyView
            
        } else {
            gridView
        }
    }
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    private var gridView: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(viewModel.photos) { photo in
                    PhotoCell(photo: photo)
                        .onTapGesture {
                            guard selectedPhoto == nil else { return }
                            selectedPhoto = photo
                        }
                }
            }
            .padding(8)
        }
    }
    
    private var emptyView: some View {
        Text("No hay imágenes disponibles")
            .foregroundColor(.gray)
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 12) {
            Text(message)
                .foregroundColor(.red)
            
            Button("Reintentar") {
                Task {
                    await viewModel.loadPhotos()
                }
            }
        }
    }
}

struct PhotoCell: View {
    
    let photo: Photo
    
    var body: some View {
        AsyncImage(url: URL(string: photo.imageUrl)) { phase in
            
            switch phase {
                
            case .empty:
                ZStack {
                    Color.gray.opacity(0.2)
                    ProgressView()
                }
                
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
                
            case .failure:
                ZStack {
                    Color.gray.opacity(0.3)
                    Image(systemName: "photo")
                        .foregroundColor(.gray)
                }
                
            @unknown default:
                EmptyView()
            }
        }
        .frame(height: 120)
        .clipped()
        .cornerRadius(8)
    }
}
