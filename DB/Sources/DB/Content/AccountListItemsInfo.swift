// Copyright © 2021 Metabolist. All rights reserved.

import Foundation
import GRDB
import Mastodon

struct AccountListItemsInfo: Codable, Hashable, FetchableRecord {
    let accountList: AccountList
    let accountAndRelationshipInfos: [AccountAndRelationshipInfo]
}

extension AccountListItemsInfo {
    static func addingIncludes<T: DerivableRequest>(_ request: T) -> T where T.RowDecoder == AccountList {
        request.including(all: AccountAndRelationshipInfo.addingIncludes(AccountList.accounts)
                            .forKey(CodingKeys.accountAndRelationshipInfos))
    }

    static func request(_ request: QueryInterfaceRequest<AccountList>) -> QueryInterfaceRequest<Self> {
        addingIncludes(request).asRequest(of: self)
    }
}
