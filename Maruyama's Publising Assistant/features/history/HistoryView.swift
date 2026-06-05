//
//  HistoryView.swift
//  Maruyama's Publising Assistant
//
//  Created by LJD Technology on 01/05/26.
//

import SwiftUI

struct HistoryView: View {
    @StateObject private var viewModel: HistoryViewModel
    @State private var selectedFilter: PublicationFilter = .pendientes
    @State private var selectedPendingItem: FusionItem?
    @State private var itemPendingNetworkDeletion: FusionItem?
    @State private var completionResult: FusionCompletionResult?
    
    private let fusionRepository: FusionRepository
    private let publishingRepository: PublishingRepository
    
    init(
        mediaRepository: MediaRepository,
        fusionRepository: FusionRepository,
        publishingRepository: PublishingRepository
    ) {
        self.fusionRepository = fusionRepository
        self.publishingRepository = publishingRepository
        
        _viewModel = StateObject(
            wrappedValue: HistoryViewModel(
                mediaRepository: mediaRepository,
                publishingRepository: publishingRepository
            )
        )
    }
    
    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Publicaciones")
                .navigationBarTitleDisplayMode(.large)
                .appScreenBackground()
                .navigationDestination(item: $selectedPendingItem) { item in
                    PreviewView(
                        input: item.previewInput,
                        fusionRepository: fusionRepository,
                        publishingRepository: publishingRepository,
                        onComplete: { result in
                            FusionSession.shared.clear()
                            completionResult = result
                            selectedPendingItem = nil
                            Task {
                                await viewModel.loadFusions()
                            }
                        },
                        onBackgroundPublishStarted: {
                            selectedPendingItem = nil
                        },
                        onBackgroundPublishFinished: { _ in
                            FusionSession.shared.clear()
                            Task {
                                await viewModel.loadFusions()
                            }
                        }
                    )
                }
        }
        .alert(
            completionResult?.title ?? "",
            isPresented: Binding(
                get: { completionResult != nil },
                set: { if !$0 { completionResult = nil } }
            )
        ) {
            Button("Entendido", role: .cancel) {
                completionResult = nil
            }
        } message: {
            Text(completionResult?.message ?? "")
        }
        .alert(
            "Eliminar de redes",
            isPresented: Binding(
                get: { itemPendingNetworkDeletion != nil },
                set: { if !$0 { itemPendingNetworkDeletion = nil } }
            )
        ) {
            Button("Cancelar", role: .cancel) {
                itemPendingNetworkDeletion = nil
            }

            Button("Eliminar", role: .destructive) {
                guard let item = itemPendingNetworkDeletion else { return }
                itemPendingNetworkDeletion = nil
                Task {
                    await viewModel.deletePublishedPost(item)
                }
            }
        } message: {
            Text("Se intentará eliminar la publicación de Facebook/Instagram usando los IDs guardados en la fusión.")
        }
        .task {
            await viewModel.loadFusions()
        }
    }
}

private extension HistoryView {
    
    @ViewBuilder
    var content: some View {
        if viewModel.isLoading {
            ProgressView("Cargando publicaciones...")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let error = viewModel.errorMessage {
            EmptyStateView(
                title: "No pudimos cargar el historial",
                message: error,
                systemImage: "wifi.exclamationmark",
                actionTitle: "Reintentar",
                action: {
                    Task { await viewModel.loadFusions() }
                }
            )
            .padding(16)
        } else {
            list
        }
    }
}

private extension FusionItem {
    var previewInput: PreviewInput {
        PreviewInput(
            fusionId: id,
            caption: caption,
            platforms: platforms
        )
    }
}

private extension HistoryView {
    
    var list: some View {
        VStack(spacing: 14) {
            filterToolbar
            
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 14) {
                    summaryCard
                    actionMessages

                    if filteredItems.isEmpty {
                        emptyFilteredState
                    } else {
                        section(title: selectedFilter.sectionTitle, items: filteredItems)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.bottom, 28)
            }
        }
        .background(AppColors.canvas)
    }
}

private extension HistoryView {
    
