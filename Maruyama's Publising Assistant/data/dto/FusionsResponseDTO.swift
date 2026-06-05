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
    let eliminadasRedes: [FusionItemDTO]?
}; extension FusionsDataDTO {
    func toDomain() -> FusionGroups {
        FusionGroups(
            pendientes: (pendientes ?? []).map { $0.toDomain() },
            agendadas: (agendadas ?? []).map { $0.toDomain() },
            publicadas: (publicadas ?? []).map { $0.toDomain() },
            eliminadasRedes: (eliminadasRedes ?? []).map { $0.toDomain() }
        )
    }
}

struct FusionItemDTO: Decodable {
    let id: Int
    let photoId: Int
    let distributorId: Int?
    let distributorName: String
    let coordenada: Int
    let caption: String?
    let fechaPublicacion: String?
    let thumbnailUrl: String
    let productoNombre: String
    let formato: String
    let formatoDisplay: String?
    let platform: PlatformDTO?
    let platforms: [PlatformDTO]?
    let publicada: Bool?
    let eliminadoDeRedes: Bool?
    let hasFacebookPost: Bool?
    let hasInstagramPost: Bool?
    let canDeletePost: Bool?

    private enum CodingKeys: String, CodingKey {
        case id
        case photoId
        case distributorId
        case distributorName
        case coordenada
        case caption
        case fechaPublicacion
        case thumbnailUrl
        case productoNombre
        case formato
        case formatoDisplay
        case platform
        case platforms
        case publicada
        case eliminadoDeRedes
        case hasFacebookPost
        case hasInstagramPost
        case canDeletePost
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(Int.self, forKey: .id)
        photoId = try container.decodeIfPresent(Int.self, forKey: .photoId) ?? 0
        distributorId = try container.decodeIfPresent(Int.self, forKey: .distributorId)
        distributorName = try container.decodeIfPresent(String.self, forKey: .distributorName) ?? "Distribuidor"
        coordenada = try container.decodeIfPresent(Int.self, forKey: .coordenada) ?? 0
        caption = try container.decodeIfPresent(String.self, forKey: .caption)
        fechaPublicacion = try container.decodeIfPresent(String.self, forKey: .fechaPublicacion)
        thumbnailUrl = try container.decodeIfPresent(String.self, forKey: .thumbnailUrl)
            ?? "/api/media_library/fusion/\(id)/thumbnail/"
        productoNombre = try container.decodeIfPresent(String.self, forKey: .productoNombre) ?? "Publicación"
        formato = try container.decodeIfPresent(String.self, forKey: .formato) ?? "Sin formato"
        formatoDisplay = try container.decodeIfPresent(String.self, forKey: .formatoDisplay)
        platform = try container.decodeIfPresent(PlatformDTO.self, forKey: .platform)
        platforms = try container.decodeIfPresent([PlatformDTO].self, forKey: .platforms)
        publicada = try container.decodeIfPresent(Bool.self, forKey: .publicada)
        eliminadoDeRedes = try container.decodeIfPresent(Bool.self, forKey: .eliminadoDeRedes)
        hasFacebookPost = try container.decodeIfPresent(Bool.self, forKey: .hasFacebookPost)
        hasInstagramPost = try container.decodeIfPresent(Bool.self, forKey: .hasInstagramPost)
        canDeletePost = try container.decodeIfPresent(Bool.self, forKey: .canDeletePost)
    }
}; extension FusionItemDTO {
    func toDomain() -> FusionItem {
        FusionItem(
            id: id,
            photoId: photoId,
            distributorId: distributorId,
            distributorName: distributorName,
            coordenada: coordenada,
            caption: caption,
            fechaPublicacion: fechaPublicacion.flatMap(Self.parseDate),
            thumbnailUrl: thumbnailUrl,
            productoNombre: productoNombre,
            formato: formato,
            formatoDisplay: formatoDisplay,
            platforms: displayPlatforms,
            publicada: publicada ?? false,
            eliminadoDeRedes: eliminadoDeRedes ?? false,
            hasFacebookPost: hasFacebookPost ?? false,
            hasInstagramPost: hasInstagramPost ?? false,
            canDeletePost: canDeletePost ?? false
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
