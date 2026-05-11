//
//  PhotoViewerView.swift
//  Maruyama's Publising Assistant
//
//  Created by LJD Technology on 28/03/26.
//


import SwiftUI

struct PhotoViewerView: View {
    
    @StateObject private var viewModel: PhotoViewerViewModel
    
    private let fusionRepository: FusionRepository
    private let publishingRepository: PublishingRepository
    private let onFusionCompleted: @MainActor (FusionCompletionResult) -> Void
    
    init(photo: Photo,
         distributorRepository: DistributorRepository,
         fusionRepository: FusionRepository,
         publishingRepository: PublishingRepository,
         onFusionCompleted: @escaping @MainActor (FusionCompletionResult) -> Void = { _ in }
    ) {
        self.fusionRepository = fusionRepository
        self.publishingRepository = publishingRepository
        self.onFusionCompleted = onFusionCompleted
        
        _viewModel = StateObject(
            wrappedValue: PhotoViewerViewModel(
                photo: photo,
                distributorRepository: distributorRepository,
                fusionRepository: fusionRepository
            )
        )
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                imageSection
                distributorSection
                coordinateSection
                Button("Preview") {
                    viewModel.goToPreview()
                }
                .disabled(
                    viewModel.fusionImageBase64 == nil ||
                    viewModel.selectedDistributorId == nil ||
                    viewModel.selectedCoordinate == nil
                )
            }
            .navigationDestination(isPresented: $viewModel.shouldNavigateToPreview) {
                if let imageBase64 = viewModel.fusionImageBase64,
                   let distributorId = viewModel.selectedDistributorId,
                   let coordinate = viewModel.selectedCoordinate {
                    
                    let sessionFusionId = FusionSession.shared.fusionId(
                        matchingPhotoId: viewModel.photo.id,
                        distributorId: distributorId,
                        coordinate: coordinate
                    )

                    let input = PreviewInput(
                        imageBase64: imageBase64,
                        photoId: viewModel.photo.id,
                        distributorId: distributorId,
                        coordinate: coordinate,
                        fusionId: sessionFusionId
                    )
                    
                    PreviewView(
                        input: input,
                        fusionRepository: fusionRepository,
                        publishingRepository: publishingRepository,
                        onComplete: onFusionCompleted
                    )
                    
                } else {
                    Text("Faltan datos para la vista de previsualización")
                        .foregroundColor(.red)
                }
            }
            
            .padding()
        }
        .navigationTitle("Detalle")
        .task {
            if FusionSession.shared.photoId != nil,
               FusionSession.shared.photoId != viewModel.photo.id {
                FusionSession.shared.clear()
            }
            await viewModel.loadDistributors()
        }
    }
    
    private var imageSection: some View {
        ZStack {
            if let base64 = viewModel.fusionImageBase64,
               let uiImage = uiImage(fromBase64: base64) {
                logoPreviewImage(uiImage)
            } else {
                remotePhotoImage
            }
        }
        .overlay(alignment: .topLeading) {
            positionPointsOverlay
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private var distributorSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Selecciona un distribuidor")
        
            if viewModel.isLoading {
                ProgressView()
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))]) {
                    
                    ForEach(viewModel.distributors) { distributor in
                        
                        VStack {
                            AsyncImage(url: URL(string: distributor.logoUrl)) { phase in
                                
                                switch phase {
                                case .empty:
                                    ProgressView()
                                    
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 60)
                                    
                                case .failure:
                                    Text(String(distributor.name.prefix(2)))
                                        .frame(height: 60)
                                    
                                default:
                                    EmptyView()
                                }
                            }
                            
                            Text(distributor.name)
                                .font(.caption)
                                .lineLimit(1)
                        }
                        .padding(6)
                        .background(
                            viewModel.selectedDistributorId == distributor.id
                            ? Color.blue.opacity(0.2)
                            : Color.clear
                        )
                        .cornerRadius(8)
                        .onTapGesture {
                            Task {
                                await viewModel.selectDistributor(distributor.id)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var coordinateSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Posición del logo")

            if viewModel.selectedDistributorId == nil {
                Text("Selecciona un distribuidor para ver las posiciones disponibles")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else if viewModel.isLoadingPositions {
                HStack(spacing: 8) {
                    ProgressView()
                    Text("Cargando posiciones")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else if viewModel.positionOptions.isEmpty {
                Text("No hay posiciones disponibles para esta imagen")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else if let selectedCoordinate = viewModel.selectedCoordinate {
                Text("Posición seleccionada: P\(selectedCoordinate)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("Toca un punto rojo en la imagen")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var remotePhotoImage: some View {
        AsyncImage(url: URL(string: viewModel.photo.imageUrl)) { phase in
            switch phase {
            case .empty:
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 240)
            case .success(let image):
                image
                    .resizable()
                    .scaledToFit()
            case .failure:
                Text("Error")
                    .frame(maxWidth: .infinity, minHeight: 240)
            default:
                EmptyView()
            }
        }
    }

    private func logoPreviewImage(_ image: UIImage) -> some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFit()
    }

    private var positionPointsOverlay: some View {
        GeometryReader { geometry in
            if let imageSize = viewModel.previewImageSize {
                ForEach(viewModel.positionOptions) { option in
                    Button {
                        viewModel.selectPosition(option)
                    } label: {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 22, height: 22)
                            .overlay {
                                Circle()
                                    .stroke(Color.white, lineWidth: 3)
                            }
                            .shadow(radius: 3)
                    }
                    .buttonStyle(.plain)
                    .position(
                        x: pointX(option.x, imageWidth: imageSize.width, viewWidth: geometry.size.width),
                        y: pointY(option.y, imageHeight: imageSize.height, viewHeight: geometry.size.height)
                    )
                    .opacity(viewModel.selectedCoordinate == option.id ? 1 : 0.85)
                }
            }
        }
        .allowsHitTesting(!viewModel.positionOptions.isEmpty)
    }

    private func pointX(_ x: Int, imageWidth: CGFloat, viewWidth: CGFloat) -> CGFloat {
        guard imageWidth > 0 else { return 0 }
        return (CGFloat(x) / imageWidth) * viewWidth
    }

    private func pointY(_ y: Int, imageHeight: CGFloat, viewHeight: CGFloat) -> CGFloat {
        guard imageHeight > 0 else { return 0 }
        return (CGFloat(y) / imageHeight) * viewHeight
    }

    private func uiImage(fromBase64 base64: String) -> UIImage? {
        let cleanedBase64 = base64
            .replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "\r", with: "")
            .replacingOccurrences(of: "data:image/png;base64,", with: "")
            .replacingOccurrences(of: "data:image/jpeg;base64,", with: "")
            .replacingOccurrences(of: "data:image/jpg;base64,", with: "")

        guard let data = Data(base64Encoded: cleanedBase64) else {
            return nil
        }

        return UIImage(data: data)
    }
}
