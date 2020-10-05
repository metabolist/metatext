// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import Mastodon

public struct IdentityFixture {
    public let id: Identity.Id
    public let instanceURL: URL
    public let instance: Instance?
    public let account: Account?

    public init(id: Identity.Id, instanceURL: URL, instance: Instance?, account: Account?) {
        self.id = id
        self.instanceURL = instanceURL
        self.instance = instance
        self.account = account
    }
}
