// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import Mastodon
import Stubbing

extension AccessTokenEndpoint: Stubbing {
    public func dataString(url: URL) -> String? {
        switch self {
        case let .oauthToken(_, _, _, _, scopes, _):
            return """
            {
              "access_token": "ACCESS_TOKEN_STUB_VALUE",
              "token_type": "Bearer",
              "scope": "\(scopes)",
              "created_at": "\(Int(Date().timeIntervalSince1970))"
            }
            """
        }
    }
}
