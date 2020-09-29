// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import GRDB
import Mastodon

struct IdentityResult: Codable, Hashable, FetchableRecord {
    let identity: IdentityRecord
    let instance: Identity.Instance?
    let account: Identity.Account?
}

extension IdentityResult {
    static func request(_ request: QueryInterfaceRequest<IdentityRecord>) -> QueryInterfaceRequest<Self> {
        request.including(optional: IdentityRecord.instance.forKey(CodingKeys.instance))
            .including(optional: IdentityRecord.account.forKey(CodingKeys.account))
            .asRequest(of: self)
    }
}
