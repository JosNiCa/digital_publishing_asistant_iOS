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
    @State private var isShowingSearch = false
    @State private var searchText = ""
    @State private var submittedSearchText = ""
    @State private var isShowingFilters = false
    @State private var selectedFormats: Set<PhotoFormat> = []
    @State private var selectedStates: Set<String> = []
    @State private var countryFilterText = ""
    @State private var productFilterText = ""
    @State private var coordinateFilter: PhotoCoordinateFilter = .all
    @State private var contentFilter: PhotoContentFilter = .all
    @State private var platformFilter: PublishingPlatformFilter = .all
    @State private var sortOrder: PhotoSortOrder = .newest
    @State private var usesStartDate = false
    @State private var usesEndDate = false
    @State private var startDate = Calendar.current.date(from: DateComponents(year: 2025, month: 1, day: 1)) ?? Date()
    @State private var endDate = Date()
    @FocusState private var isSearchFocused: Bool
    
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
                .navigationBarTitleDisplayMode(.large)
                .appScreenBackground()
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
                        },
                        onBackgroundPublishStarted: {
                            selectedPhoto = nil
                        },
                        onBackgroundPublishFinished: { _ in
                            FusionSession.shared.clear()
                            Task {
                                await viewModel.refresh()
                            }
                        }
                    )
                }
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isShowingSearch.toggle()
                            }
                            if isShowingSearch {
                                isSearchFocused = true
                            }
                        } label: {
                            Image(systemName: isShowingSearch ? "magnifyingglass.circle.fill" : "magnifyingglass")
                                .foregroundStyle(AppColors.brand)
                        }
                        .accessibilityLabel("Buscar fotos")
                    }

                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showLogoutConfirm = true
                        } label: {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .foregroundStyle(AppColors.brand)
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
            ProgressView("Cargando fotos...")
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
                gallerySummary

                if isShowingSearch {
                    searchPanel
                }

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
            .padding(.top, 6)
            .padding(.bottom, 28)
        }
        .background(AppColors.canvas)
    }

    private var filteredPhotos: [Photo] {
        let photos = viewModel.photos.filter { photo in
            let matchesFormat = selectedFormats.isEmpty || selectedFormats.contains(photo.format)
            let matchesState = selectedStates.isEmpty
                || selectedStates.contains(photo.state ?? "")
            let matchesCountry = matchesOriginFilter(countryFilterText, in: photo.origin)
            let matchesProduct = matchesFilterText(productFilterText, in: photo.productName)
            let matchesCoordinates: Bool
            let matchesContent: Bool
            let matchesPlatform = photo.isCompatible(with: platformFilter)
            let matchesSearch = photo.matchesSearch(submittedSearchText)
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
                && matchesState
                && matchesCountry
                && matchesProduct
                && matchesCoordinates
                && matchesContent
                && matchesPlatform
                && matchesSearch
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
        HStack(spacing: 12) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isShowingFilters.toggle()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: isShowingFilters ? "slider.horizontal.3" : "line.3.horizontal.decrease.circle")
                    Text("Filtros")
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppColors.ink)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(AppColors.elevated)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)

            if activeFilterCount > 0 {
                StatusBadge(
                    text: "\(activeFilterCount) activos",
                    systemImage: "checkmark.circle.fill",
                    tint: AppColors.brand
                )
            }

            Spacer()

            Text("\(filteredPhotos.count) fotos")
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)
        }
    }

    private var searchPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(AppColors.brand)

                TextField("Buscar producto, país, formato...", text: $searchText)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($isSearchFocused)
                    .submitLabel(.search)
                    .onSubmit {
                        submitSearch()
                    }

                if !searchText.isEmpty {
                    Button {
                        clearSearch()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Limpiar búsqueda")
                }

                Button {
                    submitSearch()
                } label: {
                    Text("Buscar")
                        .font(.subheadline.weight(.bold))
                }
                .disabled(normalized(searchText).isEmpty)
            }
            .padding(13)
            .background(AppColors.field)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            if !searchSuggestions.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    SectionEyebrow("Sugerencias", systemImage: "magnifyingglass.circle")

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(searchSuggestions, id: \.self) { suggestion in
                                Button {
                                    searchText = suggestion
                                    submittedSearchText = suggestion
                                    isSearchFocused = false
                                } label: {
                                    Label(suggestion, systemImage: "magnifyingglass")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(AppColors.ink)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(AppColors.field)
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }

            if !submittedSearchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                HStack(spacing: 8) {
                    StatusBadge(
                        text: "Resultados para \(submittedSearchText)",
                        systemImage: "checkmark.circle.fill",
                        tint: AppColors.brand
                    )

                    Button("Quitar") {
                        clearSearch()
                    }
                    .font(.caption.weight(.bold))
                }
            }
        }
        .appCard(cornerRadius: 22, padding: 16)
        .onChange(of: searchText) { _, newValue in
            if normalized(newValue).isEmpty {
                submittedSearchText = ""
            } else if searchSuggestions.count == 1,
                      normalized(searchSuggestions[0]).hasPrefix(normalized(newValue)),
                      normalized(searchSuggestions[0]) != normalized(newValue) {
                submittedSearchText = ""
            }
        }
    }

    private var gallerySummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 7) {
                    Text("Biblioteca lista")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(AppColors.ink)

                    Text("Selecciona una imagen y prueba logos con posiciones disponibles antes de publicar.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 12)

                Image(systemName: "photo.stack.fill")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(AppColors.brand)
                    .frame(width: 48, height: 48)
                    .background(AppColors.brand.opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }

            HStack(spacing: 8) {
                StatusBadge(text: "\(viewModel.photos.count) totales", systemImage: "photo.on.rectangle", tint: AppColors.softInk)

                if activeFilterCount > 0 {
                    StatusBadge(text: "\(filteredPhotos.count) visibles", systemImage: "eye.fill", tint: AppColors.brand)
                }

                if !submittedSearchText.isEmpty {
                    StatusBadge(text: "Búsqueda activa", systemImage: "magnifyingglass", tint: AppColors.brand)
                }
            }
        }
        .appCard(cornerRadius: 22, padding: 16)
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
                Text("Plataforma")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)

                Picker("Plataforma", selection: $platformFilter) {
                    ForEach(PublishingPlatformFilter.allCases) { platform in
                        Text(platform.title).tag(platform)
                    }
                }
                .pickerStyle(.segmented)

                if platformFilter != .all {
                    Text(platformFilter.helperText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("País")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)

                AutocompleteFilterField(
                    placeholder: "Escribe un país",
                    systemImage: "globe.americas.fill",
                    text: $countryFilterText,
                    suggestions: countryFilterSuggestions
                )
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Producto")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)

                AutocompleteFilterField(
                    placeholder: "Escribe un producto",
                    systemImage: "shippingbox.fill",
                    text: $productFilterText,
                    suggestions: productFilterSuggestions
                )
            }

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
        .appCard(cornerRadius: 22, padding: 16)
    }

    private var activeFilterCount: Int {
        let adminFilterCount = session.isAdmin
            ? selectedStates.count
                + (coordinateFilter == .all ? 0 : 1)
                + (usesStartDate ? 1 : 0)
                + (usesEndDate ? 1 : 0)
            : 0

        return selectedFormats.count
            + (countryFilterText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0 : 1)
            + (productFilterText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0 : 1)
            + (contentFilter == .all ? 0 : 1)
            + (platformFilter == .all ? 0 : 1)
            + (sortOrder == .newest ? 0 : 1)
            + (submittedSearchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0 : 1)
            + adminFilterCount
    }

    private var emptyFilteredView: some View {
        EmptyStateView(
            title: "No hay fotos con esos filtros",
            message: "Prueba con otra plataforma, fecha o formato para ampliar la búsqueda.",
            systemImage: "line.3.horizontal.decrease.circle",
            actionTitle: "Limpiar filtros",
            action: clearFilters
        )
        .appCard(cornerRadius: 22, padding: 0)
    }

    private func toggleFormat(_ format: PhotoFormat) {
        if selectedFormats.contains(format) {
            selectedFormats.remove(format)
        } else {
            selectedFormats.insert(format)
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
        selectedStates = []
        countryFilterText = ""
        productFilterText = ""
        coordinateFilter = .all
        contentFilter = .all
        platformFilter = .all
        sortOrder = .newest
        usesStartDate = false
        usesEndDate = false
    }

    private func submitSearch() {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        if searchSuggestions.count == 1,
           normalized(searchSuggestions[0]).hasPrefix(normalized(trimmed)) {
            searchText = searchSuggestions[0]
            submittedSearchText = searchSuggestions[0]
        } else {
            submittedSearchText = trimmed
        }

        isSearchFocused = false
    }

    private func clearSearch() {
        searchText = ""
        submittedSearchText = ""
        isSearchFocused = false
    }

    private var searchSuggestions: [String] {
        let query = normalized(searchText)
        guard !query.isEmpty else { return [] }

        let candidates = viewModel.photos
            .flatMap { $0.searchSuggestionValues }
            .filter { normalized($0).contains(query) }

        return Array(NSOrderedSet(array: candidates).compactMap { $0 as? String })
            .sorted { lhs, rhs in
                let lhsStarts = normalized(lhs).hasPrefix(query)
                let rhsStarts = normalized(rhs).hasPrefix(query)

                if lhsStarts != rhsStarts {
                    return lhsStarts
                }

                return lhs.localizedCaseInsensitiveCompare(rhs) == .orderedAscending
            }
            .prefix(8)
            .map { $0 }
    }

    private func normalized(_ value: String) -> String {
        value.normalizedForPhotoSearch
    }

    private var availableStates: [String] {
        Array(Set(viewModel.photos.compactMap { valueIfPresent($0.state) })).sorted()
    }

    private var availableCountries: [String] {
        Array(Set(viewModel.photos.compactMap { valueIfPresent($0.origin) }))
            .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    private var availableProducts: [String] {
        Array(Set(viewModel.photos.compactMap { valueIfPresent($0.productName) }))
            .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    private var countryFilterSuggestions: [String] {
        autocompleteSuggestions(matching: countryFilterText, in: availableCountries)
    }

    private var productFilterSuggestions: [String] {
        autocompleteSuggestions(matching: productFilterText, in: availableProducts)
    }

    private func matchesFilterText(_ filterText: String, in value: String?) -> Bool {
        let query = normalized(filterText)
        guard !query.isEmpty else { return true }

        return normalized(value ?? "").contains(query)
    }

    private func matchesOriginFilter(_ filterText: String, in origin: String?) -> Bool {
        let query = normalized(filterText)
        guard !query.isEmpty else { return true }

        return originSearchValues(for: origin).contains {
            $0.contains(query) || query.contains($0)
        }
    }

    private func autocompleteSuggestions(matching queryText: String, in values: [String]) -> [String] {
        let query = normalized(queryText)
        guard !query.isEmpty else { return [] }

        return values
            .filter { normalized($0).contains(query) }
            .sorted { lhs, rhs in
                let lhsStarts = normalized(lhs).hasPrefix(query)
                let rhsStarts = normalized(rhs).hasPrefix(query)

                if lhsStarts != rhsStarts {
                    return lhsStarts
                }

                return lhs.localizedCaseInsensitiveCompare(rhs) == .orderedAscending
            }
            .prefix(6)
            .map { $0 }
    }

    private func originSearchValues(for origin: String?) -> [String] {
        guard let origin = valueIfPresent(origin) else { return [] }

        var values = Set([normalized(origin)])

        if let aliases = countryAliases[normalized(origin)] {
            values.formUnion(aliases.map(normalized))
        }

        return Array(values)
    }

    private var countryAliases: [String: [String]] {
        [
            "mexico": ["mx"],
            "mx": ["mexico"],
            "colombia": ["co"],
            "co": ["colombia"],
            "ecuador": ["ec"],
            "ec": ["ecuador"]
        ]
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
        EmptyStateView(
            title: "No hay imágenes disponibles",
            message: "Cuando el backend entregue material nuevo, aparecerá aquí para preparar publicaciones.",
            systemImage: "photo.on.rectangle.angled"
        )
        .padding(16)
    }

    private func errorView(message: String) -> some View {
        EmptyStateView(
            title: "No pudimos cargar las fotos",
            message: message,
            systemImage: "wifi.exclamationmark",
            actionTitle: "Reintentar",
            action: {
                Task {
                    await viewModel.loadPhotos()
                }
            }
        )
        .padding(16)
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
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? AppColors.brand : AppColors.field)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct AutocompleteFilterField: View {
    let placeholder: String
    let systemImage: String
    @Binding var text: String
    let suggestions: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppColors.brand)
                    .frame(width: 18)

                TextField(placeholder, text: $text)
                    .font(.subheadline)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()

                if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Button {
                        text = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Limpiar")
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 11)
            .background(AppColors.field)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            if !suggestions.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(suggestions.enumerated()), id: \.element) { index, suggestion in
                        Button {
                            text = suggestion
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "text.magnifyingglass")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(AppColors.brand)
                                    .frame(width: 18)

                                Text(suggestion)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(AppColors.ink)
                                    .lineLimit(1)

                                Spacer()
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        if index < suggestions.count - 1 {
                            Divider()
                                .padding(.leading, 40)
                        }
                    }
                }
                .background(Color(.systemBackground))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(AppColors.brand.opacity(0.10), lineWidth: 1)
                }
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
    }
}

