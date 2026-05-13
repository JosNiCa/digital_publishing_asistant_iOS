//
//  PreviewView.swift
//  Maruyama's Publising Assistant
//
//  Created by LJD Technology on 14/04/26.
//

import SwiftUI

enum FusionCompletionResult {
    case saved
    case published
    case scheduled

    var title: String {
        switch self {
        case .saved:
            return "Fusión guardada"
        case .published:
            return "Publicación enviada"
        case .scheduled:
            return "Publicación programada"
        }
    }

    var message: String {
        switch self {
        case .saved:
            return "La fusión quedó guardada y puedes verla en el historial."
        case .published:
            return "La publicación se envió correctamente."
        case .scheduled:
            return "La publicación quedó programada correctamente."
        }
    }
}

struct PreviewView: View {

    @StateObject private var viewModel: PreviewViewModel
    private let onComplete: @MainActor (FusionCompletionResult) -> Void

    init(
        input: PreviewInput,
        fusionRepository: FusionRepository,
        publishingRepository: PublishingRepository,
        onComplete: @escaping @MainActor (FusionCompletionResult) -> Void = { _ in }
    ) {
        self.onComplete = onComplete
        _viewModel = StateObject(
            wrappedValue: PreviewViewModel(
                input: input,
                fusionRepository: fusionRepository,
                publishingRepository: publishingRepository
            )
        )
    }

    var body: some View {
        VStack(spacing: 16) {

            contentImage
            captionInput
            scheduleSection
            actionsSection

            Spacer()
        }
        .padding()
        .navigationTitle("Preview")
    }
}

private extension PreviewView {

    var contentImage: some View {
        Group {
            if let image = viewModel.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(12)
            } else if let imageUrl = viewModel.imageUrl {
                AsyncImage(url: imageUrl) { phase in
                    switch phase {
                    case .empty:
                        ProgressView("Cargando imagen...")
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(12)
                    case .failure:
                        Text("Error al cargar la imagen")
                            .foregroundColor(.red)
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                ProgressView("Cargando imagen...")
            }
        }
    }
}

private extension PreviewView {

    var captionInput: some View {
        VStack(alignment: .leading, spacing: 8) {

            Text("Caption")
                .font(.headline)

            TextEditor(text: $viewModel.caption)
                .frame(height: 120)
                .padding(8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
        }
    }
}

private extension PreviewView {
    var scheduleSection: some View {
        VStack(alignment: .leading) {

            Text("Programar publicación")
                .font(.headline)

            DatePicker(
                "Fecha",
                selection: Binding(
                    get: { viewModel.scheduledDate ?? Date() },
                    set: { viewModel.scheduledDate = $0 }
                ),
                displayedComponents: [.date, .hourAndMinute]
            )
        }
    }
}

private extension PreviewView {

    var actionsSection: some View {
        VStack(spacing: 12) {
            
            if viewModel.isLoading {
                ProgressView()
            }

            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
            }

            if let success = viewModel.successMessage {
                Text(success)
                    .foregroundColor(.green)
            }

            HStack(spacing: 12) {
                
                Button("Guardar") {
                    Task {
                        if await viewModel.saveFusion() {
                            onComplete(.saved)
                        }
                    }
                }
                .buttonStyle(.bordered)

                Button("Publicar") {
                    Task {
                        if await viewModel.publish() {
                            onComplete(viewModel.scheduledDate == nil ? .published : .scheduled)
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
            }

            if viewModel.canRetryPublish {
                Text("La fusión se mantiene aquí. Antes de reintentar, revisa si la publicación apareció en Meta para evitar duplicarla.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}
