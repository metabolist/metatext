// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import GRDB

struct AccountInfo: Codable, Hashable, FetchableRecord {
    let record: AccountRecord
    let movedRecord: AccountRecord?
}

extension AccountInfo {
    static func addingIncludes<T: DerivableRequest>(_ request: T) -> T where T.RowDecoder == AccountRecord {
        request.including(optional: AccountRecord.moved.forKey(CodingKeys.movedRecord))
    }

    static func request(_ request: QueryInterfaceRequest<AccountRecord>) -> QueryInterfaceRequest<Self> {
        addingIncludes(request).asRequest(of: self)
    }
}
