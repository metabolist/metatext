// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

extension URL {
    var isHTTPURL: Bool {
        guard let scheme = scheme else { return false }

        return scheme == "http" || scheme == "https"
    }

    init?(stringEscapingPath: String) {
        guard let pathEscaped = stringEscapingPath.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)
        else { return nil }

        let httpsColonUnescaped = pathEscaped.replacingOccurrences(
            of: "https%3A",
            with: "https:",
            range: pathEscaped.range(of: "https%3A"))

        self.init(string: httpsColonUnescaped)
    }
}

extension URL: Identifiable {
    public var id: String { absoluteString }
}
