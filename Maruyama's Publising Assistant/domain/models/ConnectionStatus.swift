//
//  ConnectionStatus.swift
//  Maruyama's Publising Assistant
//
//  Created by LJD Technology on 01/05/26.
//

struct ConnectionStatus {
    let isConnected: Bool
    let facebookConnected: Bool
    let instagramConnected: Bool
    let facebookPageId: String?
    let instagramUserId: String?
    let userId: Int?
    let message: String?

    init(
        isConnected: Bool,
        facebookConnected: Bool = false,
        instagramConnected: Bool = false,
        facebookPageId: String? = nil,
        instagramUserId: String? = nil,
        userId: Int? = nil,
        message: String? = nil
    ) {
        self.isConnected = isConnected
        self.facebookConnected = facebookConnected
        self.instagramConnected = instagramConnected
        self.facebookPageId = facebookPageId
        self.instagramUserId = instagramUserId
        self.userId = userId
        self.message = message
    }

    var metaTokenConfigured: Bool {
        isConnected || facebookPageId != nil || instagramUserId != nil
    }
}
