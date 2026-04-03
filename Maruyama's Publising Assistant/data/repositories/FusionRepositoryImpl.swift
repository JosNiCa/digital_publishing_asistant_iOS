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
            requiresAuth: true // ⚠️ IMPORTANTE
        )
        
        return dto.toDomain()
    }
}