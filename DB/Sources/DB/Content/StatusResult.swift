// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import GRDB

struct StatusResult: Codable, Hashable, FetchableRecord {
    let account: AccountRecord
    let accountMoved: AccountRecord?
    let status: StatusRecord
    let reblogAccount: AccountRecord?
    let reblogAccountMoved: AccountRecord?
    let reblog: StatusRecord?
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

extension QueryInterfaceRequest where RowDecoder == StatusRecord {
    var statusResultRequest: QueryInterfaceRequest<StatusResult> {
        including(required: StatusRecord.account)
            .including(optional: StatusRecord.accountMoved)
            .including(optional: StatusRecord.reblogAccount)
            .including(optional: StatusRecord.reblogAccountMoved)
            .including(optional: StatusRecord.reblog)
            .asRequest(of: StatusResult.self)
    }
}
