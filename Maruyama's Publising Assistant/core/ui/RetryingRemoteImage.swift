//
//  RetryingRemoteImage.swift
//  Maruyama's Publising Assistant
//
//  Created by Codex on 26/05/26.
//

import SwiftUI
import UIKit

enum RetryingRemoteImageState {
    case loading
    case success(UIImage)
    case failure
}

struct RetryingRemoteImage<Content: View>: View {
    let url: URL?
    let maxRetries: Int
    let onSuccess: () -> Void
    let onFinalFailure: () -> Void
    @ViewBuilder let content: (RetryingRemoteImageState, @escaping () -> Void) -> Content

    @State private var state: RetryingRemoteImageState = .loading
    @State private var loadID = UUID()

    init(
        url: URL?,
        maxRetries: Int = 3,
        onSuccess: @escaping () -> Void = {},
        onFinalFailure: @escaping () -> Void = {},
        @ViewBuilder content: @escaping (RetryingRemoteImageState, @escaping () -> Void) -> Content
    ) {
        self.url = url
        self.maxRetries = maxRetries
        self.onSuccess = onSuccess
        self.onFinalFailure = onFinalFailure
        self.content = content
    }

    var body: some View {
        content(state, retry)
            .task(id: loadID) {
                await loadImage()
            }
            .onChange(of: url) { _, _ in
                state = .loading
                loadID = UUID()
            }
    }

    private func retry() {
        state = .loading
        loadID = UUID()
    }

    private func loadImage() async {
        guard let url else {
            await MainActor.run {
                state = .failure
                onFinalFailure()
            }
            return
        }

        if let cachedImage = RemoteImageCache.shared.image(for: url) {
            await MainActor.run {
                state = .success(cachedImage)
                onSuccess()
            }
            return
        }

        let delays: [UInt64] = [150_000_000, 350_000_000, 650_000_000]
        for attempt in 0...maxRetries {
            if Task.isCancelled { return }

            if let image = await RemoteImageLoader.image(from: url) {
                await MainActor.run {
                    state = .success(image)
                    onSuccess()
                }
                return
            }

            guard attempt < maxRetries else { break }
            let delay = delays[min(attempt, delays.count - 1)]
            try? await Task.sleep(nanoseconds: delay)
        }

        await MainActor.run {
            state = .failure
            onFinalFailure()
        }
    }
}

private enum RemoteImageLoader {
    static func image(from url: URL) async -> UIImage? {
        if let cachedImage = RemoteImageCache.shared.image(for: url) {
            return cachedImage
        }

        var request = URLRequest(url: url)
        request.cachePolicy = .returnCacheDataElseLoad
        request.timeoutInterval = 12

        guard
            let (data, response) = try? await URLSession.shared.data(for: request),
            let httpResponse = response as? HTTPURLResponse,
            (200..<300).contains(httpResponse.statusCode),
            let image = UIImage(data: data)
        else {
            return nil
        }

        RemoteImageCache.shared.setImage(image, for: url)
        return image
    }
}

private final class RemoteImageCache {
    static let shared = RemoteImageCache()

    private let cache = NSCache<NSURL, UIImage>()

    private init() {
        cache.countLimit = 220
        cache.totalCostLimit = 90 * 1024 * 1024
    }

    func image(for url: URL) -> UIImage? {
        cache.object(forKey: url as NSURL)
    }

    func setImage(_ image: UIImage, for url: URL) {
        let cost = Int(image.size.width * image.size.height * image.scale * image.scale * 4)
        cache.setObject(image, forKey: url as NSURL, cost: cost)
    }
}
