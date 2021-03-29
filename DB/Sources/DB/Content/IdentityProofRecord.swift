// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import GRDB
import Mastodon

struct IdentityProofRecord: ContentDatabaseRecord, Hashable {
    let accountId: Account.Id
    let provider: String
    let providerUsername: String
    let profileUrl: UnicodeURL
    let proofUrl: UnicodeURL
    let updatedAt: Date
}

extension IdentityProofRecord {
    enum Columns {
        static let accountId = Column(CodingKeys.accountId)
        static let provider = Column(CodingKeys.provider)
        static let providerUsername = Column(CodingKeys.providerUsername)
        static let profileUrl = Column(CodingKeys.profileUrl)
        static let proofUrl = Column(CodingKeys.proofUrl)
        static let updatedAt = Column(CodingKeys.updatedAt)
    }
}
