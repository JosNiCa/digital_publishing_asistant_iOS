//
//  PublishingRepositoryImpl.swift
//  Maruyama's Publising Assistant
//
//  Created by LJD Technology on 15/04/26.
//

final class PublishingRepositoryImpl: PublishingRepository {

    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func publishFusion(
        fusionId: Int,
        caption: String,
        scheduledTime: Int?
    ) async throws {

        let body = PublishRequestDTO(
            idFusion: fusionId,
            caption: caption,
            scheduledTime: scheduledTime
        )

        let response: PublishResponseDTO = try await apiClient.request(
            endpoint: .publishFusion,
            body: body,
            requiresAuth: true
        )
	
        guard response.success else {
            throw APIError.serverError(
                code: nil,
                message: response.message
            )
        }
    }
    
    func verifyConnection() async throws -> ConnectionStatus {
        let response: ConnectionResponseDTO = try await apiClient.request(
            endpoint: .verifyConnection,
            requiresAuth: true
        )

        return ConnectionStatus(
            isConnected: response.facebookConnected || response.instagramConnected
        )
    }
}
