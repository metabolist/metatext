// Copyright © 2021 Metabolist. All rights reserved.

import Foundation
import GRDB

public struct AccountList: ContentDatabaseRecord, Hashable {
    let id: Id
}

public extension AccountList {
    typealias Id = String
}

extension AccountList {
    enum Columns {
        static let id = Column(CodingKeys.id)
    }

    static let accountListJoins = hasMany(AccountListJoin.self)
    static let accounts = hasMany(
        AccountRecord.self,
        through: accountListJoins.order(AccountListJoin.Columns.order),
        using: AccountListJoin.account)
}
