//
//  JSONDecoder.swift
//  Maruyama's Publising Assistant
//
//  Created by LJD Technology on 24/03/26.
//

import Foundation

extension JSONDecoder {
    
    static var apiDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        if #available(iOS 15.0, *) {
            decoder.dateDecodingStrategy = .iso8601
        }
        
        return decoder
    }
}
