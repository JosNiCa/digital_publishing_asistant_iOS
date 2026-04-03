//
//  DistributorDTO.swift
//  Maruyama's Publising Assistant
//
//  Created by LJD Technology on 30/03/26.
//


struct DistributorDTO: Decodable {
    let id: Int
    let name: String
    let logoUrl: String
}

extension DistributorDTO {
    func toDomain() -> Distributor {
        Distributor(
            id: id,
            name: name,
            logoUrl: logoUrl
        )
    }
}