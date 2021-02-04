// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

public struct MastodonNotification: Codable, Hashable {
    public let id: Id
    public let type: NotificationType
    public let account: Account
    public let createdAt: Date
    public let status: Status?

    public init(id: String,
                type: MastodonNotification.NotificationType,
                account: Account,
                createdAt: Date,
                status: Status?) {
        self.id = id
        self.type = type
        self.account = account
        self.createdAt = createdAt
        self.status = status
    }
}

public extension MastodonNotification {
    typealias Id = String

    enum NotificationType: String, Codable, Unknowable {
        case follow
        case mention
        case reblog
        case favourite
        case poll
        case followRequest = "follow_request"
        case status
        case unknown

        public static var unknownCase: Self { .unknown }
    }
}

extension MastodonNotification.NotificationType: Identifiable {
    public var id: Self { self }
}
