//
//  PhotoViewerViewModel.swift
//  Maruyama's Publising Assistant
//
//  Created by LJD Technology on 28/03/26.
//

import Combine
import UIKit

struct LogoPositionOption: Identifiable {
    let id: Int
    let x: Int
    let y: Int
    let preview: FusionResult?
}

struct DistributorLogoOption: Identifiable, Hashable {
    let id: Int
    let distributorId: Int
    let distributorName: String
    let imageUrl: String
    let displayName: String
}

@MainActor
final class PhotoViewerViewModel: ObservableObject {

    let photo: Photo
    
    @Published var distributors: [Distributor] = []
    @Published var logoOptions: [DistributorLogoOption] = []
    @Published var fusionImageBase64: String?
    @Published var selectedLogoId: Int?
    @Published var selectedCoordinate: Int?
    @Published var isLoading = false
    @Published var isLoadingPositions = false
    @Published var errorMessage: String?
    @Published var shouldNavigateToPreview = false
    @Published var positionOptions: [LogoPositionOption] = []
    @Published var previewImageSize: CGSize?
    @Published var loadedPositionPreviewCount = 0
    @Published var totalPositionPreviewCount = 0

    private let distributorRepository: DistributorRepository
    private let fusionRepository: FusionRepository
    private var activePositionLoadID = UUID()
    private var fusionPreviewCache: [String: FusionResult] = [:]
    

    init(
        photo: Photo,
        distributorRepository: DistributorRepository,
        fusionRepository: FusionRepository
    ) {
        self.photo = photo
        self.distributorRepository = distributorRepository
        self.fusionRepository = fusionRepository
    }
    
    func loadDistributors() async {
        isLoading = true
        
        do {
            distributors = try await distributorRepository.fetchDistributors()
            logoOptions = Self.makeLogoOptions(from: distributors)
        } catch {
            errorMessage = "No se pudieron cargar distribuidores"
        }
        
        isLoading = false
    }

    func selectLogo(_ logo: DistributorLogoOption) async {
        selectedLogoId = logo.id
        selectedCoordinate = nil
        fusionImageBase64 = nil
        positionOptions = []
        previewImageSize = nil
        loadedPositionPreviewCount = 0
        totalPositionPreviewCount = 0
        errorMessage = nil

        await loadPositionOptions(for: logo.id)
    }

    func selectPosition(_ option: LogoPositionOption) async {
        selectedCoordinate = option.id
        errorMessage = nil

        if let preview = cachedPreview(for: option.id) ?? option.preview {
            fusionImageBase64 = preview.imageBase64
            previewImageSize = ImageDataDecoder.imageSize(fromBase64: preview.imageBase64) ?? previewImageSize
            return
        }

        await generateFusion(for: option.id)
    }
    
    func applyFusion() async {
        guard let coordinate = selectedCoordinate else { return }
        await generateFusion(for: coordinate)
    }

    private func generateFusion(for coordinate: Int) async {
        guard let logoId = selectedLogoId else { return }

        isLoading = true
        errorMessage = nil
        
        do {
            if let cachedPreview = cachedPreview(for: coordinate) {
                fusionImageBase64 = cachedPreview.imageBase64
                previewImageSize = ImageDataDecoder.imageSize(fromBase64: cachedPreview.imageBase64) ?? previewImageSize
                isLoading = false
                return
            }

            let result = try await fusionRepository.applyFusion(
                photoId: photo.id,
                logoId: logoId,
                coordinate: coordinate,
                caption: nil
            )
            
            cache(result, for: coordinate)
            self.fusionImageBase64 = result.imageBase64
            if let coordinate = result.coordinate,
               let x = result.x,
               let y = result.y,
               !positionOptions.contains(where: { $0.id == coordinate }) {
                positionOptions.append(
                    LogoPositionOption(
                        id: coordinate,
                        x: x,
                        y: y,
                        preview: result
                    )
                )
            }
            previewImageSize = ImageDataDecoder.imageSize(fromBase64: result.imageBase64)
            
        } catch {
            self.errorMessage = "Error al generar la imagen"
        }
        
        isLoading = false
    }
    
