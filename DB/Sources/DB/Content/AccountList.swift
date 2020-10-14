// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import GRDB

public struct AccountList: ContentDatabaseRecord {
    let id: Id

    public init() {
        id = Id()
    }
}

public extension AccountList {
    typealias Id = UUID
}

extension AccountList {
    static let joins = hasMany(AccountListJoin.self).order(AccountListJoin.Columns.index)
    static let accounts = hasMany(
        AccountRecord.self,
        through: joins,
        using: AccountListJoin.account)

    var accounts: QueryInterfaceRequest<AccountInfo> {
        AccountInfo.request(request(for: Self.accounts))
    }
}
