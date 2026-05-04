//
//  String.swift
//  Maruyama's Publising Assistant
//
//  Created by LJD Technology on 01/05/26.
//

import Foundation

extension String {
    
    func toDate() -> Date? {
        let formatter = ISO8601DateFormatter()
        
        // Para cubrir formatos comunes del backend
        formatter.formatOptions = [
            .withInternetDateTime,
            .withFractionalSeconds
        ]
        
        return formatter.date(from: self)
            ?? ISO8601DateFormatter().date(from: self)
    }
}