    func goToPreview() {
        guard fusionImageBase64 != nil,
              selectedLogoId != nil,
              selectedCoordinate != nil else {
            errorMessage = "Faltan datos para preview"
            return
        }

        shouldNavigateToPreview = true
    }

    private func loadPositionOptions(for logoId: Int) async {
        let loadID = UUID()
        activePositionLoadID = loadID
        isLoadingPositions = true

        if let knownOptions = knownPositionOptions() {
            positionOptions = knownOptions
            previewImageSize = knownImageSize
            totalPositionPreviewCount = knownOptions.count
            loadedPositionPreviewCount = knownOptions.count
            isLoadingPositions = false
            return
        }

        let coordinateIds = Array(1...3)
        let photoId = photo.id
        let fusionRepository = fusionRepository
        totalPositionPreviewCount = coordinateIds.count
        loadedPositionPreviewCount = 0

        let options = await withTaskGroup(of: LogoPositionOption?.self) { group in
            for coordinate in coordinateIds {
                group.addTask {
                    do {
                        let result = try await fusionRepository.applyFusion(
                            photoId: photoId,
                            logoId: logoId,
                            coordinate: coordinate,
                            caption: nil
                        )

                        guard let x = result.x,
                              let y = result.y,
                              let resultCoordinate = result.coordinate else {
                            return nil
                        }

                        return LogoPositionOption(
                            id: resultCoordinate,
                            x: x,
                            y: y,
                            preview: result
                        )
                    } catch {
                        return nil
                    }
                }
            }

            var loadedOptions: [LogoPositionOption] = []
            for await option in group {
                guard activePositionLoadID == loadID else {
                    return [LogoPositionOption]()
                }

                loadedPositionPreviewCount += 1

                if let option {
                    loadedOptions.append(option)
                }
            }

            return loadedOptions.sorted { $0.id < $1.id }
        }

        guard selectedLogoId == logoId,
              activePositionLoadID == loadID else {
            return
        }

        positionOptions = options
        previewImageSize = options.first?.preview.flatMap { ImageDataDecoder.imageSize(fromBase64: $0.imageBase64) }

        if options.isEmpty {
            errorMessage = "Esta imagen no tiene posiciones disponibles para el logo seleccionado"
        }

        isLoadingPositions = false
    }

    private var knownImageSize: CGSize? {
        guard let width = photo.width,
              let height = photo.height,
              width > 0,
              height > 0 else {
            return nil
        }

        return CGSize(width: width, height: height)
    }

    private func knownPositionOptions() -> [LogoPositionOption]? {
        guard !photo.coordinates.isEmpty,
              knownImageSize != nil else {
            return nil
        }

        return photo.coordinates
            .map {
                LogoPositionOption(
                    id: $0.id,
                    x: $0.x,
                    y: $0.y,
                    preview: cachedPreview(for: $0.id)
                )
            }
            .sorted { $0.id < $1.id }
    }

    private func cachedPreview(for coordinate: Int) -> FusionResult? {
        guard let logoId = selectedLogoId else { return nil }
        return fusionPreviewCache[cacheKey(logoId: logoId, coordinate: coordinate)]
    }

    private func cache(_ result: FusionResult, for coordinate: Int) {
        guard let logoId = selectedLogoId else { return }
        fusionPreviewCache[cacheKey(logoId: logoId, coordinate: coordinate)] = result
    }

    private func cacheKey(logoId: Int, coordinate: Int) -> String {
        "\(logoId)-\(coordinate)"
    }

    private static func makeLogoOptions(from distributors: [Distributor]) -> [DistributorLogoOption] {
        distributors.flatMap { distributor in
            distributor.logos.enumerated().map { index, logo in
                let displayName = distributor.logos.count > 1
                    ? "\(distributor.name) \(index + 1)"
                    : distributor.name

                return DistributorLogoOption(
                    id: logo.id,
                    distributorId: distributor.id,
                    distributorName: distributor.name,
                    imageUrl: logo.imageUrl,
                    displayName: displayName
                )
            }
        }
    }
}
