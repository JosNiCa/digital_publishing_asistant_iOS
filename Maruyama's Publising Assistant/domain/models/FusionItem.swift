//
//  FusionItem.swift
//  Maruyama's Publising Assistant
//
//  Created by LJD Technology on 01/05/26.
//

import SwiftUI

struct FusionItem: Identifiable, Hashable {
    let id: Int
    let photoId: Int
    let distributorName: String
    let coordenada: Int
    let caption: String?
    let fechaPublicacion: Date?
    let thumbnailUrl: String
    let productoNombre: String
    let formato: String
}
