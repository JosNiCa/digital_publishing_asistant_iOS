//
//  PublishResponseDTO.swift
//  Maruyama's Publising Assistant
//
//  Created by LJD Technology on 15/04/26.
//

struct PublishResponseDTO: Decodable {
    let success: Bool
    let partialFailure: Bool?
    let scheduled: Bool?
    let platforms: [String]?
    let results: [String: PublishPlatformResultDTO]?
    let message: String?
}

struct PublishPlatformResultDTO: Decodable {
    let success: Bool?
    let platform: String?
    let scheduled: Bool?
    let message: String?
}

struct DeletePublishedPostRequestDTO: Encodable {
    let fusionId: Int

    enum CodingKeys: String, CodingKey {
        case fusionId = "fusion_id"
    }
}

struct DeletePublishedPostResponseDTO: Decodable {
    let success: Bool
    let message: String?
}
