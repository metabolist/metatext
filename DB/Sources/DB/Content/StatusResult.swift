// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import GRDB
import Mastodon

struct StatusResult: Codable, Hashable, FetchableRecord {
    let account: StoredAccount
    let accountMoved: StoredAccount?
    let status: StoredStatus
    let reblogAccount: StoredAccount?
    let reblogAccountMoved: StoredAccount?
    let reblog: StoredStatus?
}

extension StatusResult {
    var accountResult: AccountResult {
        AccountResult(account: account, moved: accountMoved)
    }

    var reblogAccountResult: AccountResult? {
        guard let reblogAccount = reblogAccount else { return nil }

        return AccountResult(account: reblogAccount, moved: reblogAccountMoved)
    }
}

extension QueryInterfaceRequest where RowDecoder == StoredStatus {
    var statusResultRequest: AnyFetchRequest<StatusResult> {
        AnyFetchRequest(including(required: StoredStatus.account)
                            .including(optional: StoredStatus.accountMoved)
                            .including(optional: StoredStatus.reblogAccount)
                            .including(optional: StoredStatus.reblogAccountMoved)
                            .including(optional: StoredStatus.reblog))
            .asRequest(of: StatusResult.self)
    }
}
