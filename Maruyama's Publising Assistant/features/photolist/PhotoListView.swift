//
//  PhotoListView.swift
//  Maruyama's Publising Assistant
//
//  Created by LJD Technology on 26/03/26.
//

import SwiftUI

struct PhotoListView: View {
    
    @StateObject private var viewModel: PhotoListViewModel
    @ObservedObject private var session = SessionManager.shared
    @State private var selectedPhoto: Photo?
    @State private var showLogoutConfirm: Bool = false
    @State private var completionResult: FusionCompletionResult?
    @State private var isShowingFilters = false
    @State private var selectedFormats: Set<PhotoFormat> = []
    @State private var selectedOrigins: Set<String> = []
    @State private var selectedStates: Set<String> = []
    @State private var coordinateFilter: PhotoCoordinateFilter = .all
    @State private var contentFilter: PhotoContentFilter = .all
    @State private var sortOrder: PhotoSortOrder = .newest
    @State private var usesStartDate = false
    @State private var usesEndDate = false
    @State private var startDate = Calendar.current.date(from: DateComponents(year: 2025, month: 1, day: 1)) ?? Date()
    @State private var endDate = Date()
    
    private let apiClient: APIClient
    private let distributorRepository: DistributorRepositoryImpl
    private let fusionRepository: FusionRepositoryImpl
    private let publishingRepository: PublishingRepositoryImpl
        
