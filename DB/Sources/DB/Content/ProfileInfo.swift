// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import GRDB
import Mastodon

struct ProfileInfo: Codable, Hashable, FetchableRecord {
    let accountInfo: AccountInfo
    let relationship: Relationship?
    let identityProofRecords: [IdentityProofRecord]
    let featuredTagRecords: [FeaturedTagRecord]
}

extension ProfileInfo {
    static func addingIncludes<T: DerivableRequest>(_ request: T) -> T where T.RowDecoder == AccountRecord {
        AccountInfo.addingIncludes(request)
            .including(optional: AccountRecord.relationship.forKey(CodingKeys.relationship))
            .including(all: AccountRecord.identityProofs.forKey(CodingKeys.identityProofRecords))
            .including(all: AccountRecord.featuredTags.forKey(CodingKeys.featuredTagRecords))
    }

    static func request(_ request: QueryInterfaceRequest<AccountRecord>) -> QueryInterfaceRequest<Self> {
        addingIncludes(request).asRequest(of: self)
    }
}
