//
//  FusionRequestDTO.swift
//  Maruyama's Publising Assistant
//
//  Created by LJD Technology on 01/04/26.
//

struct FusionRequestDTO: Encodable {
    let logo_id: Int
    let coordenada: Int
    let caption: String?

    init(logoId: Int, coordenada: Int, caption: String? = nil) {
        self.logo_id = logoId
        self.coordenada = coordenada
        self.caption = caption
    }
}
