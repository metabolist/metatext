// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import Mastodon

extension Target: Stubbing {
    func stub(url: URL) -> HTTPStub? {
        (endpoint as? Stubbing)?.stub(url: url)
    }

    func data(url: URL) -> Data? {
        (endpoint as? Stubbing)?.data(url: url)
    }

    func dataString(url: URL) -> String? {
        (endpoint as? Stubbing)?.dataString(url: url)
    }

    func statusCode(url: URL) -> Int? {
        (endpoint as? Stubbing)?.statusCode(url: url)
    }
}
