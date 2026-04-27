//
//  PreviewView.swift
//  Maruyama's Publising Assistant
//
//  Created by LJD Technology on 14/04/26.
//

import SwiftUI

struct PreviewView: View {

    @StateObject private var viewModel: PreviewViewModel

    init(
        input: PreviewInput,
        fusionRepository: FusionRepository,
        publishingRepository: PublishingRepository
    ) {
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
                        await viewModel.saveFusion()
                    }
                }
                .buttonStyle(.bordered)

                Button("Publicar") {
                    Task {
                        await viewModel.publish()
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
}
