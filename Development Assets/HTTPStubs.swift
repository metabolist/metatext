// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import HTTP

struct HTTPStubs {
    static func stub(
        request: URLRequest,
        target: Target? = nil,
        userInfo: [String: Any] = [:]) -> HTTPStub? {
        guard let url = request.url else {
            return nil
        }

        return (target as? Stubbing)?.stub(url: url)
    }
}
