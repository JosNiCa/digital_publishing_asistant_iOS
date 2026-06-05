//
//  PreviewView.swift
//  Maruyama's Publising Assistant
//
//  Created by LJD Technology on 14/04/26.
//

import SwiftUI

enum FusionCompletionResult: Equatable {
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
    private let onBackgroundPublishStarted: @MainActor () -> Void
    private let onBackgroundPublishFinished: @MainActor (FusionCompletionResult) -> Void

    init(
        input: PreviewInput,
        fusionRepository: FusionRepository,
        publishingRepository: PublishingRepository,
        onComplete: @escaping @MainActor (FusionCompletionResult) -> Void = { _ in },
        onBackgroundPublishStarted: @escaping @MainActor () -> Void = {},
        onBackgroundPublishFinished: @escaping @MainActor (FusionCompletionResult) -> Void = { _ in }
    ) {
        self.onComplete = onComplete
        self.onBackgroundPublishStarted = onBackgroundPublishStarted
        self.onBackgroundPublishFinished = onBackgroundPublishFinished
        _viewModel = StateObject(
            wrappedValue: PreviewViewModel(
                input: input,
                fusionRepository: fusionRepository,
                publishingRepository: publishingRepository
            )
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                contentImage
                captionInput
                platformSection
                scheduleSection
                actionsSection
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 28)
        }
        .navigationTitle("Preview")
        .navigationBarTitleDisplayMode(.inline)
        .appScreenBackground()
        .task {
            await viewModel.loadFusionDetailIfNeeded()
        }
    }

    var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionEyebrow("Publicación", systemImage: "paperplane.fill")

            Text("Revisa antes de enviar")
                .font(.title2.weight(.bold))
                .foregroundStyle(AppColors.ink)

            Text("Ajusta el caption, programa si hace falta y guarda la fusión para continuar después.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .appCard(cornerRadius: 22, padding: 16)
    }
}

private extension PreviewView {

    @ViewBuilder
    var platformSection: some View {
        if viewModel.canChoosePlatforms {
            VStack(alignment: .leading, spacing: 12) {
                SectionEyebrow("Plataformas", systemImage: "square.grid.2x2.fill")

                HStack(spacing: 10) {
                    ForEach(viewModel.platforms) { platform in
                        Button {
                            viewModel.togglePlatform(platform)
                        } label: {
                            HStack(spacing: 8) {
                                platformIcon(platform)
                                Text(platform.name)
                                    .font(.subheadline.weight(.semibold))
                                    .lineLimit(1)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 9)
                            .frame(maxWidth: .infinity)
                            .background(
                                viewModel.isPlatformSelected(platform)
                                    ? AppColors.brand.opacity(0.14)
                                    : AppColors.field
                            )
                            .foregroundStyle(
                                viewModel.isPlatformSelected(platform)
                                    ? AppColors.brand
                                    : AppColors.softInk
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .appCard(cornerRadius: 22, padding: 16)
        }
    }

    @ViewBuilder
    func platformIcon(_ platform: PublishingPlatform) -> some View {
        if let iconUrl = platform.iconUrl {
            RetryingRemoteImage(url: iconUrl, maxRetries: 1) { state, _ in
                switch state {
                case .loading:
                    ProgressView()
                        .controlSize(.mini)
                        .frame(width: 20, height: 20)
                case .success(let image):
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                case .failure:
                    Image(systemName: "network")
                        .frame(width: 20, height: 20)
                }
            }
        } else {
            Image(systemName: "network")
                .frame(width: 20, height: 20)
        }
    }

    var contentImage: some View {
        Group {
            if let image = viewModel.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            } else if let imageUrl = viewModel.imageUrl {
                RetryingRemoteImage(url: imageUrl) { state, _ in
                    switch state {
                    case .loading:
                        ZStack {
                            AppColors.field
                            ProgressView("Cargando imagen...")
                        }
                    case .success(let image):
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    case .failure:
                        EmptyStateView(
                            title: "Imagen no disponible",
                            message: "No pudimos cargar la previsualización de esta fusión.",
                            systemImage: "photo.badge.exclamationmark"
                        )
                    }
                }
            } else {
                ZStack {
                    AppColors.field
                    ProgressView("Cargando imagen...")
                }
            }
        }
        .frame(maxWidth: .infinity)
        .background(AppColors.elevated)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 18, x: 0, y: 8)
    }
}

private extension PreviewView {

    var captionInput: some View {
        VStack(alignment: .leading, spacing: 12) {

            HStack {
                SectionEyebrow("Caption", systemImage: "text.quote")

                Spacer()

                Text("\(viewModel.caption.count) caracteres")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            TextEditor(text: $viewModel.caption)
                .font(.body)
                .frame(minHeight: 130)
                .padding(10)
                .scrollContentBackground(.hidden)
                .background(AppColors.field)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .appCard(cornerRadius: 22, padding: 16)
    }
}

private extension PreviewView {
    var scheduleSection: some View {
        VStack(alignment: .leading, spacing: 12) {

            SectionEyebrow("Programación", systemImage: "calendar.badge.clock")

            DatePicker(
                "Fecha",
                selection: Binding(
                    get: { viewModel.scheduledDate ?? Date() },
                    set: { viewModel.scheduledDate = $0 }
                ),
                displayedComponents: [.date, .hourAndMinute]
            )
            .datePickerStyle(.compact)
        }
        .appCard(cornerRadius: 22, padding: 16)
    }
}

private extension PreviewView {

    var actionsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            
            if viewModel.isLoading {
                HStack(spacing: 10) {
                    ProgressView()
                    Text(viewModel.loadingMessage ?? "Procesando...")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }

            if let error = viewModel.errorMessage {
                messageBanner(error, systemImage: "exclamationmark.triangle.fill", tint: AppColors.brand)
            }

            if let success = viewModel.successMessage {
                messageBanner(success, systemImage: "checkmark.circle.fill", tint: AppColors.positive)
            }

            HStack(spacing: 12) {
                
                Button {
                    Task {
                        if await viewModel.saveFusion() {
                            onComplete(.saved)
                        }
                    }
                } label: {
                    Label("Guardar", systemImage: "tray.and.arrow.down.fill")
                }
                .buttonStyle(SecondaryCapsuleButtonStyle())
                .disabled(viewModel.isLoading)

                Button {
                    publishInBackground()
                } label: {
                    Label(viewModel.scheduledDate == nil ? "Publicar" : "Programar", systemImage: "paperplane.fill")
                }
                .buttonStyle(PrimaryCapsuleButtonStyle(isEnabled: !viewModel.isLoading))
                .disabled(viewModel.isLoading)
            }

            if viewModel.canRetryPublish {
                Text("La fusión se mantiene aquí. Antes de reintentar, revisa si la publicación apareció en Meta para evitar duplicarla.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .appCard(cornerRadius: 22, padding: 16)
    }

    func publishInBackground() {
        guard viewModel.canStartPublishing() else { return }

        let result: FusionCompletionResult = viewModel.scheduledDate == nil ? .published : .scheduled
        let activity = PublishingActivityCenter.shared
        let publisher = viewModel

        activity.begin(isScheduled: result == .scheduled)
        onBackgroundPublishStarted()

        Task {
            let didPublish = await publisher.publish()

            await MainActor.run {
                if didPublish {
                    activity.complete(result)
                    onBackgroundPublishFinished(result)
                } else {
                    activity.fail(publisher.errorMessage ?? "No pudimos completar la publicación.")
                }
            }
        }
    }

    func messageBanner(_ text: String, systemImage: String, tint: Color) -> some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: systemImage)
            Text(text)
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(tint)
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tint.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
