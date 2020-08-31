// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import Mastodon
import Stubbing

extension PreferencesEndpoint: Stubbing {
    public func dataString(url: URL) -> String? {
        switch self {
        case .preferences:
            return """
            {
              "posting:default:visibility": "public",
              "posting:default:sensitive": false,
              "posting:default:language": null,
              "reading:expand:media": "default",
              "reading:expand:spoilers": false
            }
            """
        }
    }
}
