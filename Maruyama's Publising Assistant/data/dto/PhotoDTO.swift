//
//  PhotoDTO.swift
//  Maruyama's Publising Assistant
//
//  Created by LJD Technology on 26/03/26.
//

struct PhotoDTO: Decodable {
    let id: Int
    let imageUrl: String
}

extension PhotoDTO {
    func toDomain() -> Photo {
        Photo(id: id, imageUrl: imageUrl)
    }
}
