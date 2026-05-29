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
    let preview: FusionResult
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

    func selectPosition(_ option: LogoPositionOption) {
        selectedCoordinate = option.id
        fusionImageBase64 = option.preview.imageBase64

        if previewImageSize == nil {
            previewImageSize = ImageDataDecoder.imageSize(fromBase64: option.preview.imageBase64)
        }
    }
    
    func applyFusion() async {
        guard let logoId = selectedLogoId,
              let coordinate = selectedCoordinate else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await fusionRepository.applyFusion(
                photoId: photo.id,
                logoId: logoId,
                coordinate: coordinate,
                caption: nil
            )
            
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

        let availableCoordinates = photo.coordinates.map(\.id)
        let coordinateIds = availableCoordinates.isEmpty ? Array(1...3) : availableCoordinates
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
        previewImageSize = options.first.map { ImageDataDecoder.imageSize(fromBase64: $0.preview.imageBase64) } ?? nil

        if options.isEmpty {
            errorMessage = "Esta imagen no tiene posiciones disponibles para el logo seleccionado"
        }

        isLoadingPositions = false
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
