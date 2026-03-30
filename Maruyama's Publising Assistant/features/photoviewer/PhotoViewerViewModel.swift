//
//  PhotoViewerViewModel.swift
//  Maruyama's Publising Assistant
//
//  Created by LJD Technology on 28/03/26.
//

import Combine

@MainActor
final class PhotoViewerViewModel: ObservableObject {

    let photo: Photo

    init(photo: Photo) {
        self.photo = photo
    }
}
