// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import MastodonAPI
import Stubbing

extension MastodonAPITarget: Stubbing {
    public func stub(url: URL) -> HTTPStub? {
        (endpoint as? Stubbing)?.stub(url: url)
    }

    public func data(url: URL) -> Data? {
        (endpoint as? Stubbing)?.data(url: url)
    }

    public func dataString(url: URL) -> String? {
        (endpoint as? Stubbing)?.dataString(url: url)
    }

    public func statusCode(url: URL) -> Int? {
        (endpoint as? Stubbing)?.statusCode(url: url)
    }
}
