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
        let dtos: [PhotoDTO] = try await apiClient.request(
            endpoint: .getPhotos,
            requiresAuth: false
        )
        
        return dtos.map { $0.toDomain() }
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
