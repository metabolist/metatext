// Copyright © 2021 Metabolist. All rights reserved.

import Combine
import Foundation
import Mastodon

public struct TagViewModel {
    public let identityContext: IdentityContext

    private let tag: Tag

    init(tag: Tag, identityContext: IdentityContext) {
        self.tag = tag
        self.identityContext = identityContext
    }
}

public extension TagViewModel {
    var name: String { "#".appending(tag.name) }

    var accounts: Int? {
        guard let history = tag.history,
              let accountsString = history.first?.accounts,
              var accounts = Int(accountsString)
        else { return nil }

        if history.count > 1, let secondDayAccounts = Int(history[1].accounts) {
            accounts += secondDayAccounts
        }

        return accounts
    }

    var uses: Int? {
        guard let history = tag.history,
              let usesString = history.first?.uses,
              var uses = Int(usesString)
        else { return nil }

        if history.count > 1, let secondDayUses = Int(history[1].uses) {
            uses += secondDayUses
        }

        return uses
    }

    var usageHistory: [Int] {
        tag.history?.compactMap { Int($0.uses) } ?? []
    }
}
