//
//  HistoryViewModel.swift
//  Maruyama's Publising Assistant
//
//  Created by LJD Technology on 01/05/26.
//

import Combine

@MainActor
final class HistoryViewModel: ObservableObject {
    
    @Published var pendientes: [FusionItem] = []
    @Published var agendadas: [FusionItem] = []
    @Published var publicadas: [FusionItem] = []
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let mediaRepository: MediaRepository
    
    init(mediaRepository: MediaRepository) {
        self.mediaRepository = mediaRepository
    }
    
    func loadFusions() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let groups = try await mediaRepository.fetchFusions()
            
            pendientes = groups.pendientes
            agendadas = groups.agendadas
            publicadas = groups.publicadas
            
        } catch {
            errorMessage = "Error cargando publicaciones"
        }
        
        isLoading = false
    }
}
