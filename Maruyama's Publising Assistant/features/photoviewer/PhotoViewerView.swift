//
//  PhotoViewerView.swift
//  Maruyama's Publising Assistant
//
//  Created by LJD Technology on 28/03/26.
//


import SwiftUI

struct PhotoViewerView: View {
    
    @StateObject private var viewModel: PhotoViewerViewModel
    
    init(photo: Photo) {
        _viewModel = StateObject(
            wrappedValue: PhotoViewerViewModel(photo: photo)
        )
    }
    
    var body: some View {
        content
            .navigationTitle("Detalle")
            .navigationBarTitleDisplayMode(.inline)
    }
    
    @ViewBuilder
    private var content: some View {
        AsyncImage(url: URL(string: viewModel.photo.imageUrl)) { phase in
            
            switch phase {
                
            case .empty:
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
            case .success(let image):
                image
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black)
                
            case .failure:
                VStack {
                    Image(systemName: "photo")
                    Text("Error al cargar imagen")
                }
                
            @unknown default:
                EmptyView()
            }
        }
    }
}
