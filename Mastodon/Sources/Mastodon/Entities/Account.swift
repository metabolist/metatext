// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

public struct Account: Codable, Hashable {
    public struct Field: Codable, Hashable {
        public let name: String
        public let value: HTML
        public let verifiedAt: Date?
    }

    public let id: String
    public let username: String
    public let acct: String
    public let displayName: String
    public let locked: Bool
    public let createdAt: Date
    public let followersCount: Int
    public let followingCount: Int
    public let statusesCount: Int
    public let note: HTML
    public let url: URL
    public let avatar: URL
    public let avatarStatic: URL
    public let header: URL
    public let headerStatic: URL
    public let fields: [Field]
    public let emojis: [Emoji]
    @DecodableDefault.False public private(set) var bot: Bool
    @DecodableDefault.False public private(set) var discoverable: Bool
}
