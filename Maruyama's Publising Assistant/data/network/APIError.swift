//
//  APIError.swift
//  Maruyama's Publising Assistant
//
//  Created by LJD Technology on 24/03/26.
//

enum APIError: Error {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case serverError(code: String?, message: String)
    case unauthorized
    case unknown
}
