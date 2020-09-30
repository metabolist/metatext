// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import GRDB
import Mastodon

struct IdentityInfo: Codable, Hashable, FetchableRecord {
    let record: IdentityRecord
    let instance: Identity.Instance?
    let account: Identity.Account?
}

extension IdentityInfo {
    static func addingIncludes<T: DerivableRequest>(_ request: T) -> T where T.RowDecoder == IdentityRecord {
        request.including(optional: IdentityRecord.instance.forKey(CodingKeys.instance))
            .including(optional: IdentityRecord.account.forKey(CodingKeys.account))
    }

    static func request(_ request: QueryInterfaceRequest<IdentityRecord>) -> QueryInterfaceRequest<Self> {
        addingIncludes(request).asRequest(of: self)
    }
}
