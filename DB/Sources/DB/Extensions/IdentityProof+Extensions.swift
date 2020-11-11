// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import GRDB
import Mastodon

extension IdentityProof {
    init(record: IdentityProofRecord) {
        self.init(
            provider: record.provider,
            providerUsername: record.providerUsername,
            profileUrl: record.profileUrl,
            proofUrl: record.proofUrl,
            updatedAt: record.updatedAt)
    }
}
