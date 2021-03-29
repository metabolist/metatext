// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

public struct Mention: Codable, Hashable {
    public let url: UnicodeURL
    public let username: String
    public let acct: String
    public let id: Account.Id
}
