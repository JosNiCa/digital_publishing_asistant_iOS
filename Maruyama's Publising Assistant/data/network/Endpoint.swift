//
//  Endpoint.swift
//  Maruyama's Publising Assistant
//
//  Created by LJD Technology on 23/03/26.
//

enum Endpoint {
    case login
    case me
    case getPhotos(page: Int, pageSize: Int, includeAllStates: Bool)
    case getDistributors
    case fusionPreview(photoId: Int)
    case fusionDetail(fusionId: Int)
    case publishFusion
    case deletePublishedPost
    case scheduledPosts
    case publishingHealth
    case fusionSave(photoId: Int)
    case verifyConnection
    case fusionsList
    
    var path: String {
        switch self {
        case .login:
            return "/api/accounts/mobile/"
            
        case .me:
            return "/api/accounts/me/"
            
        case .getPhotos(let page, let pageSize, let includeAllStates):
            let state = includeAllStates ? "&estado=todas" : ""
            return "/api/media_library/photos/?page=\(page)&page_size=\(pageSize)\(state)"
            
        case .getDistributors:
            return "/api/media_library/distributors/"
            
        case .fusionPreview(let photoId):
            return "/api/media_library/fusion/preview/\(photoId)/"

        case .fusionDetail(let fusionId):
            return "/api/media_library/fusion/\(fusionId)/"
            
        case .publishFusion:
            return "/api/publishing/publicar-fusion/"

        case .deletePublishedPost:
            return "/api/publishing/eliminar-post/"

        case .scheduledPosts:
            return "/api/publishing/programadas/"

        case .publishingHealth:
            return "/api/publishing/health/"
            
        case .fusionSave(let photoId):
            return "/api/media_library/fusion/save/\(photoId)/"
            
        case .verifyConnection:
            return "/api/publishing/conexion/"
            
        case .fusionsList:
            return "/api/media_library/fusions/"
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
            case .fusionDetail:
                return "GET"
            case .publishFusion:
                return "POST"
            case .deletePublishedPost:
                return "POST"
            case .scheduledPosts:
                return "GET"
            case .publishingHealth:
                return "GET"
            case .fusionSave:
                return "POST"
            case .verifyConnection:
                return "GET"
            case .fusionsList:
                return "GET"
        }
    }
}
