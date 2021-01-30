// Copyright © 2021 Metabolist. All rights reserved.

import Combine
import Foundation
import Mastodon
import MastodonAPI

public struct InstanceService {
    public let instance: Instance

    private let mastodonAPIClient: MastodonAPIClient

    init(instance: Instance, mastodonAPIClient: MastodonAPIClient) {
        self.instance = instance
        self.mastodonAPIClient = mastodonAPIClient
    }
}
