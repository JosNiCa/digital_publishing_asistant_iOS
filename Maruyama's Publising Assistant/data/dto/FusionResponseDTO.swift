//
//  FusionResponseDTO.swift
//  Maruyama's Publising Assistant
//
//  Created by LJD Technology on 01/04/26.
//

struct FusionResponseDTO: Decodable {
    let ok: Bool
    let data: FusionDataDTO?
    let error: String?
}; extension FusionResponseDTO {
    func toDomain() throws -> FusionResult {
        guard ok, let data else {
            throw APIError.serverError(
                code: nil,
                message: error ?? "Error generando preview"
            )
        }

        return FusionResult(
            imageBase64: data.image,
            x: data.x,
            y: data.y,
            coordinate: data.coordenada
        )
    }
}

struct FusionDataDTO: Decodable {
    let image: String
    let x: Int?
    let y: Int?
    let coordenada: Int?
}
