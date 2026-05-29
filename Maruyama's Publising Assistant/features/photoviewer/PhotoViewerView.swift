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
    private let onBackgroundPublishStarted: @MainActor () -> Void
    private let onBackgroundPublishFinished: @MainActor (FusionCompletionResult) -> Void
    
    init(photo: Photo,
         distributorRepository: DistributorRepository,
         fusionRepository: FusionRepository,
         publishingRepository: PublishingRepository,
         onFusionCompleted: @escaping @MainActor (FusionCompletionResult) -> Void = { _ in },
         onBackgroundPublishStarted: @escaping @MainActor () -> Void = {},
         onBackgroundPublishFinished: @escaping @MainActor (FusionCompletionResult) -> Void = { _ in }
    ) {
        self.fusionRepository = fusionRepository
        self.publishingRepository = publishingRepository
        self.onFusionCompleted = onFusionCompleted
        self.onBackgroundPublishStarted = onBackgroundPublishStarted
        self.onBackgroundPublishFinished = onBackgroundPublishFinished
        
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
            VStack(alignment: .leading, spacing: 18) {
                headerSection
                imageSection
                distributorSection
                coordinateSection
                previewAction
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 28)
            .navigationDestination(isPresented: $viewModel.shouldNavigateToPreview) {
                if let imageBase64 = viewModel.fusionImageBase64,
                   let logoId = viewModel.selectedLogoId,
                   let coordinate = viewModel.selectedCoordinate {
                    
                    let sessionFusionId = FusionSession.shared.fusionId(
                        matchingPhotoId: viewModel.photo.id,
                        logoId: logoId,
                        coordinate: coordinate
                    )

                    let input = PreviewInput(
                        imageBase64: imageBase64,
                        photoId: viewModel.photo.id,
                        logoId: logoId,
                        coordinate: coordinate,
                        fusionId: sessionFusionId,
                        platforms: viewModel.photo.displayPlatforms
                    )
                    
                    PreviewView(
                        input: input,
                        fusionRepository: fusionRepository,
                        publishingRepository: publishingRepository,
                        onComplete: onFusionCompleted,
                        onBackgroundPublishStarted: onBackgroundPublishStarted,
                        onBackgroundPublishFinished: onBackgroundPublishFinished
                    )
                    
                } else {
                    EmptyStateView(
                        title: "Faltan datos",
                        message: "Selecciona distribuidor y posición para abrir el preview.",
                        systemImage: "exclamationmark.triangle"
                    )
                }
            }
        }
        .navigationTitle("Detalle")
        .navigationBarTitleDisplayMode(.inline)
        .appScreenBackground()
        .task {
            if FusionSession.shared.photoId != nil,
               FusionSession.shared.photoId != viewModel.photo.id {
                FusionSession.shared.clear()
            }
            await viewModel.loadDistributors()
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionEyebrow("Composición", systemImage: "wand.and.stars")

            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(viewModel.photo.productName ?? "Imagen para publicar")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(AppColors.ink)
                        .lineLimit(2)

                    Text("Elige el logo y toca una posición disponible para generar la fusión.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                StatusBadge(
                    text: viewModel.photo.format.filterTitle,
                    systemImage: "rectangle.3.group",
                    tint: AppColors.brand
                )
            }
        }
        .appCard(cornerRadius: 22, padding: 16)
    }

    private var previewAction: some View {
        Button {
            viewModel.goToPreview()
        } label: {
            Label("Abrir preview", systemImage: "arrow.forward.circle.fill")
        }
        .disabled(
            viewModel.fusionImageBase64 == nil ||
            viewModel.selectedLogoId == nil ||
            viewModel.selectedCoordinate == nil
        )
        .buttonStyle(
            PrimaryCapsuleButtonStyle(
                isEnabled: viewModel.fusionImageBase64 != nil &&
                    viewModel.selectedLogoId != nil &&
                    viewModel.selectedCoordinate != nil
            )
        )
    }
    
    private var imageSection: some View {
        ZStack {
            if let base64 = viewModel.fusionImageBase64,
               let uiImage = ImageDataDecoder.image(fromBase64: base64) {
                logoPreviewImage(uiImage)
            } else {
                remotePhotoImage
            }
        }
        .overlay(alignment: .topLeading) {
            positionPointsOverlay
        }
        .overlay(alignment: .bottomLeading) {
            imageCaptionOverlay
        }
        .background(AppColors.elevated)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 18, x: 0, y: 8)
    }
    
    private var distributorSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                SectionEyebrow("Distribuidor", systemImage: "building.2.fill")

                Spacer()

                if let selectedLogoName {
                    StatusBadge(text: selectedLogoName, systemImage: "checkmark", tint: AppColors.positive)
                }
            }
        
            if viewModel.isLoading {
                HStack(spacing: 10) {
                    ProgressView()
                    Text("Cargando distribuidores...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 8)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 12)], spacing: 12) {
                    
                    ForEach(viewModel.logoOptions) { logo in
                        DistributorLogoTile(
                            logo: logo,
                            isSelected: viewModel.selectedLogoId == logo.id
                        ) {
                            Task {
                                await viewModel.selectLogo(logo)
                            }
                        }
                    }
                }
            }
        }
        .appCard(cornerRadius: 22, padding: 16)
    }
    
    private var coordinateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionEyebrow("Posición", systemImage: "scope")

            if let errorMessage = viewModel.errorMessage {
                messageRow(errorMessage, systemImage: "exclamationmark.circle.fill", tint: AppColors.brand)
            } else if viewModel.selectedLogoId == nil {
                messageRow("Selecciona un logo para ver las posiciones disponibles.", systemImage: "hand.tap.fill", tint: AppColors.softInk)
            } else if viewModel.isLoadingPositions {
                HStack(spacing: 10) {
                    ProgressView()
                    Text(positionLoadingText)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            } else if viewModel.positionOptions.isEmpty {
                messageRow("No hay posiciones disponibles para esta imagen.", systemImage: "mappin.slash", tint: AppColors.warning)
            } else if let selectedCoordinate = viewModel.selectedCoordinate {
                messageRow("Posición P\(selectedCoordinate) seleccionada. Ya puedes abrir el preview.", systemImage: "checkmark.circle.fill", tint: AppColors.positive)
            } else {
                messageRow("Toca un punto sobre la imagen para elegir dónde quedará el logo.", systemImage: "mappin.and.ellipse", tint: AppColors.brand)
            }
        }
        .appCard(cornerRadius: 22, padding: 16)
    }

    private var selectedLogoName: String? {
        guard let selectedLogoId = viewModel.selectedLogoId else {
            return nil
        }

        return viewModel.logoOptions.first { $0.id == selectedLogoId }?.displayName
    }

    private var positionLoadingText: String {
        guard viewModel.totalPositionPreviewCount > 0 else {
            return "Generando opciones de posición..."
        }

        return "Generando posiciones \(viewModel.loadedPositionPreviewCount) de \(viewModel.totalPositionPreviewCount)..."
    }

    private var imageCaptionOverlay: some View {
        HStack(spacing: 8) {
            Image(systemName: viewModel.fusionImageBase64 == nil ? "photo.fill" : "sparkles")
            Text(viewModel.fusionImageBase64 == nil ? "Original" : "Fusión generada")
        }
        .font(.caption.weight(.bold))
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.black.opacity(0.45), in: Capsule())
        .padding(12)
    }

    private func messageRow(_ text: String, systemImage: String, tint: Color) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.semibold))
            Text(text)
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundStyle(tint)
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tint.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var remotePhotoImage: some View {
        RetryingRemoteImage(url: viewModel.photo.imageUrl.resolvedMediaURL) { state, _ in
            switch state {
            case .loading:
                ZStack {
                    AppColors.field
                    ProgressView()
                }
                .frame(maxWidth: .infinity, minHeight: 260)
            case .success(let image):
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            case .failure:
                EmptyStateView(
                    title: "Imagen no disponible",
                    message: "No pudimos cargar el archivo original.",
                    systemImage: "photo.badge.exclamationmark"
                )
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
                    if viewModel.selectedCoordinate != option.id {
                        Button {
                            viewModel.selectPosition(option)
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(AppColors.brand)
                                    .frame(width: 28, height: 28)
                                    .shadow(color: AppColors.brand.opacity(0.45), radius: 8, x: 0, y: 4)

                                Text("\(option.id)")
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(.white)
                            }
                            .overlay {
                                Circle()
                                    .stroke(.white, lineWidth: 3)
                            }
                        }
                        .buttonStyle(.plain)
                        .position(
                            x: pointX(option.x, imageWidth: imageSize.width, viewWidth: geometry.size.width),
                            y: pointY(option.y, imageHeight: imageSize.height, viewHeight: geometry.size.height)
                        )
                        .accessibilityLabel("Posición \(option.id)")
                        .transition(.scale.combined(with: .opacity))
                    }
                }
            }
        }
        .animation(.easeInOut(duration: 0.18), value: viewModel.selectedCoordinate)
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

}

private struct DistributorLogoTile: View {
    let logo: DistributorLogoOption
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(isSelected ? AppColors.brand.opacity(0.10) : AppColors.field)
                        .frame(height: 70)

                    RetryingRemoteImage(url: logo.imageUrl.resolvedMediaURL, maxRetries: 1) { state, _ in
                        switch state {
                        case .loading:
                            ProgressView()
                        case .success(let image):
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .padding(12)
                        case .failure:
                            Text(String(logo.distributorName.prefix(2)).uppercased())
                                .font(.headline.weight(.bold))
                                .foregroundStyle(AppColors.brand)
                        }
                    }
                }

                Text(logo.displayName)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppColors.ink)
                    .lineLimit(1)
            }
            .padding(8)
            .background(isSelected ? AppColors.brand.opacity(0.08) : Color.clear)
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(isSelected ? AppColors.brand : Color.clear, lineWidth: 1.5)
            }
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
