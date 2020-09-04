// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import MastodonAPI
import Stubbing

extension TimelinesEndpoint: Stubbing {
    public func data(url: URL) -> Data? {
        try? Data(contentsOf: Bundle.module.url(forResource: "timeline", withExtension: "json")!)
    }
}
