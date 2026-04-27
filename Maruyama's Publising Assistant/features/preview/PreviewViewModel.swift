//
//  PreviewViewModel.swift
//  Maruyama's Publising Assistant
//
//  Created by LJD Technology on 14/04/26.
//

import Combine
import SwiftUI

struct PreviewInput {
    let imageBase64: String
    let photoId: Int
    let distributorId: Int
    let coordinate: Int
    let fusionId: Int? 
}

@MainActor
final class PreviewViewModel: ObservableObject {

    // MARK: - Input
    let input: PreviewInput

    // MARK: - Dependencies
    private let fusionRepository: FusionRepository
    private let publishingRepository: PublishingRepository

    // MARK: - UI State
    @Published var caption: String = ""
    @Published var image: UIImage?
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false
    @Published var successMessage: String?

    // MARK: - Internal State
    private var fusionId: Int?

    // MARK: - Init
    init(
        input: PreviewInput,
        fusionRepository: FusionRepository,
        publishingRepository: PublishingRepository
    ) {
        self.input = input
        self.fusionRepository = fusionRepository
        self.publishingRepository = publishingRepository
        self.fusionId = input.fusionId
        
        self.decodeImage()
    }

    // MARK: - Private logic

    private func decodeImage() {
        let cleanedBase64 = input.imageBase64
            .replacingOccurrences(of: "\n", with: "")
        
        guard let data = Data(base64Encoded: cleanedBase64),
              let uiImage = UIImage(data: data) else {
            self.errorMessage = "Error al procesar la imagen"
            return
        }

        self.image = uiImage
    }

    // MARK: - Actions

    func saveFusion() async {
        
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        defer { isLoading = false }
        
        do {
            let id = try await fusionRepository.saveFusion(
                photoId: input.photoId,
                logoId: input.distributorId,
                coordinate: input.coordinate
            )
            
            self.fusionId = id
            successMessage = "Fusión guardada (ID: \(id))"
            
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func publish() async {
        
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        defer { isLoading = false }
        
        guard !caption.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "El caption no puede estar vacío"
            return
        }
        
        do {
            // 🔴 1. Asegurar que exista fusionId
            if fusionId == nil {
                let id = try await fusionRepository.saveFusion(
                    photoId: input.photoId,
                    logoId: input.distributorId,
                    coordinate: input.coordinate
                )
                fusionId = id
            }
            
            guard let fusionId else {
                throw NSError(domain: "", code: -1, userInfo: [
                    NSLocalizedDescriptionKey: "No se pudo obtener id_fusion"
                ])
            }
            
            // 🔴 2. Publicar
            try await publishingRepository.publishFusion(
                fusionId: fusionId,
                caption: caption,
                scheduledTime: nil
            )
            
            successMessage = "Publicado correctamente"
            
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
