// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import Mastodon
import Stubbing

extension InstanceEndpoint: Stubbing {
    public func data(url: URL) -> Data? {
        switch self {
        case .instance: return try? Data(contentsOf: Bundle.module.url(forResource: "instance", withExtension: "json")!)
        }
    }
}
