//
//  HistoryViewModel.swift
//  Maruyama's Publising Assistant
//
//  Created by LJD Technology on 01/05/26.
//

import Combine
import Foundation

@MainActor
final class HistoryViewModel: ObservableObject {
    
    @Published var pendientes: [FusionItem] = []
    @Published var agendadas: [FusionItem] = []
    @Published var publicadas: [FusionItem] = []
    @Published var eliminadasRedes: [FusionItem] = []
    
    @Published var isLoading = false
    @Published var deletingFusionId: Int?
    @Published var errorMessage: String?
    @Published var actionErrorMessage: String?
    @Published var successMessage: String?
    
    private let mediaRepository: MediaRepository
    private let publishingRepository: PublishingRepository
    
    init(
        mediaRepository: MediaRepository,
        publishingRepository: PublishingRepository
    ) {
        self.mediaRepository = mediaRepository
        self.publishingRepository = publishingRepository
    }
    
    func loadFusions() async {
        isLoading = true
        errorMessage = nil
        actionErrorMessage = nil
        
        do {
            let groups = try await mediaRepository.fetchFusions()
            
            pendientes = groups.pendientes
            agendadas = groups.agendadas
            publicadas = groups.publicadas
            eliminadasRedes = groups.eliminadasRedes
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }

    func deletePublishedPost(_ item: FusionItem) async {
        guard item.canDeletePost, deletingFusionId == nil else { return }

        deletingFusionId = item.id
        actionErrorMessage = nil
        successMessage = nil

        defer {
            deletingFusionId = nil
        }

        do {
            try await publishingRepository.deletePublishedPost(fusionId: item.id)
            successMessage = "Publicación eliminada de redes correctamente."
            await loadFusions()
        } catch {
            actionErrorMessage = error.localizedDescription
        }
    }

    func isDeleting(_ item: FusionItem) -> Bool {
        deletingFusionId == item.id
    }
}
