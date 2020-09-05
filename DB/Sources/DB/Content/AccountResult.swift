// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import GRDB
import Mastodon

struct AccountResult: Codable, Hashable, FetchableRecord {
    let account: AccountRecord
    let moved: AccountRecord?
}

extension QueryInterfaceRequest where RowDecoder == AccountRecord {
    var accountResultRequest: AnyFetchRequest<AccountResult> {
        AnyFetchRequest(including(optional: AccountRecord.moved))
            .asRequest(of: AccountResult.self)
    }
}
