//
//  DistributorRepositoryImpl.swift
//  Maruyama's Publising Assistant
//
//  Created by LJD Technology on 30/03/26.
//


final class DistributorRepositoryImpl: DistributorRepository {
    
    private let apiClient: APIClient
    
    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }
    
    func fetchDistributors() async throws -> [Distributor] {
        let dtos: [DistributorDTO] = try await apiClient.request(
            endpoint: .getDistributors,
            requiresAuth: false
        )
        
        let distributors = dtos.map { $0.toDomain() }
        let session = await MainActor.run {
            (
                isAdmin: SessionManager.shared.isAdmin,
                distributorId: SessionManager.shared.distributorId
            )
        }

        guard !session.isAdmin, let distributorId = session.distributorId else {
            return distributors
        }

        return distributors.filter { $0.id == distributorId }
    }
}
