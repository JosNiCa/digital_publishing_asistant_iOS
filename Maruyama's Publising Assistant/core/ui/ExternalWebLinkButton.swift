//
//  ExternalWebLinkButton.swift
//  Maruyama's Publising Assistant
//

import SwiftUI

struct ExternalWebLinkButton: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let url: URL?
    var tint: Color = AppColors.brand
    var requiresConfirmation = false
    var confirmationTitle = "Abrir enlace externo"
    var confirmationMessage = "Se abrirá una página web fuera de la aplicación."

    @Environment(\.openURL) private var openURL
    @State private var isShowingConfirmation = false

    var body: some View {
        Button {
            guard url != nil else { return }

            if requiresConfirmation {
                isShowingConfirmation = true
            } else {
                openExternalURL()
            }
        } label: {
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

                Image(systemName: url == nil ? "lock.fill" : "arrow.up.forward.app")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(url == nil ? .secondary : tint)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColors.field)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(url == nil)
        .opacity(url == nil ? 0.62 : 1)
        .accessibilityHint(url == nil ? "Enlace pendiente de configurar" : "Abre una página web externa")
        .alert(confirmationTitle, isPresented: $isShowingConfirmation) {
            Button("Cancelar", role: .cancel) {}
            Button("Continuar") {
                openExternalURL()
            }
        } message: {
            Text(confirmationMessage)
        }
    }

    private func openExternalURL() {
        guard let url else { return }
        openURL(url)
    }
}

struct InlineWebLink: View {
    let title: String
    let url: URL
    var font: Font = .footnote.weight(.semibold)
    var tint: Color = .blue

    @Environment(\.openURL) private var openURL

    var body: some View {
        Button {
            openURL(url)
        } label: {
            Text(title)
                .font(font)
                .foregroundStyle(tint)
                .underline()
                .multilineTextAlignment(.center)
        }
        .buttonStyle(.plain)
        .accessibilityHint("Abre una página web externa")
    }
}
