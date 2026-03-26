//
//  ContentView.swift
//  Maruyama's Publising Assistant
//
//  Created by LJD Technology on 23/03/26.
//

import SwiftUI

struct LoginView: View {
    
    @StateObject private var viewModel: LoginViewModel
    
    init(authRepository: AuthRepository) {
        _viewModel = StateObject(
            wrappedValue: LoginViewModel(authRepository: authRepository)
        )
    }
    
    var body: some View {
        VStack(spacing: 20) {
            
            Text("Login")
                .font(.largeTitle)
                .bold()
            
            TextField("Usuario", text: $viewModel.username)
                .textFieldStyle(.roundedBorder)
                .autocapitalization(.none)
            
            SecureField("Contraseña", text: $viewModel.password)
                .textFieldStyle(.roundedBorder)
            
            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            Button(action: {
                Task {
                    await viewModel.login()
                }
            }) {
                if viewModel.isLoading {
                    ProgressView()
                } else {
                    Text("Iniciar sesión")
                        .frame(maxWidth: .infinity)
                }
            }
            .disabled(viewModel.isLoading)
            .buttonStyle(.borderedProminent)
            
        }
        .padding()
    }
}

#Preview {
    LoginView()
}
