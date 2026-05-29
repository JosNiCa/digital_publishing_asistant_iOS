//
//  Distributor.swift
//  Maruyama's Publising Assistant
//
//  Created by LJD Technology on 30/03/26.
//


struct Distributor: Identifiable {
    let id: Int
    let name: String
    let logoId: Int?
    let logoUrl: String?
    let logos: [DistributorLogo]
}

struct DistributorLogo: Identifiable, Hashable {
    let id: Int
    let imageUrl: String
}
