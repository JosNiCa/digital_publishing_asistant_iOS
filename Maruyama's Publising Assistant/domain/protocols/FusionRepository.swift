//
//  FusionRepository.swift
//  Maruyama's Publising Assistant
//
//  Created by LJD Technology on 01/04/26.
//

protocol FusionRepository {
    func applyFusion(
        photoId: Int,
        logoId: Int,
        coordinate: Int,
        caption: String?
    ) async throws -> FusionResult
    
    func saveFusion(
        photoId: Int,
        logoId: Int,
        coordinate: Int,
        caption: String?
    ) async throws -> Int

    func fetchFusionDetail(fusionId: Int) async throws -> FusionDetail
}
