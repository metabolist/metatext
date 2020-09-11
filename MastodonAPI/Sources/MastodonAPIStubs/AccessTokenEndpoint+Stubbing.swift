// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import MastodonAPI
import Stubbing

extension AccessTokenEndpoint: Stubbing {
    public func dataString(url: URL) -> String? {
        """
        {
          "access_token": "ACCESS_TOKEN_STUB_VALUE",
          "token_type": "Bearer",
          "scope": "ACCESS_TOKEN_STUB_VALUE_SCOPES",
          "created_at": "\(Int(Date().timeIntervalSince1970))"
        }
        """
    }
}
