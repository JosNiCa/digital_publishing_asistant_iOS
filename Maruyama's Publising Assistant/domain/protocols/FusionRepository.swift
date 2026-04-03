//
//  FusionRepository.swift
//  Maruyama's Publising Assistant
//
//  Created by LJD Technology on 01/04/26.
//

protocol FusionRepository {
    func applyFusion(
        photoId: Int,
        distributorId: Int,
        coordinate: Int
    ) async throws -> FusionResult
}
