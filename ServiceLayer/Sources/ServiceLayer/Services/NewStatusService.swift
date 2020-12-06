// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import DB
import Foundation
import Mastodon
import MastodonAPI
import Secrets

public struct NewStatusService {
    private var id: Identity.Id
    private let identityDatabase: IdentityDatabase
    private let environment: AppEnvironment

    public init(id: Identity.Id, identityDatabase: IdentityDatabase, environment: AppEnvironment) {
        self.id = id
        self.identityDatabase = identityDatabase
        self.environment = environment
    }
}

extension NewStatusService {
    func mastodonAPIClient() throws -> MastodonAPIClient {
        let secrets = Secrets(
            identityId: id,
            keychain: environment.keychain)
        let mastodonAPIClient = MastodonAPIClient(
            session: environment.session,
            instanceURL: try secrets.getInstanceURL())

        mastodonAPIClient.accessToken = try secrets.getAccessToken()

        return mastodonAPIClient
    }
}
