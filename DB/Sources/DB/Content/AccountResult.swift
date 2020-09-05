// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import GRDB
import Mastodon

struct AccountResult: Codable, Hashable, FetchableRecord {
    let account: StoredAccount
    let moved: StoredAccount?
}

extension QueryInterfaceRequest where RowDecoder == StoredAccount {
    var accountResultRequest: AnyFetchRequest<AccountResult> {
        AnyFetchRequest(including(optional: StoredAccount.moved))
            .asRequest(of: AccountResult.self)
    }
}
