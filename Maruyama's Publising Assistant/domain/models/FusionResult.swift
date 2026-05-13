//
//  FusionResult.swift
//  Maruyama's Publising Assistant
//
//  Created by LJD Technology on 01/04/26.
//

struct FusionResult {
    let imageBase64: String
    let x: Int?
    let y: Int?
    let coordinate: Int?
}

struct FusionDetail {
    let imageBase64: String
    let photoId: Int
    let distributorId: Int
    let coordinate: Int
    let caption: String?
}
