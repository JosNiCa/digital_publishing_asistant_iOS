//
//  FusionsResponseDTO.swift
//  Maruyama's Publising Assistant
//
//  Created by LJD Technology on 01/05/26.
//

import Foundation

struct FusionsResponseDTO: Decodable {
    let ok: Bool
    let data: FusionsDataDTO?
    let error: String?
}

struct FusionsDataDTO: Decodable {
    let pendientes: [FusionItemDTO]?
    let agendadas: [FusionItemDTO]?
    let publicadas: [FusionItemDTO]?
}; extension FusionsDataDTO {
    func toDomain() -> FusionGroups {
        FusionGroups(
            pendientes: (pendientes ?? []).map { $0.toDomain() },
            agendadas: (agendadas ?? []).map { $0.toDomain() },
            publicadas: (publicadas ?? []).map { $0.toDomain() }
        )
    }
}

struct FusionItemDTO: Decodable {
    let id: Int
    let photoId: Int
    let distributorName: String
    let coordenada: Int
    let caption: String?
    let fechaPublicacion: String?
    let thumbnailUrl: String
    let productoNombre: String
    let formato: String
    let platform: PlatformDTO?
    let platforms: [PlatformDTO]?
}; extension FusionItemDTO {
    func toDomain() -> FusionItem {
        FusionItem(
            id: id,
            photoId: photoId,
            distributorName: distributorName,
            coordenada: coordenada,
            caption: caption,
            fechaPublicacion: fechaPublicacion.flatMap(Self.parseDate),
            thumbnailUrl: thumbnailUrl,
            productoNombre: productoNombre,
            formato: formato,
            platforms: displayPlatforms
        )
    }

    private nonisolated static func parseDate(_ value: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [
            .withInternetDateTime,
            .withFractionalSeconds
        ]

        return formatter.date(from: value)
            ?? ISO8601DateFormatter().date(from: value)
    }
}

private extension FusionItemDTO {
    var displayPlatforms: [PublishingPlatform] {
        if let platforms, !platforms.isEmpty {
            return platforms.map { $0.toDomain() }
        }

        return platform.map { [$0.toDomain()] } ?? []
    }
}
