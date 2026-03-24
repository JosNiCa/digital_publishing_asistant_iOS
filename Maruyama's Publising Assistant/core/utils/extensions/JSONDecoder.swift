//
//  JSONDecoder.swift
//  Maruyama's Publising Assistant
//
//  Created by LJD Technology on 24/03/26.
//

extension JSONDecoder {
    static var apiDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }
}
