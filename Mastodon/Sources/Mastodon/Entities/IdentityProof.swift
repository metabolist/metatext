// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

public struct IdentityProof: Codable, Hashable {
    public let provider: String
    public let providerUsername: String
    public let profileUrl: UnicodeURL
    public let proofUrl: UnicodeURL
    public let updatedAt: Date

    public init(provider: String,
                providerUsername: String,
                profileUrl: UnicodeURL,
                proofUrl: UnicodeURL,
                updatedAt: Date) {
        self.provider = provider
        self.providerUsername = providerUsername
        self.profileUrl = profileUrl
        self.proofUrl = proofUrl
        self.updatedAt = updatedAt
    }
}
