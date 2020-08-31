// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import Mastodon
import Stubbing

extension ContextEndpoint: Stubbing {
    public func dataString(url: URL) -> String? {
        switch self {
        case .context:
            return """
            {
              "ancestors": [],
              "descendants": []
            }
            """
        }
    }
}
