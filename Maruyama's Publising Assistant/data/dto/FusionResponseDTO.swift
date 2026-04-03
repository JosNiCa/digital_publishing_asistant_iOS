//
//  FusionResponseDTO.swift
//  Maruyama's Publising Assistant
//
//  Created by LJD Technology on 01/04/26.
//

struct FusionResponseDTO: Decodable {
    let ok: Bool
    let data: FusionDataDTO
}; extension FusionResponseDTO {
    func toDomain() -> FusionResult {
        FusionResult(imageBase64: data.image)
    }
}

struct FusionDataDTO: Decodable {
    let image: String
}