private struct PhotoFormatSection: View {
    let title: String
    let format: PhotoFormat
    let photos: [Photo]
    let compactColumns: [GridItem]
    let onSelect: (Photo) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(AppColors.ink)

                    Text("\(photos.count) imágenes")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            if format == .horizontal {
                LazyVStack(spacing: 10) {
                    ForEach(Array(photos.chunked(into: 5).enumerated()), id: \.offset) { index, blockPhotos in
                        PhotoRenderBlock(
                            blockIndex: index,
                            format: format,
                            photos: blockPhotos,
                            compactColumns: compactColumns,
                            onSelect: onSelect
                        )
                        .id(blockPhotos.map(\.id))
                    }
                }
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(Array(photos.chunked(into: 4).enumerated()), id: \.offset) { index, blockPhotos in
                        PhotoRenderBlock(
                            blockIndex: index,
                            format: format,
                            photos: blockPhotos,
                            compactColumns: compactColumns,
                            onSelect: onSelect
                        )
                        .id(blockPhotos.map(\.id))
                    }
                }
            }
        }
        .padding(.top, 2)
    }
}

private struct PhotoRenderBlock: View {
    let blockIndex: Int
    let format: PhotoFormat
    let photos: [Photo]
    let compactColumns: [GridItem]
    let onSelect: (Photo) -> Void

