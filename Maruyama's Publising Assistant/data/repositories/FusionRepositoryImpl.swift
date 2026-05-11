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
        distributorId: Int,
        coordinate: Int
    ) async throws -> FusionResult {
        
        let body = FusionRequestDTO(
            logo_id: distributorId,
            coordenada: coordinate
        )
        
        let dto: FusionResponseDTO = try await apiClient.request(
            endpoint: .fusionPreview(photoId: photoId),
            body: body,
            requiresAuth: true
        )
        
        return try dto.toDomain()
    }

    func saveFusion(
        photoId: Int,
        logoId: Int,
        coordinate: Int
    ) async throws -> Int {
        let body = FusionRequestDTO(
            logo_id: logoId,
            coordenada: coordinate
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
        
        return response.data.idFusion
    }
}
