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
        scheduledTime: Int?,
        platforms: [String]?
    ) async throws
    
    func verifyConnection() async throws -> ConnectionStatus

    func fetchScheduledPosts() async throws -> [ScheduledPost]

    func fetchHealthStatus() async throws -> PublishingHealthStatus
}
