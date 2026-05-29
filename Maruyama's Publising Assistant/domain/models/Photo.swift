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
    let platform: PublishingPlatform?
    let platforms: [PublishingPlatform]
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
        platform: PublishingPlatform? = nil,
        platforms: [PublishingPlatform] = [],
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
        self.platform = platform
        self.platforms = platforms
        self.origin = origin
        self.createdAt = createdAt
        self.isInUse = isInUse
        self.state = state
        self.formatDisplay = formatDisplay
        self.productName = productName
        self.coordinates = coordinates
    }
}

struct PublishingPlatform: Identifiable, Hashable {
    let id: String
    let key: String
    let name: String
    let iconUrl: URL?

    init(key: String, name: String, iconUrl: URL?) {
        self.id = key
        self.key = key
        self.name = name
        self.iconUrl = iconUrl
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

enum PublishingPlatformFilter: String, CaseIterable, Identifiable {
    case all
    case instagram
    case facebook

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            return "Todas"
        case .instagram:
            return "Instagram"
        case .facebook:
            return "Facebook"
        }
    }

    var helperText: String {
        switch self {
        case .all:
            return ""
        case .instagram:
            return "Muestra imágenes marcadas por backend para Instagram."
        case .facebook:
            return "Muestra imágenes marcadas por backend para Facebook."
        }
    }
}

extension Photo {
    func isCompatible(with platform: PublishingPlatformFilter) -> Bool {
        guard platform != .all else {
            return true
        }

        if !destinationPlatforms.isEmpty {
            return destinationPlatforms.contains(platform)
        }

        switch platform {
        case .all:
            return true
        case .instagram:
            return [.semiVertical, .vertical].contains(format)
        case .facebook:
            return [.horizontal, .square].contains(format)
        }
    }

    var destinationPlatform: PublishingPlatformFilter? {
        guard let platform = primaryPlatform?.key.lowercased() else {
            return nil
        }

        switch platform {
        case "instagram":
            return .instagram
        case "facebook":
            return .facebook
        default:
            return nil
        }
    }

    var destinationPlatforms: Set<PublishingPlatformFilter> {
        let filters = platforms.compactMap {
            PublishingPlatformFilter(platformKey: $0.key)
        }

        if !filters.isEmpty {
            return Set(filters)
        }

        if let destinationPlatform {
            return [destinationPlatform]
        }

        return []
    }

    var primaryPlatform: PublishingPlatform? {
        platform ?? platforms.first
    }

    var platformDisplayName: String? {
        let names = displayPlatforms.map(\.name).filter { !$0.isEmpty }
        guard !names.isEmpty else { return nil }
        return names.joined(separator: " / ")
    }

    var displayPlatforms: [PublishingPlatform] {
        if !platforms.isEmpty {
            return platforms
        }

        return platform.map { [$0] } ?? []
    }

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

extension PublishingPlatformFilter {
    init?(platformKey: String) {
        switch platformKey.lowercased() {
        case "instagram":
            self = .instagram
        case "facebook":
            self = .facebook
        default:
            return nil
        }
    }
}
