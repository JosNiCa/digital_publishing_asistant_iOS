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
        
        return dtos.map { $0.toDomain() }
    }
}