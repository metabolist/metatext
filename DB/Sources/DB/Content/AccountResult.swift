// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import GRDB

struct AccountResult: Codable, Hashable, FetchableRecord {
    let account: AccountRecord
    let moved: AccountRecord?
}

extension AccountResult {
    static func request(_ request: QueryInterfaceRequest<AccountRecord>) -> QueryInterfaceRequest<Self> {
        request.including(optional: AccountRecord.moved.forKey(CodingKeys.moved)).asRequest(of: self)
    }
}
