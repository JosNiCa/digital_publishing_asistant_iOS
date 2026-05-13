//
//  MediaRepositoryImpl.swift
//  Maruyama's Publising Assistant
//
//  Created by LJD Technology on 26/03/26.
//

final class MediaRepositoryImpl: MediaRepository {
    private let apiClient: APIClient
    
    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }
    
    func fetchPhotos() async throws -> [Photo] {
        var page = 1
        var photos: [Photo] = []

        while true {
            let response: PhotosResponseDTO = try await apiClient.request(
                endpoint: .getPhotos(page: page, pageSize: 100),
                requiresAuth: false
            )

            photos.append(contentsOf: response.results.map { $0.toDomain() })

            guard response.next != nil else {
                return photos
            }

            page += 1
        }
    }
    
    func fetchFusions() async throws -> FusionGroups {
        let response: FusionsResponseDTO = try await apiClient.request(
            endpoint: .fusionsList,
            requiresAuth: false
        )
        
        guard response.ok, let data = response.data else {
            throw APIError.serverError(
                code: nil,
                message: response.error ?? "Error cargando fusiones"
            )
        }

        return data.toDomain()
    }
}
