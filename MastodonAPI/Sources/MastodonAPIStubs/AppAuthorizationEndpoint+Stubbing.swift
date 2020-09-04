// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import MastodonAPI
import Stubbing

extension AppAuthorizationEndpoint: Stubbing {
    public func dataString(url: URL) -> String? {
        switch self {
        case let .apps(clientName, redirectURI, _, _):
            return """
            {
              "id": "\(Int.random(in: 100000...999999))",
              "name": "\(clientName)",
              "website": null,
              "redirect_uri": "\(redirectURI)",
              "client_id": "AUTHORIZATION_CLIENT_ID_STUB_VALUE",
              "client_secret": "AUTHORIZATION_CLIENT_SECRET_STUB_VALUE",
              "vapid_key": "AUTHORIZATION_VAPID_KEY_STUB_VALUE"
            }
            """
        }
    }
}
