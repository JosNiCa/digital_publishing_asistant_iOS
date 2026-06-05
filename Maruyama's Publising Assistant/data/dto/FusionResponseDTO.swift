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

struct FusionDetailResponseDTO: Decodable {
    let ok: Bool
    let data: FusionDetailDTO?
    let error: String?
}

struct FusionDetailDTO: Decodable {
    let image: String
    let photoId: Int
    let distributorId: Int
    let coordenada: Int
    let caption: String?
    let platform: PlatformDTO?
    let platforms: [PlatformDTO]?
}

extension FusionDetailResponseDTO {
    func toDomain() throws -> FusionDetail {
        guard ok, let data else {
            throw APIError.serverError(
                code: nil,
                message: error ?? "Error cargando la fusión"
            )
        }

        return FusionDetail(
            imageBase64: data.image,
            photoId: data.photoId,
            distributorId: data.distributorId,
            coordinate: data.coordenada,
            caption: data.caption,
            platforms: data.displayPlatforms
        )
    }
}

private extension FusionDetailDTO {
    var displayPlatforms: [PublishingPlatform] {
        if let platforms, !platforms.isEmpty {
            return platforms.map { $0.toDomain() }
        }

        return platform.map { [$0.toDomain()] } ?? []
    }
}
