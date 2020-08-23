// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

struct Poll: Codable, Hashable {
    struct Option: Codable, Hashable {
        var title: String
        var votesCount: Int
    }

    let id: String
    let expiresAt: Date
    let expired: Bool
    let multiple: Bool
    let votesCount: Int
    let votersCount: Int?
    @DecodableDefault.False private(set) var voted: Bool
    @DecodableDefault.EmptyList private(set) var ownVotes: [Int]
    let options: [Option]
    let emojis: [Emoji]
}
