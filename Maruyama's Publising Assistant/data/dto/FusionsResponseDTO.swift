//
//  FusionsResponseDTO.swift
//  Maruyama's Publising Assistant
//
//  Created by LJD Technology on 01/05/26.
//

import Foundation

struct FusionsResponseDTO: Decodable {
    let ok: Bool
    let data: FusionsDataDTO
}

struct FusionsDataDTO: Decodable {
    let pendientes: [FusionItemDTO]
    let agendadas: [FusionItemDTO]
    let publicadas: [FusionItemDTO]
}; extension FusionsDataDTO {
    func toDomain() -> FusionGroups {
        FusionGroups(
            pendientes: pendientes.map { $0.toDomain() },
            agendadas: agendadas.map { $0.toDomain() },
            publicadas: publicadas.map { $0.toDomain() }
        )
    }
}

struct FusionItemDTO: Decodable {
    let id: Int
    let photoId: Int
    let distributorName: String
    let coordenada: Int
    let fechaPublicacion: String?
    let thumbnailUrl: String
    let productoNombre: String
    let formato: String
}; extension FusionItemDTO {
    func toDomain() -> FusionItem {
        FusionItem(
            id: id,
            photoId: photoId,
            distributorName: distributorName,
            coordenada: coordenada,
            fechaPublicacion: fechaPublicacion.flatMap(Self.parseDate),
            thumbnailUrl: thumbnailUrl,
            productoNombre: productoNombre,
            formato: formato
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
