// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

extension ContextEndpoint: Stubbing {
    func dataString(url: URL) -> String? {
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
