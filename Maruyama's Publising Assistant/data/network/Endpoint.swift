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
    case getDistributors
    case fusionPreview(photoId: Int)
    
    var path: String {
        switch self {
        case .login:
            return "/api/accounts/mobile/"
            
        case .me:
            return "/api/accounts/me/"
            
        case .getPhotos:
            return "/api/media_library/photos/"
            
        case .getDistributors:
            return "api/media_library/distributors/"
            
        case .fusionPreview(let photoId):
            return "api/media_library/fusion/preview/\(photoId)/"
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
            case .getDistributors:
                return "GET"
            case .fusionPreview:
                return "POST"
        }
    }
}
