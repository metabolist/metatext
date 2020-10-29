// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

public struct Conversation: Codable, Hashable {
    public let id: Id
    public let accounts: [Account]
    public let unread: Bool
    public let lastStatus: Status?

    public init(id: String, accounts: [Account], unread: Bool, lastStatus: Status?) {
        self.id = id
        self.accounts = accounts
        self.unread = unread
        self.lastStatus = lastStatus
    }
}

public extension Conversation {
    typealias Id = String
}
