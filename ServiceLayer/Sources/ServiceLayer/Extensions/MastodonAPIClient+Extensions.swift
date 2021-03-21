// Copyright © 2021 Metabolist. All rights reserved.

import MastodonAPI
import Secrets

extension MastodonAPIClient {
    static func forIdentity(id: Identity.Id, environment: AppEnvironment) throws -> Self {
        let secrets = Secrets(identityId: id, keychain: environment.keychain)

        let client = Self(session: environment.session, instanceURL: try secrets.getInstanceURL())

        client.accessToken = try secrets.getAccessToken()

        return client
    }
}
