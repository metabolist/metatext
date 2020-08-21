// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

struct Account: Codable, Hashable {
    struct Field: Codable, Hashable {
        let name: String
        let value: HTML
        let verifiedAt: Date?
    }

    let id: String
    let username: String
    let acct: String
    let displayName: String
    let locked: Bool
    let createdAt: Date
    let followersCount: Int
    let followingCount: Int
    let statusesCount: Int
    let note: HTML
    let url: URL
    let avatar: URL
    let avatarStatic: URL
    let header: URL
    let headerStatic: URL
    let fields: [Field]
    let emojis: [Emoji]
    let bot: Bool?
    let moved: Bool?
    let discoverable: Bool?
}
