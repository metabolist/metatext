// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import Mastodon

struct HTTPStubs {
    static func stub(
        request: URLRequest,
        target: HTTPTarget? = nil,
        userInfo: [String: Any] = [:]) -> HTTPStub? {
        guard let url = request.url else {
            return nil
        }

        return (target as? Stubbing)?.stub(url: url)
    }
}
