//
//  SaveFusionResponseDTO.swift
//  Maruyama's Publising Assistant
//
//  Created by LJD Technology on 29/04/26.
//

import Foundation

struct SaveFusionResponseDTO: Decodable {
    let ok: Bool
    let idFusion: Int?
    let data: SaveFusionDataDTO?
    let error: String?

    func fusionId() throws -> Int {
        if let idFusion {
            return idFusion
        }

        if let idFusion = data?.idFusion {
            return idFusion
        }

        throw APIError.serverError(
            code: nil,
            message: error ?? "La respuesta no incluyó el ID de la fusión"
        )
    }
}

struct SaveFusionDataDTO: Decodable {
    let idFusion: Int
    let caption: String?
    let mensaje: String?
}
