//
//  ConnectionsViewModel.swift
//  Maruyama's Publising Assistant
//
//  Created by LJD Technology on 12/05/26.
//

import Combine
import Foundation

@MainActor
final class ConnectionsViewModel: ObservableObject {
    @Published var status: ConnectionStatus?
    @Published var errorMessage: String?
    @Published var isLoading = false

    private let publishingRepository: PublishingRepository

    init(publishingRepository: PublishingRepository) {
        self.publishingRepository = publishingRepository
    }

    func loadStatus() async {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        do {
            status = try await publishingRepository.verifyConnection()
        } catch {
            status = nil
            errorMessage = error.localizedDescription
        }
    }
}
