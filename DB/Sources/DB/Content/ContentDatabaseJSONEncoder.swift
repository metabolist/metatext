// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import Mastodon

final class ContentDatabaseJSONEncoder: JSONEncoder {
    override init() {
        super.init()

        keyEncodingStrategy = .convertToSnakeCase
        outputFormatting = .sortedKeys
        dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()

            try container.encode(MastodonDecoder.dateFormatter.string(from: date))
        }
    }
}
