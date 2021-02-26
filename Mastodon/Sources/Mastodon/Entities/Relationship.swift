// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

public struct Relationship: Codable, Hashable {
    public let id: Account.Id
    public let following: Bool
    public let requested: Bool
    @DecodableDefault.False public private(set) var endorsed: Bool
    public let followedBy: Bool
    public let muting: Bool
    @DecodableDefault.False public private(set) var mutingNotifications: Bool
    @DecodableDefault.False public private(set) var showingReblogs: Bool
    public let notifying: Bool?
    public let blocking: Bool
    public let domainBlocking: Bool
    @DecodableDefault.False public private(set) var blockedBy: Bool
    @DecodableDefault.EmptyString public private(set) var note: String
}
