//
//  AuthRepository.swift
//  Maruyama's Publising Assistant
//
//  Created by LJD Technology on 23/03/26.
//

protocol AuthRepository {
    func login(username: String, password: String) async throws -> AuthSession
}
