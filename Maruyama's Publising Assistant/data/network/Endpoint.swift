//
//  Endpoint.swift
//  Maruyama's Publising Assistant
//
//  Created by LJD Technology on 23/03/26.
//

enum Endpoint {
    case login
    
    var path: String {
        switch self {
        case .login:
            return "/api/accounts/mobile/"
        }
    }
    
    var method: String {
        return "POST"
    }
}
