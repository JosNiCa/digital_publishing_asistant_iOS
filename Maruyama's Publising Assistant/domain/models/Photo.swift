//
//  Photo.swift
//  Maruyama's Publising Assistant
//
//  Created by LJD Technology on 26/03/26.
//

struct Photo: Identifiable, Hashable {
    let id: Int
    let imageUrl: String
    let width: Int?
    let height: Int?
    let coordinates: [PhotoCoordinate]

    init(
        id: Int,
        imageUrl: String,
        width: Int? = nil,
        height: Int? = nil,
        coordinates: [PhotoCoordinate] = []
    ) {
        self.id = id
        self.imageUrl = imageUrl
        self.width = width
        self.height = height
        self.coordinates = coordinates
    }
}

struct PhotoCoordinate: Identifiable, Hashable {
    let id: Int
    let x: Int
    let y: Int
}
