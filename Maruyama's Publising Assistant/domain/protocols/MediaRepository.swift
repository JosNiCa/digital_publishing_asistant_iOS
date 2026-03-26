//
//  MediaRepository.swift
//  Maruyama's Publising Assistant
//
//  Created by LJD Technology on 26/03/26.
//

protocol MediaRepository {
    func fetchPhotos() async throws -> [Photo]
}
