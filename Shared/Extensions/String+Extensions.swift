// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

extension String {
    private static let HTTPSPrefix = "https://"

    func url() throws -> URL {
        let url: URL?

        if hasPrefix(Self.HTTPSPrefix) {
            url = URL(string: self)
        } else {
            url = URL(string: Self.HTTPSPrefix + self)
        }

        guard let validURL = url else { throw URLError(.badURL) }

        return validURL
    }
}
