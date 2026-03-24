//
//  LoginViewModel.swift
//  Maruyama's Publising Assistant
//
//  Created by LJD Technology on 23/03/26.
//

import Combine

@MainActor
final class LoginViewModel: ObservableObject {
    
    @Published var username = ""
    @Published var password = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let authRepository: AuthRepository
    
    init(authRepository: AuthRepository) {
        self.authRepository = authRepository
    }
    
    func login() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let session = try await authRepository.login(
                username: username,
                password: password
            )
            
            // TODO: guardar token (Keychain)
            print("Login exitoso:", session.token)
            
        } catch {
            errorMessage = "Credenciales incorrectas"
        }
        
        isLoading = false
    }
}

