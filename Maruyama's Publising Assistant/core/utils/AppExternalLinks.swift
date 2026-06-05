//
//  AppExternalLinks.swift
//  Maruyama's Publising Assistant
//

import Foundation

enum AppExternalLinks {
    static let registration = URL(string: "https://www.ljdit.com/registro/")!
    static let privacyPolicy = URL(string: "https://www.ljdit.com/privacy-policy/")!

    // Apple account deletion compliance: keep the in-app entry point visible now.
    // Replace nil with URL(string: "https://...") when the web deletion workflow is available.
    static let accountDeletion: URL? = nil
}
