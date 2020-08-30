// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

public class MastodonDecoder: JSONDecoder {
    public override init() {
        super.init()

        let dateFormatter = DateFormatter()

        dateFormatter.dateFormat = Constants.dateFormat
        dateDecodingStrategy = .formatted(dateFormatter)
        keyDecodingStrategy = .convertFromSnakeCase
    }
}
