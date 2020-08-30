// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

public class MastodonEncoder: JSONEncoder {
    public override init() {
        super.init()

        let dateFormatter = DateFormatter()

        dateFormatter.dateFormat = Constants.dateFormat
        dateEncodingStrategy = .formatted(dateFormatter)
        keyEncodingStrategy = .convertToSnakeCase
        outputFormatting = .sortedKeys
    }
}
