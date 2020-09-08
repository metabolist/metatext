// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import MastodonAPI
import Stubbing

extension AccountEndpoint: Stubbing {
    public func data(url: URL) -> Data? {
        StubData.account
    }
}
