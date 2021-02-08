// Copyright © 2021 Metabolist. All rights reserved.

import Foundation
import GRDB
import Mastodon

struct AccountAndRelationshipInfo: Codable, Hashable, FetchableRecord {
    let accountInfo: AccountInfo
    let relationship: Relationship?
}

extension AccountAndRelationshipInfo {
    static func addingIncludes<T: DerivableRequest>(_ request: T) -> T where T.RowDecoder == AccountRecord {
        AccountInfo.addingIncludes(request).including(optional: AccountRecord.relationship)
    }

    static func request(_ request: QueryInterfaceRequest<AccountRecord>) -> QueryInterfaceRequest<Self> {
        addingIncludes(request).asRequest(of: self)
    }
}