    @State private var loadedPhotoIDs: Set<Int> = []

    private var isReady: Bool {
        loadedPhotoIDs.count >= photos.count
    }

    private var photoIDs: [Int] {
        photos.map(\.id)
    }

    var body: some View {
        ZStack(alignment: .top) {
            blockContent
                .opacity(isReady ? 1 : 0)
                .allowsHitTesting(isReady)

            if !isReady {
                PhotoBlockLoadingView(
                    loadedCount: loadedPhotoIDs.count,
                    totalCount: photos.count
                )
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.22), value: isReady)
        .onChange(of: photoIDs) { _, _ in
            loadedPhotoIDs = []
        }
    }

    @ViewBuilder
    private var blockContent: some View {
        if format == .horizontal {
            LazyVStack(spacing: 10) {
                ForEach(photos) { photo in
                    PhotoCell(
                        photo: photo,
                        aspectRatio: format.displayAspectRatio,
                        onRenderComplete: markLoaded
                    )
                    .onTapGesture {
                        onSelect(photo)
                    }
                }
            }
        } else {
            LazyVStack(spacing: 10) {
                ForEach(Array(photos.chunked(into: 2).enumerated()), id: \.offset) { _, rowPhotos in
                    HStack(alignment: .top, spacing: 10) {
                        ForEach(rowPhotos) { photo in
                            PhotoCell(
                                photo: photo,
                                aspectRatio: format.displayAspectRatio,
                                onRenderComplete: markLoaded
                            )
                            .onTapGesture {
                                onSelect(photo)
                            }
                            .frame(maxWidth: .infinity)
                        }

                        if rowPhotos.count == 1 {
                            Spacer(minLength: 0)
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
        }
    }

    private func markLoaded(_ photo: Photo) {
        loadedPhotoIDs.insert(photo.id)
    }
}

private struct PhotoBlockLoadingView: View {
    let loadedCount: Int
    let totalCount: Int

    var body: some View {
        VStack(spacing: 14) {
            BubbleLoadingIndicator()

            VStack(spacing: 4) {
                Text("Preparando siguiente bloque")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(AppColors.ink)

                Text("\(loadedCount) de \(totalCount) imágenes listas")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 160)
        .padding(18)
        .background(Color(.systemBackground))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(AppColors.brand.opacity(0.16), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 14, x: 0, y: 7)
    }
}

private struct BubbleLoadingIndicator: View {
    @State private var isAnimating = false

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(AppColors.brand.opacity(0.82 - Double(index) * 0.14))
                    .frame(width: 12, height: 12)
                    .scaleEffect(isAnimating ? 1.12 : 0.72)
                    .offset(y: isAnimating ? -4 : 4)
                    .animation(
                        .easeInOut(duration: 0.52)
                        .repeatForever(autoreverses: true)
                        .delay(Double(index) * 0.12),
                        value: isAnimating
                    )
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(AppColors.brand.opacity(0.10))
        .clipShape(Capsule())
        .onAppear {
            isAnimating = true
        }
    }
}

private struct PhotoCell: View {
    
    let photo: Photo
    let aspectRatio: Double
    let onRenderComplete: (Photo) -> Void
    @State private var didCompleteRender = false

    private let maxImageRetries = 3
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RetryingRemoteImage(
                url: resolvedImageURL,
                maxRetries: maxImageRetries,
                onSuccess: completeRenderIfNeeded,
                onFinalFailure: completeRenderIfNeeded
            ) { state, retry in
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
                    ZStack {
                        AppColors.field
                        Button {
                            didCompleteRender = false
                            retry()
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .font(.title2.weight(.semibold))
                                .foregroundColor(.secondary)
                                .frame(width: 44, height: 44)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Reintentar imagen")
                    }
                }
            }
            .onChange(of: photo.id) { _, _ in
                didCompleteRender = false
            }

            LinearGradient(
                colors: [.clear, .black.opacity(0.55)],
                startPoint: .center,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 6) {
                if let productName = photo.productName, !productName.isEmpty {
                    Text(productName)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }

                HStack(spacing: 6) {
                    if let origin = photo.origin, !origin.isEmpty {
                        Text(origin.capitalized)
                    }

                    if let platformName = photo.platform?.name, !platformName.isEmpty {
                        Text(platformName)
                    }
                }
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.86))
                .lineLimit(1)
            }
            .padding(10)
            .padding(.trailing, photo.platform?.iconUrl == nil ? 0 : 42)

            platformIcon
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        }
        .aspectRatio(aspectRatio, contentMode: .fit)
        .frame(maxWidth: .infinity)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)
    }

    @ViewBuilder
    private var platformIcon: some View {
        if let platform = photo.platform,
           let iconUrl = platform.iconUrl {
            RetryingRemoteImage(url: iconUrl, maxRetries: 1) { state, _ in
                switch state {
                case .loading:
                    ProgressView()
                        .controlSize(.mini)
                        .frame(width: 24, height: 24)
                        .padding(5)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                case .success(let image):
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .padding(5)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                case .failure:
                    EmptyView()
                }
            }
            .padding(6)
            .accessibilityLabel(platform.name.isEmpty ? "Plataforma" : platform.name)
        }
    }

    private func completeRenderIfNeeded() {
        guard !didCompleteRender else { return }
        didCompleteRender = true
        onRenderComplete(photo)
    }

    private var resolvedImageURL: URL? {
        photo.imageUrl.resolvedMediaURL
    }
}

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else { return [self] }

        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

private extension Photo {
    var searchSuggestionValues: [String] {
        [
            productName,
            origin,
            state,
            platform?.key,
            platform?.name,
            formatDisplay,
            serverFormat,
            createdAt,
            destinationPlatform?.title,
            format.title,
            format.filterTitle,
            "ID \(id)"
        ]
        .compactMap { value in
            guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !value.isEmpty else {
                return nil
            }

            return value
        }
    }

    func matchesSearch(_ query: String) -> Bool {
        let normalizedQuery = query.normalizedForPhotoSearch
        guard !normalizedQuery.isEmpty else { return true }

        return searchSuggestionValues.contains {
            $0.normalizedForPhotoSearch.contains(normalizedQuery)
        }
    }
}

private extension String {
    var normalizedForPhotoSearch: String {
        folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }
}
