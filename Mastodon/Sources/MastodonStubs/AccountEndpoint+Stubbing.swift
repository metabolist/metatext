// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import Mastodon
import Stubbing

extension AccountEndpoint: Stubbing {
    public func data(url: URL) -> Data? {
        switch self {
        case .verifyCredentials: return try? Data(contentsOf: Bundle.module.url(forResource: "account", withExtension: "json")!)
        }
    }
}
