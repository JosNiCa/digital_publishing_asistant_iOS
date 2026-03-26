//
//  Endpoint.swift
//  Maruyama's Publising Assistant
//
//  Created by LJD Technology on 23/03/26.
//

enum Endpoint {
    case login
    case me
    case getPhotos
    
    var path: String {
        switch self {
        case .login:
            return "/api/accounts/mobile/"
            
        case .me:
            return "/api/accounts/me/"
            
        case .getPhotos:
            return "/api/media_library/photos/"
        }
    }
    
    var method: String {
            switch self {
            case .login:
                return "POST"
            case .me:
                return "GET"
            case .getPhotos:
                return "GET"
        }
    }
}
