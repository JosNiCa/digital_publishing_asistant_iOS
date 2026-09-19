//
//  ConnectionsView.swift
//  Maruyama's Publising Assistant
//
//  Created by LJD Technology on 01/05/26.
//

import SwiftUI

struct ConnectionsView: View {

    @StateObject private var viewModel: ConnectionsViewModel
    @Environment(\.openURL) private var openURL
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var isShowingAccountDeletionConfirmation = false
    @State private var selectedWorkspaceSection: ConnectionWorkspaceSection = .integrations
    @State private var isShowingSettingsSidebar = false

    init(
        publishingRepository: PublishingRepository,
        authRepository: AuthRepository
    ) {
        _viewModel = StateObject(
            wrappedValue: ConnectionsViewModel(
                publishingRepository: publishingRepository,
                authRepository: authRepository
            )
        )
    }

    var body: some View {
        GeometryReader { proxy in
            if usesSettingsWorkspace(for: proxy.size.width) {
                settingsWorkspace
            } else {
                compactContent
            }
        }
        .navigationTitle("Conexión")
        .navigationBarTitleDisplayMode(.large)
        .appScreenBackground()
        .toolbar {
            if horizontalSizeClass == .regular {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isShowingSettingsSidebar.toggle()
                        }
                    } label: {
                        Image(systemName: "sidebar.left")
                    }
                    .accessibilityLabel(
                        isShowingSettingsSidebar ? "Cerrar opciones de conexión" : "Mostrar opciones de conexión"
                    )
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task {
                        await viewModel.loadStatus()
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .foregroundStyle(AppColors.brand)
                }
                .disabled(viewModel.isLoading)
                .accessibilityLabel("Actualizar estado")
            }
        }
        .task {
            await viewModel.loadStatus()
        }
        .refreshable {
            await viewModel.loadStatus()
        }
        .alert("Eliminar cuenta", isPresented: $isShowingAccountDeletionConfirmation) {
            Button("Cancelar", role: .cancel) {}
            Button("Continuar", role: .destructive) {
                Task {
                    await openAccountDeletionRequest()
                }
            }
        } message: {
            Text("Se abrirá la plataforma web con una sesión temporal para solicitar la eliminación de tu cuenta.")
        }
        .alert("No se pudo abrir la solicitud", isPresented: accountDeletionErrorBinding) {
            Button("OK") {
                viewModel.accountDeletionErrorMessage = nil
            }
        } message: {
            Text(viewModel.accountDeletionErrorMessage ?? "")
        }
    }

    private func usesSettingsWorkspace(for width: CGFloat) -> Bool {
        horizontalSizeClass == .regular && width >= 820
    }

    private var compactContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header

                if viewModel.isLoading && viewModel.status == nil {
                    loadingView
                } else {
                    statusContent
                }

                accountManagementSection
            }
            .padding(16)
            .readableContent(maxWidth: 720)
        }
    }

    private var settingsWorkspace: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                workspaceContent

                if isShowingSettingsSidebar {
                    Color.black.opacity(0.14)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isShowingSettingsSidebar = false
                            }
                        }
                        .transition(.opacity)

                    settingsSidebar(width: min(340, max(280, proxy.size.width * 0.86)))
                        .transition(.move(edge: .leading).combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.2), value: isShowingSettingsSidebar)
        }
        .background(AppColors.canvas)
    }

    private var workspaceContent: some View {
        ScrollView {
            workspaceDetail
                .padding(24)
                .frame(maxWidth: 820, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    private func settingsSidebar(width: CGFloat) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Conexión")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(AppColors.ink)

                        Text("Configuración de cuenta")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: 8)

                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isShowingSettingsSidebar = false
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(AppColors.ink)
                            .frame(width: 36, height: 36)
                            .background(AppColors.field)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Cerrar opciones de conexión")
                }

                workspaceSidebarButton(
                    title: "Integraciones",
                    systemImage: "link",
                    section: .integrations
                )

                workspaceSidebarButton(
                    title: "Cuenta",
                    systemImage: "person.crop.circle",
                    section: .account
                )

                if let status = viewModel.status {
                    Divider()
                        .padding(.vertical, 6)

                    StatusBadge(
                        text: status.isConnected ? "Meta conectado" : "Requiere atención",
                        systemImage: status.isConnected ? "checkmark.circle.fill" : "exclamationmark.circle.fill",
                        tint: status.isConnected ? AppColors.positive : AppColors.warning
                    )
                }
            }
            .padding(16)
        }
        .frame(minWidth: width, maxWidth: width, maxHeight: .infinity, alignment: .topLeading)
        .background(AppColors.elevated)
        .shadow(color: .black.opacity(0.12), radius: 18, x: 8, y: 0)
    }

    private func workspaceSidebarButton(
        title: String,
        systemImage: String,
        section: ConnectionWorkspaceSection
    ) -> some View {
        Button {
            selectedWorkspaceSection = section
            withAnimation(.easeInOut(duration: 0.2)) {
                isShowingSettingsSidebar = false
            }
        } label: {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(selectedWorkspaceSection == section ? AppColors.brand : AppColors.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 11)
                .background(selectedWorkspaceSection == section ? AppColors.brand.opacity(0.11) : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var workspaceDetail: some View {
        switch selectedWorkspaceSection {
        case .integrations:
            VStack(alignment: .leading, spacing: 16) {
                header

                if viewModel.isLoading && viewModel.status == nil {
                    loadingView
                } else {
                    statusContent
                }
            }
        case .account:
            accountManagementSection
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionEyebrow("Integraciones", systemImage: "link")

            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Estado de Meta")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(AppColors.ink)

                    Text("Consulta si Facebook e Instagram están listos para recibir publicaciones desde la app.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(AppColors.brand)
                    .frame(width: 50, height: 50)
                    .background(AppColors.brand.opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
        .appCard(cornerRadius: 22, padding: 16)
    }

    private var loadingView: some View {
        HStack(spacing: 10) {
            ProgressView()
            Text("Revisando conexión...")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCard(cornerRadius: 22, padding: 16)
    }

    @ViewBuilder
    private var statusContent: some View {
        if let status = viewModel.status {
            overallCard(status)

            VStack(spacing: 10) {
                ConnectionStatusRow(
                    title: "Token de Meta",
                    subtitle: status.metaTokenConfigured
                        ? "Configurado para esta cuenta"
                        : "No hay token activo configurado",
                    systemImage: "key.fill",
                    isConnected: status.metaTokenConfigured
                )

                ConnectionStatusRow(
                    title: "Facebook",
                    subtitle: status.facebookPageId.map { "Página conectada: \($0)" }
                        ?? "Sin página conectada",
                    systemImage: "f.circle.fill",
                    iconURL: SocialPlatformAsset.facebookIconURL,
                    isConnected: status.facebookConnected
                )

                ConnectionStatusRow(
                    title: "Instagram Business",
                    subtitle: status.instagramUserId.map { "Cuenta conectada: \($0)" }
                        ?? "Sin cuenta Business conectada",
                    systemImage: "camera.fill",
                    iconURL: SocialPlatformAsset.instagramIconURL,
                    isConnected: status.instagramConnected
                )
            }
            .appCard(cornerRadius: 22, padding: 12)

            if let message = status.message, !message.isEmpty {
                infoMessage(message)
            }
        } else if let errorMessage = viewModel.errorMessage {
            errorView(errorMessage)
        }
    }

    private func overallCard(_ status: ConnectionStatus) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: status.isConnected ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                    .font(.title2.weight(.semibold))
                    .foregroundColor(status.isConnected ? AppColors.positive : AppColors.warning)
                    .frame(width: 48, height: 48)
                    .background((status.isConnected ? AppColors.positive : AppColors.warning).opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(status.isConnected ? "Listo para publicar" : "Requiere atención en web")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(AppColors.ink)

                    Text(status.isConnected
                         ? "Meta está conectado para publicar contenido."
                         : "La conexión se administra desde la versión web.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            StatusBadge(
                text: status.isConnected ? "Conectado" : "Pendiente",
                systemImage: status.isConnected ? "checkmark.circle.fill" : "exclamationmark.circle.fill",
                tint: status.isConnected ? AppColors.positive : AppColors.warning
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCard(cornerRadius: 22, padding: 16)
    }

    private func infoMessage(_ message: String) -> some View {
        Text(message)
            .font(.caption)
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .appCard(cornerRadius: 18, padding: 14)
    }

    private func errorView(_ message: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            ConnectionStatusRow(
                title: "No se pudo consultar Meta",
                subtitle: message,
                systemImage: "wifi.exclamationmark",
                isConnected: false
            )

            Button("Reintentar") {
                Task {
                    await viewModel.loadStatus()
                }
            }
            .buttonStyle(PrimaryCapsuleButtonStyle())
        }
        .appCard(cornerRadius: 22, padding: 16)
    }

    private var accountManagementSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionEyebrow("Cuenta", systemImage: "person.crop.circle")

            VStack(alignment: .leading, spacing: 6) {
                Text("Gestión centralizada")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(AppColors.ink)

                Text("Esta app pertenece a un ecosistema cerrado. El alta de usuarios, la privacidad y la eliminación de datos se gestionan desde la plataforma principal.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            AccountDeletionRequestButton(
                title: "Eliminar cuenta",
                subtitle: "Abre la solicitud web de eliminación con acceso temporal.",
                systemImage: "person.crop.circle.badge.xmark",
                tint: AppColors.brand,
                isLoading: viewModel.isRequestingAccountDeletionURL
            ) {
                isShowingAccountDeletionConfirmation = true
            }

            ExternalWebLinkButton(
                title: "Política de privacidad",
                subtitle: "Consulta cómo se gestionan y protegen tus datos.",
                systemImage: "hand.raised.fill",
                url: AppExternalLinks.privacyPolicy,
                tint: AppColors.softInk
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCard(cornerRadius: 22, padding: 16)
    }

    private var accountDeletionErrorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.accountDeletionErrorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    viewModel.accountDeletionErrorMessage = nil
                }
            }
        )
    }

    private func openAccountDeletionRequest() async {
        guard let url = await viewModel.requestAccountDeletionURL() else { return }
        openURL(url)
    }
}

private enum ConnectionWorkspaceSection {
    case integrations
    case account
}

private struct AccountDeletionRequestButton: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let tint: Color
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(tint)
                    .frame(width: 36, height: 36)
                    .background(tint.opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppColors.ink)
                        .multilineTextAlignment(.leading)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: 8)

                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Image(systemName: "arrow.up.forward.app")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(tint)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColors.field)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
        .accessibilityHint("Abre una página web externa para solicitar eliminación de cuenta")
    }
}

