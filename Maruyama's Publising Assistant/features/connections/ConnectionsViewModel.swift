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
    @Published var isRequestingAccountDeletionURL = false
    @Published var accountDeletionErrorMessage: String?

    private let publishingRepository: PublishingRepository
    private let authRepository: AuthRepository

    init(
        publishingRepository: PublishingRepository,
        authRepository: AuthRepository
    ) {
        self.publishingRepository = publishingRepository
        self.authRepository = authRepository
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

    func requestAccountDeletionURL() async -> URL? {
        guard !isRequestingAccountDeletionURL else { return nil }

        isRequestingAccountDeletionURL = true
        accountDeletionErrorMessage = nil

        defer { isRequestingAccountDeletionURL = false }

        do {
            return try await authRepository.requestAccountDeletionURL()
        } catch {
            accountDeletionErrorMessage = error.localizedDescription
            return nil
        }
    }
}
