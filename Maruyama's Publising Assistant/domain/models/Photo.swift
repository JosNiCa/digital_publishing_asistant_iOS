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

enum PhotoFormat: String, CaseIterable {
    case horizontal
    case square
    case semiVertical
    case vertical
    case unknown

    var title: String {
        switch self {
        case .horizontal:
            return "Horizontales"
        case .square:
            return "Cuadradas"
        case .semiVertical:
            return "Semiverticales"
        case .vertical:
            return "Verticales"
        case .unknown:
            return "Sin formato"
        }
    }

    var displayAspectRatio: Double {
        switch self {
        case .horizontal:
            return 16.0 / 9.0
        case .square:
            return 1
        case .semiVertical:
            return 4.0 / 5.0
        case .vertical:
            return 3.0 / 4.0
        case .unknown:
            return 1
        }
    }
}

extension Photo {
    var format: PhotoFormat {
        guard let width, let height, height > 0 else {
            return .unknown
        }

        let ratio = Double(width) / Double(height)

        switch ratio {
        case 1.15...:
            return .horizontal
        case 0.92..<1.15:
            return .square
        case 0.72..<0.92:
            return .semiVertical
        default:
            return .vertical
        }
    }
}
