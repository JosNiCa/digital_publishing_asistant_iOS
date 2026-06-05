//
//  MediaRepositoryImpl.swift
//  Maruyama's Publising Assistant
//
//  Created by LJD Technology on 26/03/26.
//

import Foundation

final class MediaRepositoryImpl: MediaRepository {
    private let apiClient: APIClient
    
    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }
    
    func fetchPhotos() async throws -> [Photo] {
        var page = 1
        var photos: [Photo] = []
        let session = await MainActor.run {
            (
                isLoggedIn: SessionManager.shared.isLoggedIn,
                isAdmin: SessionManager.shared.isAdmin
            )
        }

        while true {
            let response: PhotosResponseDTO = try await apiClient.request(
                endpoint: .getPhotos(page: page, pageSize: 100, includeAllStates: session.isAdmin),
                sendsAuthIfAvailable: session.isLoggedIn
            )

            photos.append(contentsOf: response.results.map { $0.toDomain() })

            guard response.next != nil else {
                return photos
            }

            page += 1
        }
    }
    
    func fetchFusions() async throws -> FusionGroups {
        let isLoggedIn = await MainActor.run {
            SessionManager.shared.isLoggedIn
        }

        let response: FusionsResponseDTO
        do {
            response = try await fetchFusionsResponse(sendsAuthIfAvailable: isLoggedIn)
        } catch {
            guard isLoggedIn, Self.isFusionThumbnailReverseError(error) else {
                throw error
            }

            response = try await fetchFusionsResponse(sendsAuthIfAvailable: false)
        }

        guard response.ok, let data = response.data else {
            if isLoggedIn, Self.isFusionThumbnailReverseMessage(response.error) {
                let publicResponse = try await fetchFusionsResponse(sendsAuthIfAvailable: false)
                guard publicResponse.ok, let publicData = publicResponse.data else {
                    throw APIError.serverError(
                        code: nil,
                        message: publicResponse.error ?? response.error ?? "Error cargando fusiones"
                    )
                }

                return publicData.toDomain()
            }

            throw APIError.serverError(
                code: nil,
                message: response.error ?? "Error cargando fusiones"
            )
        }

        return data.toDomain()
    }

    private func fetchFusionsResponse(sendsAuthIfAvailable: Bool) async throws -> FusionsResponseDTO {
        try await apiClient.request(
            endpoint: .fusionsList,
            sendsAuthIfAvailable: sendsAuthIfAvailable
        )
    }

    private static func isFusionThumbnailReverseError(_ error: Error) -> Bool {
        if let apiError = error as? APIError,
           case .serverError(_, let message) = apiError {
            return isFusionThumbnailReverseMessage(message)
        }

        return isFusionThumbnailReverseMessage(error.localizedDescription)
    }

    private static func isFusionThumbnailReverseMessage(_ message: String?) -> Bool {
        guard let message else { return false }

        return message.contains("fusion_thumbnail")
            && message.localizedCaseInsensitiveContains("reverse")
    }
}
