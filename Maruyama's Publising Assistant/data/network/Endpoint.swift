//
//  Endpoint.swift
//  Maruyama's Publising Assistant
//
//  Created by LJD Technology on 23/03/26.
//

enum Endpoint {
    case login
    case me
    
    var path: String {
        switch self {
        case .login:
            return "/api/accounts/mobile/"
            
        case .me:
            return "/api/accounts/me/"
        }
    }
    
    var method: String {
            switch self {
            case .login:
                return "POST"
            case .me:
                return "GET"
        }
    }
}
