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
                message: response.message ?? "No se pudo publicar."
            )
        }
    }
    
    func verifyConnection() async throws -> ConnectionStatus {
        let response: ConnectionResponseDTO = try await apiClient.request(
            endpoint: .verifyConnection,
            requiresAuth: true
        )

        if response.success == false {
            return ConnectionStatus(
                isConnected: false,
                message: response.message
            )
        }

        let facebookConnected = response.facebookConnected ?? false
        let instagramConnected = response.instagramConnected ?? false

        return ConnectionStatus(
            isConnected: facebookConnected || instagramConnected,
            facebookConnected: facebookConnected,
            instagramConnected: instagramConnected,
            facebookPageId: response.facebookPageId,
            instagramUserId: response.instagramUserId,
            distributorId: response.distribuidorId,
            message: response.message
        )
    }

    func fetchScheduledPosts() async throws -> [ScheduledPost] {
        let response: ScheduledPostsResponseDTO = try await apiClient.request(
            endpoint: .scheduledPosts,
            requiresAuth: true
        )

        guard response.success else {
            throw APIError.serverError(
                code: response.error,
                message: response.message ?? "No se pudieron cargar publicaciones programadas."
            )
        }

        return (response.posts ?? []).map { $0.toDomain() }
    }

    func fetchHealthStatus() async throws -> PublishingHealthStatus {
        let response: PublishingHealthResponseDTO = try await apiClient.request(
            endpoint: .publishingHealth,
            requiresAuth: false
        )

        return response.toDomain()
    }
}
