// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

extension String {
    private static let colonDoubleSlash = "://"

    func url(scheme: String = "https") throws -> URL {
        let url: URL?

        if hasPrefix(scheme + Self.colonDoubleSlash) {
            url = URL(string: self)
        } else {
            url = URL(string: scheme + Self.colonDoubleSlash + self)
        }

        guard let validURL = url else { throw URLError(.badURL) }

        return validURL
    }
}
