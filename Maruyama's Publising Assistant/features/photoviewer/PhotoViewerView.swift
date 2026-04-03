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
                    coordinateSection
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
        Group {
            if let base64 = viewModel.fusionImageBase64 {
                
                let cleanedBase64 = base64
                    .replacingOccurrences(of: "\n", with: "")
                    .replacingOccurrences(of: "\r", with: "")
                    .replacingOccurrences(of: "data:image/png;base64,", with: "")
                    .replacingOccurrences(of: "data:image/jpeg;base64,", with: "")
                    .replacingOccurrences(of: "data:image/jpg;base64,", with: "")
                
                if let data = Data(base64Encoded: cleanedBase64) {
                    
                    if let uiImage = UIImage(data: data) {
                        
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                        
                    } else {
                        Text("❌ UIImage no se pudo crear")
                            .foregroundColor(.red)
                    }
                    
                } else {
                    Text("❌ Base64 inválido")
                        .foregroundColor(.red)
                }
                
            } else {
                AsyncImage(url: URL(string: viewModel.photo.imageUrl)) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let image):
                        image.resizable().scaledToFit()
                    case .failure:
                        Text("Error")
                    default:
                        EmptyView()
                    }
                }
            }
        }
    }
    
    private var distributorSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Selecciona un distribuidor")
        
            if viewModel.isLoading {
                ProgressView()
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
    
    private var coordinateSection: some View {
        VStack(alignment: .leading) {
            Text("Selecciona posición")
            
            HStack {
                ForEach([1,2,3], id: \.self) { index in
                    Text("P\(index)")
                        .padding()
                        .background(
                            viewModel.selectedCoordinate == index
                            ? Color.green
                            : Color.gray.opacity(0.2)
                        )
                        .onTapGesture {
                            viewModel.selectedCoordinate = index
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
}
