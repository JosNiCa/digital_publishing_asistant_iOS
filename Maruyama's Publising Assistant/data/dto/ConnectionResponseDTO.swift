//
//  ConnectionResponseDTO.swift
//  Maruyama's Publising Assistant
//
//  Created by LJD Technology on 01/05/26.
//

import Foundation

struct ConnectionResponseDTO: Decodable {
    let success: Bool?
    let facebookConnected: Bool?
    let instagramConnected: Bool?
    let facebookPageId: String?
    let instagramUserId: String?
    let distribuidorId: Int?
    let error: String?
    let message: String?
}

struct ScheduledPostsResponseDTO: Decodable {
    let success: Bool
    let count: Int?
    let posts: [ScheduledPostDTO]?
    let pageId: String?
    let error: String?
    let message: String?
}

struct ScheduledPostDTO: Decodable {
    let id: String
    let message: String?
    let scheduledPublishTime: String?
    let createdTime: String?
    let permalinkUrl: String?
}

extension ScheduledPostDTO {
    func toDomain() -> ScheduledPost {
        ScheduledPost(
            id: id,
            message: message ?? "",
            scheduledPublishTime: scheduledPublishTime.flatMap(Self.parseDate),
            createdTime: createdTime.flatMap(Self.parseDate),
            permalinkUrl: permalinkUrl
        )
    }

    private nonisolated static func parseDate(_ value: String) -> Date? {
        let formatterWithFractionalSeconds = ISO8601DateFormatter()
        formatterWithFractionalSeconds.formatOptions = [
            .withInternetDateTime,
            .withFractionalSeconds
        ]

        return formatterWithFractionalSeconds.date(from: value)
            ?? ISO8601DateFormatter().date(from: value)
    }
}

struct PublishingHealthResponseDTO: Decodable {
    let status: String
    let service: String
    let timestamp: String?

    func toDomain() -> PublishingHealthStatus {
        PublishingHealthStatus(
            status: status,
            service: service,
            timestamp: timestamp
        )
    }
}
