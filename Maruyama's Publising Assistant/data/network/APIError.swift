//
//  APIError.swift
//  Maruyama's Publising Assistant
//
//  Created by LJD Technology on 24/03/26.
//

import Foundation

enum APIError: Error {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case serverError(code: String?, message: String)
    case unauthorized
    case missingToken
    case unknown
}

extension APIError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "URL inválida"
        case .networkError(let error):
            return "Error de red: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Respuesta inválida del servidor: \(error.localizedDescription)"
        case .serverError(_, let message):
            return message
        case .unauthorized:
            return "No autorizado"
        case .missingToken:
            return "Sesión local sin token. Inicia sesión nuevamente."
        case .unknown:
            return "Error desconocido"
        }
    }
}
