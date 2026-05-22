//
//  ConnectionStatus.swift
//  Maruyama's Publising Assistant
//
//  Created by LJD Technology on 01/05/26.
//

import Foundation

struct ConnectionStatus {
    let isConnected: Bool
    let facebookConnected: Bool
    let instagramConnected: Bool
    let facebookPageId: String?
    let instagramUserId: String?
    let distributorId: Int?
    let message: String?

    init(
        isConnected: Bool,
        facebookConnected: Bool = false,
        instagramConnected: Bool = false,
        facebookPageId: String? = nil,
        instagramUserId: String? = nil,
        distributorId: Int? = nil,
        message: String? = nil
    ) {
        self.isConnected = isConnected
        self.facebookConnected = facebookConnected
        self.instagramConnected = instagramConnected
        self.facebookPageId = facebookPageId
        self.instagramUserId = instagramUserId
        self.distributorId = distributorId
        self.message = message
    }

    var metaTokenConfigured: Bool {
        isConnected || facebookPageId != nil || instagramUserId != nil
    }
}

struct ScheduledPost: Identifiable, Hashable {
    let id: String
    let message: String
    let scheduledPublishTime: Date?
    let createdTime: Date?
    let permalinkUrl: String?
}

struct PublishingHealthStatus: Hashable {
    let status: String
    let service: String
    let timestamp: String?
}
