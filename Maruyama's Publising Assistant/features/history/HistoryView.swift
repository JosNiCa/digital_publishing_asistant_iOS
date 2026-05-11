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
                .navigationDestination(item: $selectedPendingItem) { item in
                    PreviewView(
                        input: PreviewInput(
                            imageUrl: item.thumbnailUrl,
                            photoId: item.photoId,
                            coordinate: item.coordenada,
                            fusionId: item.id
                        ),
                        fusionRepository: fusionRepository,
                        publishingRepository: publishingRepository,
                        onComplete: { _ in
                            FusionSession.shared.clear()
                            selectedPendingItem = nil
                            Task {
                                await viewModel.loadFusions()
                            }
                        }
                    )
                }
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
            ProgressView()
        } else if let error = viewModel.errorMessage {
            Text(error)
        } else {
            list
        }
    }
}

private extension HistoryView {
    
    var list: some View {
        VStack(spacing: 0) {
            filterToolbar
            
            List {
                if filteredItems.isEmpty {
                    emptyFilteredState
                } else {
                    section(title: selectedFilter.sectionTitle, items: filteredItems)
                }
            }
        }
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
        .padding(.vertical, 10)
        .background(.bar)
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
        ContentUnavailableView(
            selectedFilter.emptyTitle,
            systemImage: selectedFilter.emptySystemImage
        )
        .listRowBackground(Color.clear)
    }
    
    func section(title: String, items: [FusionItem]) -> some View {
        Section(header: Text(title)) {
            ForEach(items) { item in
                FusionRow(item: item)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        guard selectedFilter == .pendientes else { return }
                        selectedPendingItem = item
                    }
            }
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

struct FusionRow: View {
    
    let item: FusionItem
    
    var body: some View {
        HStack {
            AsyncImage(url: URL(string: item.thumbnailUrl)) { image in
                image.resizable()
            } placeholder: {
                ProgressView()
            }
            .frame(width: 60, height: 60)
            .cornerRadius(8)
            
            VStack(alignment: .leading) {
                Text(item.productoNombre)
                    .font(.headline)
                
                Text(item.distributorName)
                    .font(.subheadline)
                
                Text(item.formato)
                    .font(.caption)
            }
        }
    }
}
