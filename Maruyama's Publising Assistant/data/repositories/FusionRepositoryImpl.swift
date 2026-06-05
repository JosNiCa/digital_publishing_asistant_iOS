//
//  FusionRepositoryImpl.swift
//  Maruyama's Publising Assistant
//
//  Created by LJD Technology on 01/04/26.
//

final class FusionRepositoryImpl: FusionRepository {
    
    private let apiClient: APIClient
    
    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }
    
    func applyFusion(
        photoId: Int,
        logoId: Int,
        coordinate: Int,
        caption: String? = nil
    ) async throws -> FusionResult {
        
        let body = FusionRequestDTO(
            logoId: logoId,
            coordenada: coordinate,
            caption: caption
        )
        
        let dto: FusionResponseDTO = try await apiClient.request(
            endpoint: .fusionPreview(photoId: photoId),
            body: body,
            requiresAuth: false
        )
        
        return try dto.toDomain()
    }

    func saveFusion(
        photoId: Int,
        logoId: Int,
        coordinate: Int,
        caption: String? = nil
    ) async throws -> Int {
        let body = FusionRequestDTO(
            logoId: logoId,
            coordenada: coordinate,
            caption: caption
        )
        
        let response: SaveFusionResponseDTO = try await apiClient.request(
            endpoint: .fusionSave(photoId: photoId),
            body: body,
            requiresAuth: false
        )
        
        guard response.ok else {
            throw APIError.serverError(
                code: nil,
                message: response.error ?? "Error guardando fusión"
            )
        }
        
        return try response.fusionId()
    }

    func fetchFusionDetail(fusionId: Int) async throws -> FusionDetail {
        let response: FusionDetailResponseDTO = try await apiClient.request(
            endpoint: .fusionDetail(fusionId: fusionId),
            requiresAuth: false
        )

        return try response.toDomain()
    }
}
