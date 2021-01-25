// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

public struct Results: Codable {
    public let accounts: [Account]
    public let statuses: [Status]
    public let hashtags: [Tag]
}

public extension Results {
    static let empty = Self(accounts: [], statuses: [], hashtags: [])

    func appending(_ results: Self) -> Self {
        let accountIds = Set(accounts.map(\.id))
        let statusIds = Set(statuses.map(\.id))
        let tagNames = Set(hashtags.map(\.name))

        return Self(
            accounts: accounts + results.accounts.filter { !accountIds.contains($0.id) },
            statuses: statuses + results.statuses.filter { !statusIds.contains($0.id) },
            hashtags: hashtags + results.hashtags.filter { !tagNames.contains($0.name) })
    }
}
