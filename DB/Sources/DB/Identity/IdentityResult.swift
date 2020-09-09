// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import GRDB
import Mastodon

struct IdentityResult: Codable, Hashable, FetchableRecord {
    let identity: IdentityRecord
    let instance: Identity.Instance?
    let account: Identity.Account?
}

extension QueryInterfaceRequest where RowDecoder == IdentityRecord {
    var identityResultRequest: QueryInterfaceRequest<IdentityResult> {
        including(optional: IdentityRecord.instance)
            .including(optional: IdentityRecord.account)
            .asRequest(of: IdentityResult.self)
    }
}
