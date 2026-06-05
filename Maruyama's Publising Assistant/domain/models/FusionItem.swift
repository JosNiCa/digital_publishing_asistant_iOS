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
    let distributorId: Int?
    let distributorName: String
    let coordenada: Int
    let caption: String?
    let fechaPublicacion: Date?
    let thumbnailUrl: String
    let productoNombre: String
    let formato: String
    let formatoDisplay: String?
    let platforms: [PublishingPlatform]
    let publicada: Bool
    let eliminadoDeRedes: Bool
    let hasFacebookPost: Bool
    let hasInstagramPost: Bool
    let canDeletePost: Bool

    var displayFormat: String {
        formatoDisplay ?? formato
    }

    var platformDisplayName: String? {
        let names = platforms.map(\.name).filter { !$0.isEmpty }
        guard !names.isEmpty else { return nil }
        return names.joined(separator: " / ")
    }
}
