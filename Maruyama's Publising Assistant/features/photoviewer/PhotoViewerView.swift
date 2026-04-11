//
//  PhotoViewerView.swift
//  Maruyama's Publising Assistant
//
//  Created by LJD Technology on 28/03/26.
//


import SwiftUI

struct PhotoViewerView: View {
    
    @StateObject private var viewModel: PhotoViewerViewModel
    
    init(photo: Photo, distributorRepository: DistributorRepository, fusionRepository: FusionRepository) {
        _viewModel = StateObject(
            wrappedValue: PhotoViewerViewModel(
                photo: photo,
                distributorRepository: distributorRepository,
                fusionRepository: fusionRepository
            )
        )
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                    imageSection
                    distributorSection
                    actionsSection
                }

                .padding()
            }
            .navigationTitle("Detalle")
            .task {
                await viewModel.loadDistributors()
            }
    }
    
    private var imageSection: some View {
        
        ZStack {
            
            imageView
            
            GeometryReader { geo in
                pointsOverlay(viewSize: geo.size)
            }
            
            if viewModel.isApplyngFusion {
                Color.black.opacity(0.4)
                
                ProgressView("Aplicando logo...")
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
            }
        }
        .frame(height: 300)
    }
    
    private var distributorSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Selecciona un distribuidor")
        
            if viewModel.isLoadingDistributors {
                ProgressView("Cargando distribuidores")
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))]) {
                    
                    ForEach(viewModel.distributors) { distributor in
                        
                        VStack {
                            AsyncImage(url: URL(string: distributor.logoUrl)) { phase in
                                
                                switch phase {
                                case .empty:
                                    ProgressView()
                                    
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 60)
                                    
                                case .failure:
                                    Text(String(distributor.name.prefix(2)))
                                        .frame(height: 60)
                                    
                                default:
                                    EmptyView()
                                }
                            }
                            
                            Text(distributor.name)
                                .font(.caption)
                                .lineLimit(1)
                        }
                        .padding(6)
                        .background(
                            viewModel.selectedDistributorId == distributor.id
                            ? Color.blue.opacity(0.2)
                            : Color.clear
                        )
                        .cornerRadius(8)
                        .onTapGesture {
                            viewModel.selectedDistributorId = distributor.id
                        }
                    }
                }
            }
        }
    }
    
    private var actionsSection: some View {
        Button("Aplicar cambios") {
            Task {
                await viewModel.applyFusion()
            }
        }
        .disabled(
            viewModel.selectedDistributorId == nil ||
            viewModel.selectedCoordinate == nil
        )
    }
    
    @ViewBuilder
    private func pointsOverlay(viewSize: CGSize) -> some View {
        
        let originalWidth = viewModel.imageSize.width
        let originalHeight = viewModel.imageSize.height
        
        if originalWidth > 0, originalHeight > 0 {
            
        let (scale, xOffset, yOffset): (CGFloat, CGFloat, CGFloat) = {
            let imageAspect = originalWidth / originalHeight
            let viewAspect = viewSize.width / viewSize.height
                
            if imageAspect > viewAspect {
                let scale = viewSize.width / originalWidth
                let scaledHeight = originalHeight * scale
                return (scale, 0, (viewSize.height - scaledHeight) / 2)
            } else {
                let scale = viewSize.height / originalHeight
                let scaledWidth = originalWidth * scale
                return (scale, (viewSize.width - scaledWidth) / 2, 0)
            }
        }()
            
        let points = [
            (id: 1, x: 594.0, y: 1013.0),
            (id: 2, x: 1200.0, y: 800.0),
            (id: 3, x: 2000.0, y: 1500.0)
        ]
        
        ZStack {
            ForEach(points, id: \.id) { point in
                
                let posX = point.x * scale + xOffset
                let posY = point.y * scale + yOffset
                    
                Circle()
                    .fill(viewModel.selectedCoordinate == point.id ? Color.green : Color.red)
                    .frame(width: 20, height: 20)
                    .overlay(
                        Circle().stroke(Color.white, lineWidth: 2)
                    )
                    .shadow(radius: 3)
                    .position(x: posX, y: posY)
                    .onTapGesture {
                        viewModel.selectedCoordinate = point.id
                    }
                }
            }
            
        } else {
            EmptyView()
        }
    }
    
    @ViewBuilder
    private var imageView: some View {
        
        if let base64 = viewModel.fusionImageBase64 {
            
            let cleanedBase64 = base64
                .replacingOccurrences(of: "\n", with: "")
                .replacingOccurrences(of: "\r", with: "")
            
            if let data = Data(base64Encoded: cleanedBase64),
               let uiImage = UIImage(data: data) {
                
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .onAppear {
                        viewModel.imageSize = uiImage.size
                    }
                
            } else {
                Text("Error imagen fusionada")
            }
            
        } else {
            
            AsyncImage(url: URL(string: viewModel.photo.imageUrl)) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                        .onAppear()
                case .failure:
                    Text("Error")
                default:
                    EmptyView()
                }
            }
        }
    }
}
