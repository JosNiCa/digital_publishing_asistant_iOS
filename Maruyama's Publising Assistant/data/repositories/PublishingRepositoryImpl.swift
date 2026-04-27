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

        let body: [String: Any] = [
            "id_fusion": fusionId,
            "caption": caption,
            "scheduled_time": scheduledTime as Any
        ]

        let response: PublishResponseDTO = try await apiClient.request(
            endpoint: .publishFusion,
            body: body
        )
	
        guard response.success else {
            throw APIError.networkError(<#T##any Error#>)
        }
    }
}
