//
//  PhotoListViewModel.swift
//  Maruyama's Publising Assistant
//
//  Created by LJD Technology on 26/03/26.
//

import Combine

@MainActor
final class PhotoListViewModel: ObservableObject {

    @Published var photos: [Photo] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let mediaRepository: MediaRepository

    init(mediaRepository: MediaRepository) {
        self.mediaRepository = mediaRepository
    }

    func loadPhotos() async {
        if photos.isEmpty {
            isLoading = true
        }
        
        errorMessage = nil

        do {
            photos = try await mediaRepository.fetchPhotos()
        } catch {
            errorMessage = "Error al cargar imágenes"
        }

        isLoading = false
    }

    func refresh() async {
        await loadPhotos()
    }
}