private struct ConnectionStatusRow: View {
    let title: String
    let subtitle: String
    let systemImage: String
    var iconURL: URL? = nil
    let isConnected: Bool

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(isConnected ? AppColors.positive.opacity(0.14) : AppColors.warning.opacity(0.14))
                    .frame(width: 42, height: 42)

                platformIcon
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))

                    Image(systemName: isConnected ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(isConnected ? AppColors.positive : AppColors.warning)
                }

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.field)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    @ViewBuilder
    private var platformIcon: some View {
        if let iconURL {
            RetryingRemoteImage(url: iconURL, maxRetries: 1) { state, _ in
                switch state {
                case .loading:
                    ProgressView()
                        .controlSize(.mini)
                case .success(let image):
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                case .failure:
                    Image(systemName: systemImage)
                        .foregroundColor(isConnected ? AppColors.positive : AppColors.warning)
                }
            }
            .frame(width: 22, height: 22)
        } else {
            Image(systemName: systemImage)
                .foregroundColor(isConnected ? AppColors.positive : AppColors.warning)
        }
    }
}

private enum SocialPlatformAsset {
    static let facebookIconURL = URL(string: "https://ljdit.com/static/platforms/facebook.png")
    static let instagramIconURL = URL(string: "https://ljdit.com/static/platforms/instagram.png")
}
