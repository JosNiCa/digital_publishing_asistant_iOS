//
//  FusionSession.swift
//  Maruyama's Publising Assistant
//
//  Created by LJD Technology on 29/04/26.
//

import Combine

@MainActor
final class FusionSession: ObservableObject {

    static let shared = FusionSession()

    @Published var fusionId: Int?
    @Published var photoId: Int?
    @Published var distributorId: Int?
    @Published var coordinate: Int?

    func fusionId(
        matchingPhotoId photoId: Int,
        distributorId: Int,
        coordinate: Int
    ) -> Int? {
        guard self.photoId == photoId,
              self.distributorId == distributorId,
              self.coordinate == coordinate else {
            return nil
        }

        return fusionId
    }

    func clear() {
        fusionId = nil
        photoId = nil
        distributorId = nil
        coordinate = nil
    }
}
