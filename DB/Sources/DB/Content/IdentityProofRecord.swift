// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import GRDB
import Mastodon

struct IdentityProofRecord: ContentDatabaseRecord, Hashable {
    let accountId: Account.Id
    let provider: String
    let providerUsername: String
    let profileUrl: URL
    let proofUrl: URL
    let updatedAt: Date
}

extension IdentityProofRecord {
    enum Columns {
        static let accountId = Column(IdentityProofRecord.CodingKeys.accountId)
        static let provider = Column(IdentityProofRecord.CodingKeys.provider)
        static let providerUsername = Column(IdentityProofRecord.CodingKeys.providerUsername)
        static let profileUrl = Column(IdentityProofRecord.CodingKeys.profileUrl)
        static let proofUrl = Column(IdentityProofRecord.CodingKeys.proofUrl)
        static let updatedAt = Column(IdentityProofRecord.CodingKeys.updatedAt)
    }
}
