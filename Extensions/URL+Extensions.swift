// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

extension URL {
    var isHTTPURL: Bool {
        guard let scheme = scheme else { return false }

        return scheme == "http" || scheme == "https"
    }
}

extension URL: Identifiable {
    public var id: String { absoluteString }
}
