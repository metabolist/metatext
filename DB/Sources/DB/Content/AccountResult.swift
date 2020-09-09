// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import GRDB

struct AccountResult: Codable, Hashable, FetchableRecord {
    let account: AccountRecord
    let moved: AccountRecord?
}

extension QueryInterfaceRequest where RowDecoder == AccountRecord {
    var accountResultRequest: QueryInterfaceRequest<AccountResult> {
        including(optional: AccountRecord.moved)
            .asRequest(of: AccountResult.self)
    }
}
