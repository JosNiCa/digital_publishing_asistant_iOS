//
//  PublishingActivityCenter.swift
//  Maruyama's Publising Assistant
//

import Combine
import SwiftUI

@MainActor
final class PublishingActivityCenter: ObservableObject {
    static let shared = PublishingActivityCenter()

    enum State: Equatable {
        case idle
        case publishing(isScheduled: Bool)
        case completed(FusionCompletionResult)
        case failed(String)
    }

    @Published private(set) var state: State = .idle
    private var dismissTask: Task<Void, Never>?

    private init() {}

    func begin(isScheduled: Bool) {
        dismissTask?.cancel()
        state = .publishing(isScheduled: isScheduled)
    }

    func complete(_ result: FusionCompletionResult) {
        state = .completed(result)
        scheduleDismiss()
    }

    func fail(_ message: String) {
        state = .failed(message)
        scheduleDismiss()
    }

    func dismiss() {
        dismissTask?.cancel()
        state = .idle
    }

    private func scheduleDismiss() {
        dismissTask?.cancel()
        dismissTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 4_500_000_000)
            self?.dismiss()
        }
    }
}

struct PublishingActivityOverlay: View {
    @ObservedObject var activity: PublishingActivityCenter

    var body: some View {
        if activity.state != .idle {
            HStack(spacing: 12) {
                leadingIcon

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(AppColors.ink)

                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer(minLength: 8)
            }
            .padding(14)
            .background(Color(.systemBackground))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(borderColor, lineWidth: 1.5)
            }
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: .black.opacity(0.18), radius: 22, x: 0, y: 10)
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .animation(.spring(response: 0.28, dampingFraction: 0.82), value: activity.state)
            .allowsHitTesting(false)
        }
    }

    @ViewBuilder
    private var leadingIcon: some View {
        switch activity.state {
        case .publishing:
            ProgressView()
                .tint(AppColors.brand)
                .frame(width: 34, height: 34)
                .background(AppColors.brand.opacity(0.10))
                .clipShape(Circle())
        case .completed:
            Image(systemName: "checkmark.circle.fill")
                .font(.title2.weight(.semibold))
                .foregroundStyle(AppColors.positive)
                .frame(width: 34, height: 34)
        case .failed:
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title3.weight(.semibold))
                .foregroundStyle(AppColors.brand)
                .frame(width: 34, height: 34)
        case .idle:
            EmptyView()
        }
    }

    private var title: String {
        switch activity.state {
        case .publishing(let isScheduled):
            return isScheduled ? "Programando publicación" : "Publicando contenido"
        case .completed(let result):
            return result.title
        case .failed:
            return "No se pudo publicar"
        case .idle:
            return ""
        }
    }

    private var message: String {
        switch activity.state {
        case .publishing:
            return "Puedes seguir navegando. Te avisamos cuando Meta responda."
        case .completed(let result):
            return result.message
        case .failed(let message):
            return message
        case .idle:
            return ""
        }
    }

    private var borderColor: Color {
        switch activity.state {
        case .publishing:
            return AppColors.brand.opacity(0.45)
        case .completed:
            return AppColors.positive.opacity(0.45)
        case .failed:
            return AppColors.brand.opacity(0.45)
        case .idle:
            return .clear
        }
    }
}
