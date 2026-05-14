//
//  AppDesignSystem.swift
//  Maruyama's Publising Assistant
//

import SwiftUI

enum AppColors {
    static let brand = Color(red: 0.82, green: 0.08, blue: 0.12)
    static let brandDark = Color(red: 0.52, green: 0.03, blue: 0.08)
    static let ink = Color(red: 0.08, green: 0.08, blue: 0.10)
    static let softInk = Color(red: 0.34, green: 0.34, blue: 0.38)
    static let canvas = Color(.systemGroupedBackground)
    static let elevated = Color(.secondarySystemGroupedBackground)
    static let field = Color(.tertiarySystemGroupedBackground)
    static let positive = Color(red: 0.08, green: 0.55, blue: 0.27)
    static let warning = Color(red: 0.93, green: 0.55, blue: 0.12)
}

struct AppScreenBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(AppColors.canvas.ignoresSafeArea())
    }
}

extension View {
    func appScreenBackground() -> some View {
        modifier(AppScreenBackground())
    }

    func appCard(
        cornerRadius: CGFloat = 18,
        padding: CGFloat = 16
    ) -> some View {
        self
            .padding(padding)
            .background(AppColors.elevated)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: .black.opacity(0.05), radius: 18, x: 0, y: 8)
    }
}

struct SectionEyebrow: View {
    let title: String
    let systemImage: String?

    init(_ title: String, systemImage: String? = nil) {
        self.title = title
        self.systemImage = systemImage
    }

    var body: some View {
        HStack(spacing: 7) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.caption.weight(.bold))
            }

            Text(title.uppercased())
                .font(.caption2.weight(.bold))
        }
        .foregroundStyle(.secondary)
        .tracking(0.8)
    }
}

struct PrimaryCapsuleButtonStyle: ButtonStyle {
    var isEnabled = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                LinearGradient(
                    colors: isEnabled
                        ? [AppColors.brand, AppColors.brandDark]
                        : [Color.gray.opacity(0.45), Color.gray.opacity(0.35)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.spring(response: 0.22, dampingFraction: 0.75), value: configuration.isPressed)
    }
}

struct SecondaryCapsuleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .foregroundStyle(AppColors.ink)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(AppColors.field)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.spring(response: 0.22, dampingFraction: 0.75), value: configuration.isPressed)
    }
}

struct StatusBadge: View {
    let text: String
    let systemImage: String
    let tint: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.caption.weight(.bold))

            Text(text)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(tint.opacity(0.12))
        .clipShape(Capsule())
    }
}

struct EmptyStateView: View {
    let title: String
    let message: String
    let systemImage: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(AppColors.brand)
                .frame(width: 72, height: 72)
                .background(AppColors.brand.opacity(0.10))
                .clipShape(Circle())

            VStack(spacing: 6) {
                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(AppColors.ink)

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(.subheadline.weight(.semibold))
                    .buttonStyle(.borderedProminent)
                    .tint(AppColors.brand)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 34)
        .padding(.horizontal, 18)
    }
}
