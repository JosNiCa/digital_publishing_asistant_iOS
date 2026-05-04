//
//  PreviewView.swift
//  Maruyama's Publising Assistant
//
//  Created by LJD Technology on 14/04/26.
//

import SwiftUI

struct PreviewView: View {

    @StateObject private var viewModel: PreviewViewModel
    private let onComplete: @MainActor () -> Void

    init(
        input: PreviewInput,
        fusionRepository: FusionRepository,
        publishingRepository: PublishingRepository,
        onComplete: @escaping @MainActor () -> Void = {}
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
                            onComplete()
                        }
                    }
                }
                .buttonStyle(.bordered)

                Button("Publicar") {
                    Task {
                        if await viewModel.publish() {
                            onComplete()
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
}
