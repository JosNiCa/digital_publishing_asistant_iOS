//
//  PhotoDTO.swift
//  Maruyama's Publising Assistant
//
//  Created by LJD Technology on 26/03/26.
//

import Foundation

struct PhotosResponseDTO: Decodable {
    let count: Int?
    let next: String?
    let previous: String?
    let results: [PhotoDTO]

    private enum CodingKeys: String, CodingKey {
        case count
        case next
        case previous
        case results
    }

    init(from decoder: Decoder) throws {
        if let container = try? decoder.singleValueContainer(),
           let photos = try? container.decode([PhotoDTO].self) {
            self.count = photos.count
            self.next = nil
            self.previous = nil
            self.results = photos
            return
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.count = try container.decodeIfPresent(Int.self, forKey: .count)
        self.next = try container.decodeIfPresent(String.self, forKey: .next)
        self.previous = try container.decodeIfPresent(String.self, forKey: .previous)
        self.results = try container.decode([PhotoDTO].self, forKey: .results)
    }
}

struct PlatformDTO: Decodable {
    let key: String
    let name: String
    let iconUrl: String?

    private enum CodingKeys: String, CodingKey {
        case key
        case name
        case iconUrl
        case iconUrlSnake = "icon_url"
    }

    init(from decoder: Decoder) throws {
        if let container = try? decoder.singleValueContainer(),
           let key = try? container.decode(String.self) {
            self.key = key
            self.name = key
            self.iconUrl = nil
            return
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.key = try container.decode(String.self, forKey: .key)
        self.name = try container.decode(String.self, forKey: .name)
        self.iconUrl = try container.decodeIfPresent(String.self, forKey: .iconUrl)
            ?? container.decodeIfPresent(String.self, forKey: .iconUrlSnake)
    }
}

struct PhotoDTO: Decodable {
    let id: Int
    let imageUrl: String
    let width: Int?
    let height: Int?
    let formato: String?
    let platform: PlatformDTO?
    let platforms: [PlatformDTO]?
    let origen: String?
    let fechaCarga: String?
    let enUso: Bool?
    let estado: String?
    let coordinates: [PhotoCoordinateDTO]?
    let formatoDisplay: String?
    let producto: String?

    private enum CodingKeys: String, CodingKey {
        case id
        case imageUrl
        case imageURL = "image_url"
        case width
        case height
        case formato
        case platform
        case platforms
        case origen
        case fechaCarga
        case fechaCargaSnake = "fecha_carga"
        case enUso
        case enUsoSnake = "en_uso"
        case estado
        case coordinates
        case formatoDisplay
        case formatoDisplaySnake = "formato_display"
        case producto
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(Int.self, forKey: .id)
        self.imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
            ?? container.decode(String.self, forKey: .imageURL)
        self.width = try container.decodeIfPresent(Int.self, forKey: .width)
        self.height = try container.decodeIfPresent(Int.self, forKey: .height)
        self.formato = try container.decodeIfPresent(String.self, forKey: .formato)
        self.platform = try container.decodeIfPresent(PlatformDTO.self, forKey: .platform)
        self.platforms = try container.decodeIfPresent([PlatformDTO].self, forKey: .platforms)
        self.origen = try container.decodeIfPresent(String.self, forKey: .origen)
        self.fechaCarga = try container.decodeIfPresent(String.self, forKey: .fechaCarga)
            ?? container.decodeIfPresent(String.self, forKey: .fechaCargaSnake)
        self.enUso = try container.decodeIfPresent(Bool.self, forKey: .enUso)
            ?? container.decodeIfPresent(Bool.self, forKey: .enUsoSnake)
        self.estado = try container.decodeIfPresent(String.self, forKey: .estado)
        self.coordinates = try container.decodeIfPresent([PhotoCoordinateDTO].self, forKey: .coordinates)
        self.formatoDisplay = try container.decodeIfPresent(String.self, forKey: .formatoDisplay)
            ?? container.decodeIfPresent(String.self, forKey: .formatoDisplaySnake)
        self.producto = try container.decodeIfPresent(String.self, forKey: .producto)
    }
}

extension PlatformDTO {
    func toDomain() -> PublishingPlatform {
        PublishingPlatform(
            key: key,
            name: name,
            iconUrl: iconUrl.flatMap(URL.init(string:))
        )
    }
}

extension PhotoDTO {
    func toDomain() -> Photo {
        Photo(
            id: id,
            imageUrl: imageUrl,
            width: width,
            height: height,
            serverFormat: formato,
            platform: platform?.toDomain(),
            platforms: (platforms ?? []).map { $0.toDomain() },
            origin: origen,
            createdAt: fechaCarga,
            isInUse: enUso,
            state: estado,
            formatDisplay: formatoDisplay,
            productName: producto,
            coordinates: coordinates?.compactMap { $0.toDomain() } ?? []
        )
    }
}

struct PhotoCoordinateDTO: Decodable {
    let id: Int
    let x: Int?
    let y: Int?
}

extension PhotoCoordinateDTO {
    func toDomain() -> PhotoCoordinate? {
        guard let x, let y else {
            return nil
        }

        return PhotoCoordinate(id: id, x: x, y: y)
    }
}
