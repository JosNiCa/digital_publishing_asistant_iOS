//
//  ImageDataDecoder.swift
//  Maruyama's Publising Assistant
//
//  Created by Codex on 26/05/26.
//

import UIKit

enum ImageDataDecoder {

    static func image(fromBase64 base64: String) -> UIImage? {
        guard let data = Data(base64Encoded: cleanedBase64(base64)) else {
            return nil
        }

        return UIImage(data: data)
    }

    static func imageSize(fromBase64 base64: String) -> CGSize? {
        image(fromBase64: base64)?.size
    }

    private static func cleanedBase64(_ base64: String) -> String {
        base64
            .replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "\r", with: "")
            .replacingOccurrences(of: "data:image/png;base64,", with: "")
            .replacingOccurrences(of: "data:image/jpeg;base64,", with: "")
            .replacingOccurrences(of: "data:image/jpg;base64,", with: "")
    }
}
