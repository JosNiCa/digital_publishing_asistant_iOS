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
    @State private var completionResult: FusionCompletionResult?
    
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
                        onFusionCompleted: { result in
                            FusionSession.shared.clear()
                            completionResult = result
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
                .alert(
                    completionResult?.title ?? "",
                    isPresented: Binding(
                        get: { completionResult != nil },
                        set: { if !$0 { completionResult = nil } }
                    )
                ) {
                    Button("Entendido", role: .cancel) {
                        completionResult = nil
                    }
                } message: {
                    Text(completionResult?.message ?? "")
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
    
    private let compactColumns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]
    
    private var gridView: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 18) {
                ForEach(PhotoFormat.allCases, id: \.rawValue) { format in
                    let photos = photos(for: format)

                    if !photos.isEmpty {
                        PhotoFormatSection(
                            title: format.title,
                            format: format,
                            photos: photos,
                            compactColumns: compactColumns,
                            onSelect: selectPhoto
                        )
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    private func photos(for format: PhotoFormat) -> [Photo] {
        viewModel.photos.filter { $0.format == format }
    }

    private func selectPhoto(_ photo: Photo) {
        guard selectedPhoto == nil else { return }
        selectedPhoto = photo
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

private struct PhotoFormatSection: View {
    let title: String
    let format: PhotoFormat
    let photos: [Photo]
    let compactColumns: [GridItem]
    let onSelect: (Photo) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)

            if format == .horizontal {
                LazyVStack(spacing: 10) {
                    ForEach(photos) { photo in
                        PhotoCell(photo: photo, aspectRatio: format.displayAspectRatio)
                            .onTapGesture {
                                onSelect(photo)
                            }
                    }
                }
            } else {
                LazyVGrid(columns: compactColumns, spacing: 10) {
                    ForEach(photos) { photo in
                        PhotoCell(photo: photo, aspectRatio: format.displayAspectRatio)
                            .onTapGesture {
                                onSelect(photo)
                            }
                    }
                }
            }
        }
    }
}

struct PhotoCell: View {
    
    let photo: Photo
    let aspectRatio: Double
    
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
        .aspectRatio(aspectRatio, contentMode: .fit)
        .frame(maxWidth: .infinity)
        .clipped()
        .cornerRadius(8)
    }
}