    var filterToolbar: some View {
        Picker("Estado", selection: $selectedFilter) {
            ForEach(PublicationFilter.allCases) { filter in
                Text(filter.title).tag(filter)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 16)
        .padding(.top, 6)
        .padding(.bottom, 4)
    }

    var summaryCard: some View {
        HStack(spacing: 12) {
            Image(systemName: selectedFilter.emptySystemImage)
                .font(.title2.weight(.semibold))
                .foregroundStyle(AppColors.brand)
                .frame(width: 48, height: 48)
                .background(AppColors.brand.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(selectedFilter.sectionTitle)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(AppColors.ink)

                Text(summaryText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .appCard(cornerRadius: 22, padding: 16)
    }
    
    var filteredItems: [FusionItem] {
        switch selectedFilter {
        case .pendientes:
            return viewModel.pendientes
        case .agendadas:
            return viewModel.agendadas
        case .publicadas:
            return viewModel.publicadas
        case .eliminadasRedes:
            return viewModel.eliminadasRedes
        }
    }

    @ViewBuilder
    var actionMessages: some View {
        if let message = viewModel.successMessage {
            messageBanner(message, systemImage: "checkmark.circle.fill", tint: AppColors.positive)
        }

        if let message = viewModel.actionErrorMessage {
            messageBanner(message, systemImage: "exclamationmark.triangle.fill", tint: AppColors.brand)
        }
    }
    
    var emptyFilteredState: some View {
        EmptyStateView(
            title: selectedFilter.emptyTitle,
            message: "Cuando haya publicaciones en este estado, aparecerán organizadas aquí.",
            systemImage: selectedFilter.emptySystemImage
        )
        .appCard(cornerRadius: 22, padding: 0)
    }
    
    func section(title: String, items: [FusionItem]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionEyebrow(title, systemImage: "list.bullet.rectangle")

            LazyVStack(spacing: 10) {
                ForEach(items) { item in
                    FusionRow(
                        item: item,
                        isActionable: selectedFilter == .pendientes,
                        isDeleting: viewModel.isDeleting(item),
                        onDeleteFromNetworks: item.canDeletePost ? {
                            itemPendingNetworkDeletion = item
                        } : nil
                    )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            guard selectedFilter == .pendientes else { return }
                            selectedPendingItem = item
                        }
                }
            }
        }
    }

    var summaryText: String {
        let count = filteredItems.count
        switch selectedFilter {
        case .pendientes:
            return count == 1 ? "1 publicación lista para revisar." : "\(count) publicaciones listas para revisar."
        case .agendadas:
            return count == 1 ? "1 publicación programada." : "\(count) publicaciones programadas."
        case .publicadas:
            return count == 1 ? "1 publicación enviada." : "\(count) publicaciones enviadas."
        case .eliminadasRedes:
            return count == 1 ? "1 publicación eliminada de redes." : "\(count) publicaciones eliminadas de redes."
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

private enum PublicationFilter: String, CaseIterable, Identifiable {
    case pendientes
    case agendadas
    case publicadas
    case eliminadasRedes
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .pendientes:
            return "Pendientes"
        case .agendadas:
            return "Agendadas"
        case .publicadas:
            return "Publicadas"
        case .eliminadasRedes:
            return "Eliminadas"
        }
    }
    
    var sectionTitle: String {
        switch self {
        case .agendadas:
            return "Programadas"
        case .eliminadasRedes:
            return "Eliminadas de redes"
        default:
            return title
        }
    }
    
    var emptyTitle: String {
        switch self {
        case .pendientes:
            return "No hay pendientes"
        case .agendadas:
            return "No hay agendadas"
        case .publicadas:
            return "No hay publicadas"
        case .eliminadasRedes:
            return "No hay eliminadas"
        }
    }
    
    var emptySystemImage: String {
        switch self {
        case .pendientes:
            return "clock.badge.exclamationmark"
        case .agendadas:
            return "calendar.badge.clock"
        case .publicadas:
            return "checkmark.circle"
        case .eliminadasRedes:
            return "trash.circle"
        }
    }
}

private struct FusionRow: View {
    
    let item: FusionItem
    let isActionable: Bool
    let isDeleting: Bool
    let onDeleteFromNetworks: (() -> Void)?
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            RetryingRemoteImage(url: item.thumbnailUrl.resolvedMediaURL, maxRetries: 1) { state, _ in
                switch state {
                case .loading:
                    ZStack {
                        AppColors.field
                        ProgressView()
                    }
                case .success(let image):
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                case .failure:
                    AppColors.field
                }
            }
            .frame(width: 70, height: 70)
            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
            
            VStack(alignment: .leading, spacing: 6) {
                Text(item.productoNombre)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(AppColors.ink)
                    .lineLimit(1)
                
                Text(item.distributorName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                
                tagRow
            }

            Spacer(minLength: 8)

            if isActionable, onDeleteFromNetworks == nil {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.tertiary)
                    .padding(.top, 29)
            }
        }
        .padding(10)
        .background(AppColors.elevated)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 12, x: 0, y: 6)
    }

    private var tagRow: some View {
        HStack(spacing: 5) {
            HistoryTag(
                title: formatTagTitle,
                systemImage: "rectangle.3.group",
                tint: AppColors.softInk
            )

            if !item.platforms.isEmpty {
                HistoryTag(
                    title: platformTagTitle,
                    systemImage: "paperplane.fill",
                    tint: AppColors.brand
                )
            }

            if let fechaPublicacion = item.fechaPublicacion {
                HistoryTag(
                    title: dateTagTitle(fechaPublicacion),
                    systemImage: "calendar",
                    tint: AppColors.softInk
                )
                .overlay(alignment: .top) {
                    deleteButton
                        .offset(y: -45)
                }
            } else {
                deleteButton
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var deleteButton: some View {
        if let onDeleteFromNetworks {
            Button {
                onDeleteFromNetworks()
            } label: {
                if isDeleting {
                    ProgressView()
                        .controlSize(.mini)
                } else {
                    Image(systemName: "trash.fill")
                        .font(.caption2.weight(.bold))
                }
            }
            .disabled(isDeleting)
            .foregroundStyle(AppColors.brand)
            .frame(width: 34, height: 34)
            .background(AppColors.brand.opacity(0.12))
            .clipShape(Circle())
            .accessibilityLabel("Eliminar publicación de redes")
        }
    }

    private var formatTagTitle: String {
        switch item.formato.lowercased() {
        case "horizontal":
            return "Horizontal"
        case "cuadrado", "square":
            return "Cuadrado"
        case "semivertical", "semi_vertical", "semi-vertical":
            return "Semivertical"
        case "vertical":
            return "Vertical"
        default:
            return item.formato.capitalized
        }
    }

    private var platformTagTitle: String {
        let keys = item.platforms.map { $0.key.lowercased() }
        if keys.contains("facebook"), keys.contains("instagram") {
            return "FB + IG"
        }

        return item.platforms.first?.name ?? "Red"
    }

    private func dateTagTitle(_ date: Date) -> String {
        date.formatted(.dateTime.day().month(.abbreviated))
    }
}

private struct HistoryTag: View {
    let title: String
    let systemImage: String
    let tint: Color

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: systemImage)
                .font(.caption2.weight(.bold))

            Text(title)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 8)
        .frame(height: 28)
        .background(tint.opacity(0.10))
        .clipShape(Capsule())
        .fixedSize(horizontal: true, vertical: false)
    }
}
