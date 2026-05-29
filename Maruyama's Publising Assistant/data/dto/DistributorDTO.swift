//
//  DistributorDTO.swift
//  Maruyama's Publising Assistant
//
//  Created by LJD Technology on 30/03/26.
//

struct DistributorDTO: Decodable {
    let id: Int
    let name: String
    let logoId: Int?
    let logoUrl: String?
    let logos: [DistributorLogoDTO]?
}

struct DistributorLogoDTO: Decodable {
    let id: Int
    let imageUrl: String
}

extension DistributorDTO {
    func toDomain() -> Distributor {
        let domainLogos = (logos ?? []).map {
            DistributorLogo(
                id: $0.id,
                imageUrl: $0.imageUrl
            )
        }

        let compatibleLogos: [DistributorLogo]
        if domainLogos.isEmpty,
           let logoUrl {
            compatibleLogos = [
                DistributorLogo(
                    id: logoId ?? id,
                    imageUrl: logoUrl
                )
            ]
        } else {
            compatibleLogos = domainLogos
        }

        return Distributor(
            id: id,
            name: name,
            logoId: logoId,
            logoUrl: logoUrl,
            logos: compatibleLogos
        )
    }
}
