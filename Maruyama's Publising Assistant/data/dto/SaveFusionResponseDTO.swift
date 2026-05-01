//
//  SaveFusionResponseDTO.swift
//  Maruyama's Publising Assistant
//
//  Created by LJD Technology on 29/04/26.
//

import Foundation

struct SaveFusionResponseDTO: Decodable {
    let ok: Bool
    let data: SaveFusionDataDTO
    let error: String?
}

struct SaveFusionDataDTO: Decodable {
    let idFusion: Int
}
