// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

class MastodonEncoder: JSONEncoder {
    override init() {
        super.init()

        let dateFormatter = DateFormatter()

        dateFormatter.dateFormat = MastodonAPI.dateFormat
        dateEncodingStrategy = .formatted(dateFormatter)
        keyEncodingStrategy = .convertToSnakeCase
        outputFormatting = .sortedKeys
    }
}
