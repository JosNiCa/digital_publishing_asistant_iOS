//
//  ConnectionResponseDTO.swift
//  Maruyama's Publising Assistant
//
//  Created by LJD Technology on 01/05/26.
//

struct ConnectionResponseDTO: Decodable {
    let success: Bool?
    let facebookConnected: Bool?
    let instagramConnected: Bool?
    let facebookPageId: String?
    let instagramUserId: String?
    let userId: Int?
    let error: String?
    let message: String?
}
