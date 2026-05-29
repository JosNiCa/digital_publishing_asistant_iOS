//
//  FusionSession.swift
//  Maruyama's Publising Assistant
//
//  Created by LJD Technology on 29/04/26.
//

import Combine
import Foundation

@MainActor
final class FusionSession: ObservableObject {

    static let shared = FusionSession()

    @Published var fusionId: Int?
    @Published var photoId: Int?
    @Published var logoId: Int?
    @Published var coordinate: Int?

    func fusionId(
        matchingPhotoId photoId: Int,
        logoId: Int,
        coordinate: Int
    ) -> Int? {
        guard self.photoId == photoId,
              self.logoId == logoId,
              self.coordinate == coordinate else {
            return nil
        }

        return fusionId
    }

    func clear() {
        fusionId = nil
        photoId = nil
        logoId = nil
        coordinate = nil
    }
}

struct FusionPlatformSelection {
    let platforms: [PublishingPlatform]
    let selectedKeys: Set<String>
}

enum FusionPlatformCache {
    private static let storageKey = "fusion_platform_cache"

    static func save(
        platforms: [PublishingPlatform],
        selectedKeys: Set<String>,
        for fusionId: Int
    ) {
        guard !platforms.isEmpty else { return }

        var values = storedValues()
        values[String(fusionId)] = StoredSelection(
            platforms: platforms.map(StoredPlatform.init(platform:)),
            selectedKeys: Array(selectedKeys)
        )

        guard let data = try? JSONEncoder().encode(values) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    static func selection(for fusionId: Int) -> FusionPlatformSelection? {
        guard let value = storedValues()[String(fusionId)] else { return nil }

        let platforms = value.platforms.map {
            PublishingPlatform(
                key: $0.key,
                name: $0.name,
                iconUrl: $0.iconUrl.flatMap(URL.init(string:))
            )
        }

        guard !platforms.isEmpty else { return nil }

        return FusionPlatformSelection(
            platforms: platforms,
            selectedKeys: Set(value.selectedKeys)
        )
    }

    private static func storedValues() -> [String: StoredSelection] {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let values = try? JSONDecoder().decode([String: StoredSelection].self, from: data) else {
            return [:]
        }

        return values
    }
}

private struct StoredSelection: Codable {
    let platforms: [StoredPlatform]
    let selectedKeys: [String]
}

private struct StoredPlatform: Codable {
    let key: String
    let name: String
    let iconUrl: String?

    nonisolated init(platform: PublishingPlatform) {
        key = platform.key
        name = platform.name
        iconUrl = platform.iconUrl?.absoluteString
    }
}
