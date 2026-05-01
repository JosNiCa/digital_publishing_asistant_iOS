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
    @Published var scheduledDate: Date?

    // MARK: - Internal State
    private(set) var fusionId: Int?

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
    
    private func buildTimestamp() -> Int? {
        guard let date = scheduledDate else { return nil }
        return Int(date.timeIntervalSince1970)
    }

    // MARK: - Actions

    func saveFusion() async -> Bool {
        
        guard !isLoading else { return false }
        
        if fusionId != nil {
            successMessage = "La fusión ya fue guardada"
            FusionSession.shared.clear()
            return true
        }
        
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
            
            FusionSession.shared.fusionId = id
            FusionSession.shared.photoId = input.photoId
            FusionSession.shared.distributorId = input.distributorId
            FusionSession.shared.coordinate = input.coordinate
            
            successMessage = "Fusión guardada (ID: \(id))"
            FusionSession.shared.clear()
            return true
            
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
    
    func publish() async -> Bool {
        
        guard !isLoading else { return false }
        
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        defer { isLoading = false }
        
        guard !caption.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "El caption no puede estar vacío"
            return false
        }
        
        do {
            // Asegurar que exista fusionId
            if fusionId == nil {
                let id = try await fusionRepository.saveFusion(
                    photoId: input.photoId,
                    logoId: input.distributorId,
                    coordinate: input.coordinate
                )
                fusionId = id
                FusionSession.shared.fusionId = id
            }
            
            guard let fusionId else {
                throw APIError.serverError(code: nil, message: "No hay fusionId")
            }
            
            // Validar conexión
            let connection = try await publishingRepository.verifyConnection()
            
            if !connection.isConnected {
                errorMessage = "No hay conexión con Facebook/Instagram"
                return false
            }

            // Construir scheduled_time
            let timestamp = buildTimestamp()
            
            if let date = scheduledDate, date < Date() {
                errorMessage = "No puedes programar en el pasado"
                return false
            }
            
            // Publicar
            try await publishingRepository.publishFusion(
                fusionId: fusionId,
                caption: caption,
                scheduledTime: timestamp
            )
            
            if timestamp != nil {
                successMessage = "Publicación programada correctamente"
            } else {
                successMessage = "Publicado correctamente"
            }
            
            FusionSession.shared.clear()
            return true
            
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
