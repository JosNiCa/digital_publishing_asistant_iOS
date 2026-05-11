//
//  PhotoDTO.swift
//  Maruyama's Publising Assistant
//
//  Created by LJD Technology on 26/03/26.
//

struct PhotoDTO: Decodable {
    let id: Int
    let imageUrl: String
    let width: Int?
    let height: Int?
    let coordinates: [PhotoCoordinateDTO]?
}

extension PhotoDTO {
    func toDomain() -> Photo {
        Photo(
            id: id,
            imageUrl: imageUrl,
            width: width,
            height: height,
            coordinates: coordinates?.map { $0.toDomain() } ?? []
        )
    }
}

struct PhotoCoordinateDTO: Decodable {
    let id: Int
    let x: Int
    let y: Int
}

extension PhotoCoordinateDTO {
    func toDomain() -> PhotoCoordinate {
        PhotoCoordinate(id: id, x: x, y: y)
    }
}
