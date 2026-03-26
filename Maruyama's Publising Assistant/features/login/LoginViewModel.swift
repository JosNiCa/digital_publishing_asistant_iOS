//
//  LoginViewModel.swift
//  Maruyama's Publising Assistant
//
//  Created by LJD Technology on 23/03/26.
//

import Combine

@MainActor
final class LoginViewModel: ObservableObject {
    
    @Published var username = "iOSDev"
    @Published var password = "iOSPrueba1"
    @Published var isLoading : Bool = false
    @Published var errorMessage: String?
    
    private let authRepository: AuthRepository
    
    init(authRepository: AuthRepository) {
        self.authRepository = authRepository
    }
    
    @MainActor
    func login() async {
        guard !username.isEmpty, !password.isEmpty else {
            errorMessage = "Por favor, ingrese sus credenciales"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            _ = try await authRepository.login(
                username: username,
                password: password
            )
            
        } catch let error as AuthError{
            switch error {
            case .invalidCredentials:
                errorMessage = "Credenciales incorrectas"
            case .notApproved:
                errorMessage = "Cuenta no aprobada"
            case .mustChangePassword:
                errorMessage = "Debes cambiar tu contraseña"
            case .server(let string):
                errorMessage = errorMessage ?? string
            }
        }catch {
            errorMessage = "Error inesperado"
        }
        
        isLoading = false
    }
}

