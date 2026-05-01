//
//  PublishingRepository.swift
//  Maruyama's Publising Assistant
//
//  Created by LJD Technology on 15/04/26.
//

protocol PublishingRepository {
    func publishFusion(
        fusionId: Int,
        caption: String,
        scheduledTime: Int?
    ) async throws
    
    func verifyConnection() async throws -> ConnectionStatus
}
