//
//  Photo.swift
//  Maruyama's Publising Assistant
//
//  Created by LJD Technology on 26/03/26.
//

import Foundation

struct Photo: Identifiable, Hashable {
    let id: Int
    let imageUrl: String
    let width: Int?
    let height: Int?
    let serverFormat: String?
    let origin: String?
    let createdAt: String?
    let isInUse: Bool?
    let state: String?
    let formatDisplay: String?
    let productName: String?
    let coordinates: [PhotoCoordinate]

    init(
        id: Int,
        imageUrl: String,
        width: Int? = nil,
        height: Int? = nil,
        serverFormat: String? = nil,
        origin: String? = nil,
        createdAt: String? = nil,
        isInUse: Bool? = nil,
        state: String? = nil,
        formatDisplay: String? = nil,
        productName: String? = nil,
        coordinates: [PhotoCoordinate] = []
    ) {
        self.id = id
        self.imageUrl = imageUrl
        self.width = width
        self.height = height
        self.serverFormat = serverFormat
        self.origin = origin
        self.createdAt = createdAt
        self.isInUse = isInUse
        self.state = state
        self.formatDisplay = formatDisplay
        self.productName = productName
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

    var filterTitle: String {
        switch self {
        case .horizontal:
            return "Horizontal"
        case .square:
            return "Cuadrado"
        case .semiVertical:
            return "Semivertical"
        case .vertical:
            return "Vertical"
        case .unknown:
            return "Sin formato"
        }
    }

    static var filterableCases: [PhotoFormat] {
        [.horizontal, .square, .semiVertical, .vertical, .unknown]
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
    var createdDate: Date? {
        guard let createdAt else {
            return nil
        }

        return Self.dateFormatter.date(from: createdAt)
    }

    var format: PhotoFormat {
        if let serverFormat {
            switch serverFormat.lowercased() {
            case "horizontal":
                return .horizontal
            case "cuadrado", "square":
                return .square
            case "semivertical", "semi_vertical", "semi-vertical":
                return .semiVertical
            case "vertical":
                return .vertical
            default:
                break
            }
        }

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

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
