// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import GRDB
import Mastodon

struct StatusResult: Codable, Hashable, FetchableRecord {
    let account: Account
    let status: StoredStatus
    let reblogAccount: Account?
    let reblog: StoredStatus?
}

extension QueryInterfaceRequest where RowDecoder == StoredStatus {
    var statusResultRequest: QueryInterfaceRequest<StatusResult> {
        including(required: StoredStatus.account)
        .including(optional: StoredStatus.reblogAccount)
        .including(optional: StoredStatus.reblog)
        .asRequest(of: StatusResult.self)
    }
}
