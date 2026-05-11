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

@MainActor
final class PhotoViewerViewModel: ObservableObject {

    let photo: Photo
    
    @Published var distributors: [Distributor] = []
    @Published var fusionImageBase64: String?
    @Published var selectedDistributorId: Int?
    @Published var selectedCoordinate: Int?
    @Published var isLoading = false
    @Published var isLoadingPositions = false
    @Published var errorMessage: String?
    @Published var shouldNavigateToPreview = false
    @Published var positionOptions: [LogoPositionOption] = []
    @Published var previewImageSize: CGSize?

    private let distributorRepository: DistributorRepository
    private let fusionRepository: FusionRepository
    

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
        } catch {
            errorMessage = "No se pudieron cargar distribuidores"
        }
        
        isLoading = false
    }

    func selectDistributor(_ distributorId: Int) async {
        selectedDistributorId = distributorId
        selectedCoordinate = nil
        fusionImageBase64 = nil
        positionOptions = []
        previewImageSize = nil
        errorMessage = nil

        await loadPositionOptions(for: distributorId)
    }

    func selectPosition(_ option: LogoPositionOption) {
        selectedCoordinate = option.id
        fusionImageBase64 = option.preview.imageBase64

        if previewImageSize == nil {
            previewImageSize = imageSize(fromBase64: option.preview.imageBase64)
        }
    }
    
    func applyFusion() async {
        guard let distributor = selectedDistributorId,
              let coordinate = selectedCoordinate else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await fusionRepository.applyFusion(
                photoId: photo.id,
                distributorId: distributor,
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
            previewImageSize = imageSize(fromBase64: result.imageBase64)
            
        } catch {
            self.errorMessage = "Error al generar la imagen"
        }
        
        isLoading = false
    }
    
    func goToPreview() {
        guard fusionImageBase64 != nil,
              selectedDistributorId != nil,
              selectedCoordinate != nil else {
            errorMessage = "Faltan datos para preview"
            return
        }

        shouldNavigateToPreview = true
    }

    private func loadPositionOptions(for distributorId: Int) async {
        isLoadingPositions = true

        var options: [LogoPositionOption] = []
        var firstImageSize: CGSize?

        let availableCoordinates = photo.coordinates.map(\.id)
        let coordinateIds = availableCoordinates.isEmpty ? Array(1...3) : availableCoordinates

        for coordinate in coordinateIds {
            do {
                let result = try await fusionRepository.applyFusion(
                    photoId: photo.id,
                    distributorId: distributorId,
                    coordinate: coordinate,
                    caption: nil
                )

                guard let x = result.x,
                      let y = result.y,
                      let resultCoordinate = result.coordinate else {
                    continue
                }

                if firstImageSize == nil {
                    firstImageSize = imageSize(fromBase64: result.imageBase64)
                }

                options.append(
                    LogoPositionOption(
                        id: resultCoordinate,
                        x: x,
                        y: y,
                        preview: result
                    )
                )
            } catch {
                continue
            }
        }

        positionOptions = options.sorted { $0.id < $1.id }
        previewImageSize = firstImageSize

        if options.isEmpty {
            errorMessage = "Esta imagen no tiene posiciones disponibles para el logo seleccionado"
        }

        isLoadingPositions = false
    }

    private func imageSize(fromBase64 base64: String) -> CGSize? {
        let cleanedBase64 = base64
            .replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "\r", with: "")
            .replacingOccurrences(of: "data:image/png;base64,", with: "")
            .replacingOccurrences(of: "data:image/jpeg;base64,", with: "")
            .replacingOccurrences(of: "data:image/jpg;base64,", with: "")

        guard let data = Data(base64Encoded: cleanedBase64),
              let image = UIImage(data: data) else {
            return nil
        }

        return image.size
    }
}
