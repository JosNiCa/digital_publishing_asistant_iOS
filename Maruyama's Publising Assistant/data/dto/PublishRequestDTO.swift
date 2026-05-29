//
//  PublishRequestDTO.swift
//  Maruyama's Publising Assistant
//
//  Created by LJD Technology on 28/04/26.
//

struct PublishRequestDTO: Encodable {
    let idFusion: Int
    let caption: String
    let scheduledTime: Int?
    let platforms: [String]?
    
    enum CodingKeys: String, CodingKey {
        case idFusion = "id_fusion"
        case caption
        case scheduledTime = "scheduled_time"
        case platforms
    }
}
