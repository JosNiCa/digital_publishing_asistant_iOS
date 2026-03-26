//
//  ContentView.swift
//  Maruyama's Publising Assistant
//
//  Created by LJD Technology on 23/03/26.
//

import SwiftUI

struct LoginView: View {
    
    @StateObject private var loginViewModel: LoginViewModel
    
    init(authRepository: AuthRepository) {
        _loginViewModel = StateObject(
            wrappedValue: LoginViewModel(authRepository: authRepository)
        )
    }
    
    var body: some View {
        VStack(spacing: 20) {
            
            Text("Login")
                .font(.largeTitle)
                .bold()
            
            TextField("Usuario", text: $loginViewModel.username)
                .textFieldStyle(.roundedBorder)
                .autocapitalization(.none)
            
            SecureField("Contraseña", text: $loginViewModel.password)
                .textFieldStyle(.roundedBorder)
            
            if let error = loginViewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            Button(action: {
                Task {
                    await loginViewModel.login()
                }
            }) {
                if loginViewModel.isLoading {
                    ProgressView()
                } else {
                    Text("Iniciar sesión")
                        .frame(maxWidth: .infinity)
                }
            }
            .disabled(loginViewModel.isLoading)
            .buttonStyle(.borderedProminent)
            
        }
        .padding()
    }
}
