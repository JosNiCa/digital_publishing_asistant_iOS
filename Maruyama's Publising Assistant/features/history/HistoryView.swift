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
                mediaRepository: mediaRepository
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

                    if filteredItems.isEmpty {
                        emptyFilteredState
                    } else {
                        section(title: selectedFilter.sectionTitle, items: filteredItems)
                    }
                }
                .padding(.horizontal, 16)
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
                    FusionRow(item: item, isActionable: selectedFilter == .pendientes)
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
        }
    }
}

private enum PublicationFilter: String, CaseIterable, Identifiable {
    case pendientes
    case agendadas
    case publicadas
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .pendientes:
            return "Pendientes"
        case .agendadas:
            return "Agendadas"
        case .publicadas:
            return "Publicadas"
        }
    }
    
    var sectionTitle: String {
        switch self {
        case .agendadas:
            return "Programadas"
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
        }
    }
}

private struct FusionRow: View {
    
    let item: FusionItem
    let isActionable: Bool
    
    var body: some View {
        HStack(spacing: 14) {
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
            .frame(width: 72, height: 72)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            
            VStack(alignment: .leading, spacing: 6) {
                Text(item.productoNombre)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(AppColors.ink)
                    .lineLimit(2)
                
                Text(item.distributorName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                HStack(spacing: 8) {
                    StatusBadge(text: item.formato, systemImage: "rectangle.3.group", tint: AppColors.softInk)

                    if let fechaPublicacion = item.fechaPublicacion {
                        Text(fechaPublicacion.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }

            Spacer(minLength: 8)

            if isActionable {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(12)
        .background(AppColors.elevated)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 12, x: 0, y: 6)
    }
}
