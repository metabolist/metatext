// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import Mastodon

public struct Profile: Codable, Hashable {
    public let account: Account
    public let relationship: Relationship?
    public let identityProofs: [IdentityProof]

    public init(account: Account) {
        self.account = account
        self.relationship = nil
        self.identityProofs = []
    }
}

extension Profile {
    init(info: ProfileInfo) {
        account = Account(info: info.accountInfo)
        relationship = info.relationship
        identityProofs = info.identityProofRecords.map(IdentityProof.init(record:))
    }
}
