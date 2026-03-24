//
//  AuthError.swift
//  Maruyama's Publising Assistant
//
//  Created by LJD Technology on 23/03/26.
//

enum AuthError: Error {
    case invalidCredentials
    case notApproved
    case mustChangePassword
    case server(String)
}
