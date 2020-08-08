// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

class MastodonDecoder: JSONDecoder {
    override init() {
        super.init()

        let dateFormatter = DateFormatter()

        dateFormatter.dateFormat = MastodonAPI.dateFormat
        dateDecodingStrategy = .formatted(dateFormatter)
        keyDecodingStrategy = .convertFromSnakeCase
    }
}
