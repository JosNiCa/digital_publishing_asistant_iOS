//
//  PreviewViewModel.swift
//  Maruyama's Publising Assistant
//
//  Created by LJD Technology on 14/04/26.
//

import Combine
import SwiftUI

struct PreviewInput {
    let imageBase64: String?
    let imageUrl: String?
    let photoId: Int
    let logoId: Int?
    let coordinate: Int
    let fusionId: Int? 
    let caption: String?
    let platforms: [PublishingPlatform]
    
    init(
        imageBase64: String? = nil,
        imageUrl: String? = nil,
        photoId: Int,
        logoId: Int? = nil,
        coordinate: Int,
        fusionId: Int?,
        caption: String? = nil,
        platforms: [PublishingPlatform] = []
    ) {
        self.imageBase64 = imageBase64
        self.imageUrl = imageUrl
        self.photoId = photoId
        self.logoId = logoId
        self.coordinate = coordinate
        self.fusionId = fusionId
        self.caption = caption
        self.platforms = platforms
    }
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
    @Published var imageUrl: URL?
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false
    @Published var loadingMessage: String?
    @Published var successMessage: String?
    @Published var scheduledDate: Date?
    @Published var canRetryPublish: Bool = false
    @Published var selectedPlatformKeys: Set<String>

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
        self.caption = input.caption ?? ""
        self.selectedPlatformKeys = Set(input.platforms.map(\.key))
        
        self.decodeImage()
    }

    // MARK: - Private logic

    private func decodeImage() {
        guard let imageBase64 = input.imageBase64 else {
            imageUrl = input.imageUrl.flatMap(URL.init(string:))
            return
        }
        
        guard let uiImage = ImageDataDecoder.image(fromBase64: imageBase64) else {
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
        
        guard let logoId = input.logoId else {
            errorMessage = "Faltan datos para guardar la fusión"
            return false
        }
        
        isLoading = true
        loadingMessage = "Guardando fusión..."
        errorMessage = nil
        successMessage = nil
        canRetryPublish = false
        
        defer {
            isLoading = false
            loadingMessage = nil
        }
        
        do {
            let id = try await fusionRepository.saveFusion(
                photoId: input.photoId,
                logoId: logoId,
                coordinate: input.coordinate,
                caption: captionForRequest()
            )
            
            self.fusionId = id
            
            FusionSession.shared.fusionId = id
            FusionSession.shared.photoId = input.photoId
            FusionSession.shared.logoId = input.logoId
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
        loadingMessage = scheduledDate == nil ? "Publicando..." : "Programando publicación..."
        errorMessage = nil
        successMessage = nil
        canRetryPublish = false
        
        defer {
            isLoading = false
            loadingMessage = nil
        }
        
        guard !caption.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "El caption no puede estar vacío"
            return false
        }
        
        do {
            // Asegurar que exista fusionId
            if fusionId == nil {
                guard let logoId = input.logoId else {
                    errorMessage = "Faltan datos para publicar la fusión"
                    return false
                }
                
                let id = try await fusionRepository.saveFusion(
                    photoId: input.photoId,
                    logoId: logoId,
                    coordinate: input.coordinate,
                    caption: captionForRequest()
                )
                fusionId = id
                FusionSession.shared.photoId = input.photoId
                FusionSession.shared.logoId = input.logoId
                FusionSession.shared.coordinate = input.coordinate
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

            if platformsForRequest()?.isEmpty == true {
                errorMessage = "Selecciona al menos una plataforma"
                return false
            }
            
            // Publicar
            try await publishingRepository.publishFusion(
                fusionId: fusionId,
                caption: caption,
                scheduledTime: timestamp,
                platforms: platformsForRequest()
            )
            
            if timestamp != nil {
                successMessage = "Publicación programada correctamente"
            } else {
                successMessage = "Publicado correctamente"
            }
            
            FusionSession.shared.clear()
            return true
            
        } catch {
            FusionSession.shared.clear()
            canRetryPublish = fusionId != nil
            errorMessage = publishErrorMessage(from: error)
            return false
        }
    }

    func canStartPublishing() -> Bool {
        guard !isLoading else { return false }

        guard !caption.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "El caption no puede estar vacío"
            return false
        }

        if let date = scheduledDate, date < Date() {
            errorMessage = "No puedes programar en el pasado"
            return false
        }

        if platformsForRequest()?.isEmpty == true {
            errorMessage = "Selecciona al menos una plataforma"
            return false
        }

        return true
    }

    private func captionForRequest() -> String? {
        let value = caption.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }

    var canChoosePlatforms: Bool {
        input.platforms.count > 1
    }

    func togglePlatform(_ platform: PublishingPlatform) {
        if selectedPlatformKeys.contains(platform.key) {
            guard selectedPlatformKeys.count > 1 else {
                errorMessage = "Selecciona al menos una plataforma"
                return
            }

            selectedPlatformKeys.remove(platform.key)
        } else {
            selectedPlatformKeys.insert(platform.key)
        }

        errorMessage = nil
    }

    func isPlatformSelected(_ platform: PublishingPlatform) -> Bool {
        selectedPlatformKeys.contains(platform.key)
    }

    private func platformsForRequest() -> [String]? {
        guard canChoosePlatforms else {
            return nil
        }

        return input.platforms
            .map(\.key)
            .filter { selectedPlatformKeys.contains($0) }
    }

    private func publishErrorMessage(from error: Error) -> String {
        if let apiError = error as? APIError {
            switch apiError {
            case .networkError:
                return "No pudimos confirmar la publicación. Puede ser una falla temporal de Meta o de conexión. Tu fusión sigue en esta pantalla para que puedas intentar publicar de nuevo."
            case .serverError(_, let message):
                return "Meta no pudo completar la publicación: \(message). Tu fusión sigue en esta pantalla; intenta nuevamente en unos minutos."
            case .unauthorized:
                return "Tu sesión ya no es válida. Inicia sesión nuevamente antes de publicar."
            default:
                break
            }
        }

        let message = error.localizedDescription
        if message.localizedCaseInsensitiveContains("timed out")
            || message.localizedCaseInsensitiveContains("tiempo") {
            return "La publicación tardó demasiado en responder. Puede que Meta la procese más tarde, pero la app no pudo confirmarlo. Revisa tus publicaciones o intenta de nuevo."
        }

        return "No pudimos completar la publicación. Tu fusión sigue en esta pantalla para que puedas intentarlo de nuevo."
    }
}
