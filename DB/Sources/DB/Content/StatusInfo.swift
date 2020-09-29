// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import GRDB

struct StatusInfo: Codable, Hashable, FetchableRecord {
    let account: AccountRecord
    let accountMoved: AccountRecord?
    let status: StatusRecord
    let reblogAccount: AccountRecord?
    let reblogAccountMoved: AccountRecord?
    let reblog: StatusRecord?
}

extension StatusInfo {
    static func request(_ request: QueryInterfaceRequest<StatusRecord>) -> QueryInterfaceRequest<Self> {
        request.including(required: StatusRecord.account.forKey(CodingKeys.account))
            .including(optional: StatusRecord.accountMoved.forKey(CodingKeys.accountMoved))
            .including(optional: StatusRecord.reblogAccount.forKey(CodingKeys.reblogAccount))
            .including(optional: StatusRecord.reblogAccountMoved.forKey(CodingKeys.reblogAccountMoved))
            .including(optional: StatusRecord.reblog.forKey(CodingKeys.reblog))
            .asRequest(of: self)
    }

    var accountInfo: AccountInfo {
        AccountInfo(account: account, moved: accountMoved)
    }

    var reblogAccountInfo: AccountInfo? {
        guard let reblogAccount = reblogAccount else { return nil }

        return AccountInfo(account: reblogAccount, moved: reblogAccountMoved)
    }
}
