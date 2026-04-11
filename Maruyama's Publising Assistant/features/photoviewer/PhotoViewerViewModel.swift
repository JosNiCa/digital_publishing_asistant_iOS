//
//  PhotoViewerViewModel.swift
//  Maruyama's Publising Assistant
//
//  Created by LJD Technology on 28/03/26.
//

import Combine
import SwiftUI

@MainActor
final class PhotoViewerViewModel: ObservableObject {

    let photo: Photo
    
    @Published var distributors: [Distributor] = []
    @Published var fusionImageBase64: String?
    @Published var imageSize: CGSize = .zero
    
    @Published var selectedDistributorId: Int?
    @Published var selectedCoordinate: Int?
    
    @Published var isLoadingDistributors = false
    @Published var isApplyngFusion = false
    
    @Published var errorMessage: String?

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
        isLoadingDistributors = true
        errorMessage = nil
        
        do {
            distributors = try await distributorRepository.fetchDistributors()
        } catch {
            errorMessage = "No se pudieron cargar distribuidores"
        }
        
        isLoadingDistributors = false
    }
    
    func applyFusion() async {
        guard let distributor = selectedDistributorId,
              let coordinate = selectedCoordinate else { return }
        
        isApplyngFusion = true
        errorMessage = nil
        
        do {
            let result = try await fusionRepository.applyFusion(
                photoId: photo.id,
                distributorId: distributor,
                coordinate: coordinate
            )
            
            self.fusionImageBase64 = result.imageBase64
            
        } catch {
            self.errorMessage = "Error al generar la imagen"
        }
        
        isApplyngFusion = false
    }
}