    init(photoListViewModel: PhotoListViewModel) {
        _viewModel = StateObject(wrappedValue: photoListViewModel)
        let apiClient = APIClient()
        self.apiClient = apiClient
        self.distributorRepository = DistributorRepositoryImpl(apiClient: apiClient)
        self.fusionRepository = FusionRepositoryImpl(apiClient: apiClient)
        self.publishingRepository = PublishingRepositoryImpl(apiClient: apiClient)
    }
    
    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Fotos")
                .task {
                    await viewModel.loadPhotos()
                }
                .refreshable {
                    await viewModel.refresh()
                }
                .navigationDestination(item: $selectedPhoto) { photo in
                    PhotoViewerView(
                        photo: photo,
                        distributorRepository: distributorRepository,
                        fusionRepository: fusionRepository,
                        publishingRepository: publishingRepository,
                        onFusionCompleted: { result in
                            FusionSession.shared.clear()
                            completionResult = result
                            selectedPhoto = nil
                        }
                    )
                }
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showLogoutConfirm = true
                        } label: {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                        }
                        .accessibilityLabel("Cerrar sesión")
                    }
                }
                .alert("Cerrar sesión", isPresented: $showLogoutConfirm) {
                    Button("Cancelar", role: .cancel) {}
                    Button("Cerrar sesión", role: .destructive) {
                        SessionManager.shared.logout()
                    }
                } message: {
                    Text("Se borrarán las credenciales y tendrás que iniciar sesión de nuevo.")
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
        }
    }
    
    @ViewBuilder
    private var content: some View {
        
        if viewModel.isLoading && viewModel.photos.isEmpty {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
        } else if let error = viewModel.errorMessage {
            errorView(message: error)
            
        } else if viewModel.photos.isEmpty {
            emptyView
            
        } else {
            gridView
        }
    }
    
    private let compactColumns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]
    
    private var gridView: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 18) {
                filterHeader

                if isShowingFilters {
                    filterPanel
                }

                if filteredPhotos.isEmpty {
                    emptyFilteredView
                }

                ForEach(PhotoFormat.allCases, id: \.rawValue) { format in
                    let photos = photos(for: format)

                    if !photos.isEmpty {
                        PhotoFormatSection(
                            title: format.title,
                            format: format,
                            photos: photos,
                            compactColumns: compactColumns,
                            onSelect: selectPhoto
                        )
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    private var filteredPhotos: [Photo] {
        let photos = viewModel.photos.filter { photo in
            let matchesFormat = selectedFormats.isEmpty || selectedFormats.contains(photo.format)
            let matchesOrigin = selectedOrigins.isEmpty
                || selectedOrigins.contains(photo.origin ?? "")
            let matchesState = selectedStates.isEmpty
                || selectedStates.contains(photo.state ?? "")
            let matchesCoordinates: Bool
            let matchesContent: Bool
            let matchesStartDate: Bool
            let matchesEndDate: Bool

            switch coordinateFilter {
            case .all:
                matchesCoordinates = true
            case .withCoordinates:
                matchesCoordinates = !photo.coordinates.isEmpty
            case .withoutCoordinates:
                matchesCoordinates = photo.coordinates.isEmpty
            }

            switch contentFilter {
            case .all:
                matchesContent = true
            case .solo:
                matchesContent = photo.isInUse == false
            case .inUse:
                matchesContent = photo.isInUse == true
            }

            if usesStartDate {
                matchesStartDate = photo.createdDate.map { $0 >= Calendar.current.startOfDay(for: startDate) } ?? false
            } else {
                matchesStartDate = true
            }

            if usesEndDate {
                let endOfDay = Calendar.current.date(
                    byAdding: DateComponents(day: 1, second: -1),
                    to: Calendar.current.startOfDay(for: endDate)
                ) ?? endDate
                matchesEndDate = photo.createdDate.map { $0 <= endOfDay } ?? false
            } else {
                matchesEndDate = true
            }

            return matchesFormat
                && matchesOrigin
                && matchesState
                && matchesCoordinates
                && matchesContent
                && matchesStartDate
                && matchesEndDate
        }

        switch sortOrder {
        case .newest:
            return photos.sorted { lhs, rhs in
                guard let lhsDate = lhs.createdDate else { return false }
                guard let rhsDate = rhs.createdDate else { return true }
                return lhsDate > rhsDate
            }
        case .oldest:
            return photos.sorted { lhs, rhs in
                guard let lhsDate = lhs.createdDate else { return false }
                guard let rhsDate = rhs.createdDate else { return true }
                return lhsDate < rhsDate
            }
        }
    }

    private func photos(for format: PhotoFormat) -> [Photo] {
        filteredPhotos.filter { $0.format == format }
    }

    private func selectPhoto(_ photo: Photo) {
        guard selectedPhoto == nil else { return }
        selectedPhoto = photo
    }

    private var filterHeader: some View {
        HStack {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isShowingFilters.toggle()
                }
            } label: {
                Label("Filtros", systemImage: "line.3.horizontal.decrease.circle")
                    .font(.subheadline.weight(.semibold))
            }
            .buttonStyle(.bordered)

            if activeFilterCount > 0 {
                Text("\(activeFilterCount)")
                    .font(.caption.weight(.bold))
                    .foregroundColor(.white)
                    .frame(width: 22, height: 22)
                    .background(Circle().fill(Color.accentColor))
            }

            Spacer()

            Text("\(filteredPhotos.count) fotos")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var filterPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            Picker("Orden", selection: $sortOrder) {
                ForEach(PhotoSortOrder.allCases) { order in
                    Text(order.title).tag(order)
                }
            }
            .pickerStyle(.segmented)

            VStack(alignment: .leading, spacing: 8) {
                Text("Contenido")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)

                Picker("Contenido", selection: $contentFilter) {
                    ForEach(PhotoContentFilter.allCases) { filter in
                        Text(filter.title).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
            }

            if !availableOrigins.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Origen")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.secondary)

                    horizontalChips(availableOrigins, selected: selectedOrigins, toggle: toggleOrigin)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Formato")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(PhotoFormat.filterableCases, id: \.rawValue) { format in
                            FilterChip(
                                title: format.filterTitle,
                                isSelected: selectedFormats.contains(format)
                            ) {
                                toggleFormat(format)
                            }
                        }
                    }
                }
            }

            if session.isAdmin {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Fecha de creación")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.secondary)

                    Toggle("Desde", isOn: $usesStartDate)
                        .font(.subheadline)

                    if usesStartDate {
                        DatePicker(
                            "Desde",
                            selection: $startDate,
                            displayedComponents: [.date]
                        )
                        .datePickerStyle(.compact)
                        .labelsHidden()
                    }

                    Toggle("Hasta", isOn: $usesEndDate)
                        .font(.subheadline)

                    if usesEndDate {
                        DatePicker(
                            "Hasta",
                            selection: $endDate,
                            displayedComponents: [.date]
                        )
                        .datePickerStyle(.compact)
                        .labelsHidden()
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Coordenadas")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.secondary)

                    Picker("Coordenadas", selection: $coordinateFilter) {
                        ForEach(PhotoCoordinateFilter.allCases) { filter in
                            Text(filter.title).tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                if !availableStates.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Estado")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.secondary)

                        horizontalChips(availableStates, selected: selectedStates, toggle: toggleState)
                    }
                }
            }

            if activeFilterCount > 0 {
                Button("Limpiar filtros") {
                    clearFilters()
                }
                .font(.caption.weight(.semibold))
            }
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var activeFilterCount: Int {
        let adminFilterCount = session.isAdmin
            ? selectedStates.count
                + (coordinateFilter == .all ? 0 : 1)
                + (usesStartDate ? 1 : 0)
                + (usesEndDate ? 1 : 0)
            : 0

        return selectedFormats.count
            + selectedOrigins.count
            + (contentFilter == .all ? 0 : 1)
            + (sortOrder == .newest ? 0 : 1)
            + adminFilterCount
    }

    private var emptyFilteredView: some View {
        VStack(spacing: 8) {
            Image(systemName: "line.3.horizontal.decrease.circle")
                .font(.title2)
                .foregroundColor(.secondary)

            Text("No hay fotos con esos filtros")
                .font(.subheadline.weight(.semibold))

            Button("Limpiar filtros") {
                clearFilters()
            }
            .font(.caption.weight(.semibold))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
    }

    private func toggleFormat(_ format: PhotoFormat) {
        if selectedFormats.contains(format) {
            selectedFormats.remove(format)
        } else {
            selectedFormats.insert(format)
        }
    }

    private func toggleOrigin(_ origin: String) {
        if selectedOrigins.contains(origin) {
            selectedOrigins.remove(origin)
        } else {
            selectedOrigins.insert(origin)
        }
    }

    private func toggleState(_ state: String) {
        if selectedStates.contains(state) {
            selectedStates.remove(state)
        } else {
            selectedStates.insert(state)
        }
    }

    private func clearFilters() {
        selectedFormats = []
        selectedOrigins = []
        selectedStates = []
        coordinateFilter = .all
        contentFilter = .all
        sortOrder = .newest
        usesStartDate = false
        usesEndDate = false
    }

    private var availableOrigins: [String] {
        Array(Set(viewModel.photos.compactMap { valueIfPresent($0.origin) })).sorted()
    }

    private var availableStates: [String] {
        Array(Set(viewModel.photos.compactMap { valueIfPresent($0.state) })).sorted()
    }

    private func valueIfPresent(_ value: String?) -> String? {
        guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              !value.isEmpty else {
            return nil
        }

        return value
    }

    private func horizontalChips(
        _ values: [String],
        selected: Set<String>,
        toggle: @escaping (String) -> Void
    ) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(values, id: \.self) { value in
                    FilterChip(
                        title: value.capitalized,
                        isSelected: selected.contains(value)
                    ) {
                        toggle(value)
                    }
                }
            }
        }
    }
    
    private var emptyView: some View {
        Text("No hay imágenes disponibles")
            .foregroundColor(.gray)
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 12) {
            Text(message)
                .foregroundColor(.red)
            
            Button("Reintentar") {
                Task {
                    await viewModel.loadPhotos()
                }
            }
        }
    }
}

