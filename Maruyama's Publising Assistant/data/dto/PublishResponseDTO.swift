//
//  PublishResponseDTO.swift
//  Maruyama's Publising Assistant
//
//  Created by LJD Technology on 15/04/26.
//

struct PublishResponseDTO: Decodable {
    let success: Bool
    let scheduled: Bool?
    let message: String?
}
