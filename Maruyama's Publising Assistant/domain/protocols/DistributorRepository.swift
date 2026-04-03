//
//  DistributorRepository.swift
//  Maruyama's Publising Assistant
//
//  Created by LJD Technology on 30/03/26.
//


protocol DistributorRepository {
    func fetchDistributors() async throws -> [Distributor]
}