private enum PhotoSortOrder: String, CaseIterable, Identifiable {
    case newest
    case oldest

    var id: String { rawValue }

    var title: String {
        switch self {
        case .newest:
            return "Recientes"
        case .oldest:
            return "Antiguas"
        }
    }
}

private enum PhotoCoordinateFilter: String, CaseIterable, Identifiable {
    case all
    case withCoordinates
    case withoutCoordinates

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            return "Todas"
        case .withCoordinates:
            return "Con"
        case .withoutCoordinates:
            return "Sin"
        }
    }
}

private enum PhotoContentFilter: String, CaseIterable, Identifiable {
    case all
    case solo
    case inUse

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            return "Todo"
        case .solo:
            return "Solo"
        case .inUse:
            return "En uso"
        }
    }
}

private struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.caption.weight(.bold))
                }

                Text(title)
                    .font(.caption.weight(.semibold))
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                Capsule()
                    .fill(isSelected ? Color.accentColor : Color(.tertiarySystemBackground))
            )
        }
        .buttonStyle(.plain)
    }
}

private struct PhotoFormatSection: View {
    let title: String
    let format: PhotoFormat
    let photos: [Photo]
    let compactColumns: [GridItem]
    let onSelect: (Photo) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)

            if format == .horizontal {
                LazyVStack(spacing: 10) {
                    ForEach(photos) { photo in
                        PhotoCell(photo: photo, aspectRatio: format.displayAspectRatio)
                            .onTapGesture {
                                onSelect(photo)
                            }
                    }
                }
            } else {
                LazyVGrid(columns: compactColumns, spacing: 10) {
                    ForEach(photos) { photo in
                        PhotoCell(photo: photo, aspectRatio: format.displayAspectRatio)
                            .onTapGesture {
                                onSelect(photo)
                            }
                    }
                }
            }
        }
    }
}

struct PhotoCell: View {
    
    let photo: Photo
    let aspectRatio: Double
    
    var body: some View {
        AsyncImage(url: URL(string: photo.imageUrl)) { phase in
            
            switch phase {
                
            case .empty:
                ZStack {
                    Color.gray.opacity(0.2)
                    ProgressView()
                }
                
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
                
            case .failure:
                ZStack {
                    Color.gray.opacity(0.3)
                    Image(systemName: "photo")
                        .foregroundColor(.gray)
                }
                
            @unknown default:
                EmptyView()
            }
        }
        .aspectRatio(aspectRatio, contentMode: .fit)
        .frame(maxWidth: .infinity)
        .clipped()
        .cornerRadius(8)
    }
}
