//
//  LoginView.swift
//  Maruyama's Publising Assistant
//
//  Created by LJD Technology on 23/03/26.
//

import SwiftUI

struct LoginView: View {
    
    @StateObject private var loginViewModel: LoginViewModel
    @FocusState private var focusedField: LoginField?
    
    init(authRepository: AuthRepository) {
        _loginViewModel = StateObject(
            wrappedValue: LoginViewModel(authRepository: authRepository)
        )
    }
    
    var body: some View {
        GeometryReader { geometry in
            AppColors.canvas.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .center, spacing: 0) {
                    Spacer(minLength: 40)

                    VStack(alignment: .center, spacing: 28) {
                        header

                        VStack(spacing: 16) {
                            credentialsCard
                            loginAction
                        }
                        .frame(maxWidth: 420)
                    }

                    Spacer(minLength: 36)

                    registrationNotice
                        .frame(maxWidth: 420)
                }
                .frame(maxWidth: .infinity)
                .frame(minHeight: geometry.size.height, alignment: .center)
                .padding(.horizontal, 22)
                .padding(.bottom, 24)
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }

    private var header: some View {
        VStack(alignment: .center, spacing: 8) {
            Text("Maruyama")
                .font(.system(size: 38, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.ink)
        }
        .frame(maxWidth: .infinity)
    }

    private var credentialsCard: some View {
        VStack(alignment: .leading, spacing: 16) {

            VStack(spacing: 12) {
                inputRow(
                    title: "Correo",
                    systemImage: "person.crop.circle",
                    isFocused: focusedField == .username
                ) {
                    TextField("tu correo", text: $loginViewModel.username)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($focusedField, equals: .username)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .password }
                }

                inputRow(
                    title: "Contraseña",
                    systemImage: "key.fill",
                    isFocused: focusedField == .password
                ) {
                    SecureField("tu contraseña", text: $loginViewModel.password)
                        .focused($focusedField, equals: .password)
                        .submitLabel(.go)
                        .onSubmit { performLogin() }
                }
            }

            if let error = loginViewModel.errorMessage {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "exclamationmark.circle.fill")
                    Text(error)
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppColors.brand)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppColors.brand.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .appCard(cornerRadius: 24, padding: 18)
    }

    private var loginAction: some View {
        Button(action: performLogin) {
            HStack(spacing: 10) {
                if loginViewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "arrow.right.circle.fill")
                    Text("Iniciar sesión")
                }
            }
        }
        .disabled(loginViewModel.isLoading)
        .buttonStyle(PrimaryCapsuleButtonStyle(isEnabled: !loginViewModel.isLoading))
    }

    private var registrationNotice: some View {
        VStack(spacing: 6) {
            // App Store 5.1.1: reviewers and users can see that accounts are provisioned
            // through the existing web platform without competing visually with the login form.
            Text("¿No tienes una cuenta? Las cuentas se crean en nuestra plataforma web.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            InlineWebLink(
                title: "Regístrate en la plataforma web",
                url: AppExternalLinks.registration
            )

            InlineWebLink(
                title: "Política de privacidad",
                url: AppExternalLinks.privacyPolicy,
                font: .caption.weight(.medium)
            )
        }
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity)
    }

    private func inputRow<Content: View>(
        title: String,
        systemImage: String,
        isFocused: Bool,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.headline)
                .foregroundStyle(isFocused ? AppColors.brand : .secondary)
                .frame(width: 26)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                content()
                    .font(.body.weight(.medium))
            }
        }
        .padding(14)
        .background(AppColors.field)
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(isFocused ? AppColors.brand.opacity(0.45) : Color.clear, lineWidth: 1.5)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func performLogin() {
        guard !loginViewModel.isLoading else { return }
        Task {
            await loginViewModel.login()
        }
    }
}

private enum LoginField {
    case username
    case password
}
