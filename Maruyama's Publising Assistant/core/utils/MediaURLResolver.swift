//
//  MediaURLResolver.swift
//  Maruyama's Publising Assistant
//
//  Created by Codex on 26/05/26.
//

import Foundation

extension String {

    var resolvedMediaURL: URL? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if let url = URL(string: trimmed), url.scheme != nil {
            return url
        }

        let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed) ?? trimmed
        if let url = URL(string: encoded), url.scheme != nil {
            return url
        }

        if trimmed.hasPrefix("/") {
            return URL(string: trimmed, relativeTo: URL(string: "https://ljdit.com"))?.absoluteURL
        }

        return URL(string: "/" + trimmed, relativeTo: URL(string: "https://ljdit.com"))?.absoluteURL
    }
}
