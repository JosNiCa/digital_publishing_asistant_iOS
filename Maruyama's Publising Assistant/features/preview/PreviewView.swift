//
//  PreviewView.swift
//  Maruyama's Publising Assistant
//
//  Created by LJD Technology on 14/04/26.
//

import SwiftUI

struct PreviewView: View {
    let imageBase64: String
    let photoId: Int
    let distributorId: Int
    let coordinate: Int
    
    var body: some View {
        VStack(spacing: 16) {
            Group {
                let cleanedBase64 = imageBase64
                    .replacingOccurrences(of: "\n", with: "")
                    .replacingOccurrences(of: "\r", with: "")
                    .replacingOccurrences(of: "data:image/png;base64,", with: "")
                    .replacingOccurrences(of: "data:image/jpeg;base64,", with: "")
                    .replacingOccurrences(of: "data:image/jpg;base64,", with: "")
                if let data = Data(base64Encoded: cleanedBase64), let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                } else {
                    Text("❌ Error al mostrar la imagen base64")
                        .foregroundColor(.red)
                }
            }
            VStack(alignment: .leading, spacing: 8) {
                Text("Photo ID: \(photoId)")
                Text("Distributor ID: \(distributorId)")
                Text("Coordinate: \(coordinate)")
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
        .padding()
        .navigationTitle("Preview")
    }
}
