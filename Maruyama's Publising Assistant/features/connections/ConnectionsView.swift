//
//  ConnectionsView.swift
//  Maruyama's Publising Assistant
//
//  Created by LJD Technology on 01/05/26.
//

import SwiftUI

struct ConnectionsView: View {

    @StateObject private var viewModel: ConnectionsViewModel

    init(publishingRepository: PublishingRepository) {
        _viewModel = StateObject(
            wrappedValue: ConnectionsViewModel(
                publishingRepository: publishingRepository
            )
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header

                if viewModel.isLoading && viewModel.status == nil {
                    loadingView
                } else {
                    statusContent
                }
            }
            .padding(16)
        }
        .navigationTitle("Conexión")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task {
                        await viewModel.loadStatus()
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(viewModel.isLoading)
                .accessibilityLabel("Actualizar estado")
            }
        }
        .task {
            await viewModel.loadStatus()
        }
        .refreshable {
            await viewModel.loadStatus()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Estado de Meta")
                .font(.title2.weight(.bold))

            Text("Consulta si la integración está lista para publicar desde la app.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    private var loadingView: some View {
        HStack(spacing: 10) {
            ProgressView()
            Text("Revisando conexión...")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    @ViewBuilder
    private var statusContent: some View {
        if let status = viewModel.status {
            overallCard(status)

            VStack(spacing: 10) {
                ConnectionStatusRow(
                    title: "Token de Meta",
                    subtitle: status.metaTokenConfigured
                        ? "Configurado para esta cuenta"
                        : "No hay token activo configurado",
                    systemImage: "key.fill",
                    isConnected: status.metaTokenConfigured
                )

                ConnectionStatusRow(
                    title: "Facebook",
                    subtitle: status.facebookPageId.map { "Página conectada: \($0)" }
                        ?? "Sin página conectada",
                    systemImage: "f.circle.fill",
                    isConnected: status.facebookConnected
                )

                ConnectionStatusRow(
                    title: "Instagram Business",
                    subtitle: status.instagramUserId.map { "Cuenta conectada: \($0)" }
                        ?? "Sin cuenta Business conectada",
                    systemImage: "camera.fill",
                    isConnected: status.instagramConnected
                )
            }

            if let message = status.message, !message.isEmpty {
                infoMessage(message)
            }
        } else if let errorMessage = viewModel.errorMessage {
            errorView(errorMessage)
        }
    }

    private func overallCard(_ status: ConnectionStatus) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: status.isConnected ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                    .font(.title2)
                    .foregroundColor(status.isConnected ? .green : .orange)

                VStack(alignment: .leading, spacing: 4) {
                    Text(status.isConnected ? "Listo para publicar" : "Requiere atención en web")
                        .font(.headline)

                    Text(status.isConnected
                         ? "Meta está conectado para publicar contenido."
                         : "La conexión se administra desde la versión web.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func infoMessage(_ message: String) -> some View {
        Text(message)
            .font(.caption)
            .foregroundColor(.secondary)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.tertiarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func errorView(_ message: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            ConnectionStatusRow(
                title: "No se pudo consultar Meta",
                subtitle: message,
                systemImage: "wifi.exclamationmark",
                isConnected: false
            )

            Button("Reintentar") {
                Task {
                    await viewModel.loadStatus()
                }
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

private struct ConnectionStatusRow: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let isConnected: Bool

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(isConnected ? Color.green.opacity(0.14) : Color.orange.opacity(0.14))
                    .frame(width: 42, height: 42)

                Image(systemName: systemImage)
                    .foregroundColor(isConnected ? .green : .orange)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))

                    Image(systemName: isConnected ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(isConnected ? .green : .orange)
                }

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
