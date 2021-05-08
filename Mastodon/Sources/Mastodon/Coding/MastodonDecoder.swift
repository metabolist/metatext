// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

public final class MastodonDecoder: JSONDecoder {
    public override init() {
        super.init()

        keyDecodingStrategy = .convertFromSnakeCase
        dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)

            guard let date = Self.dateFormatter.date(from: dateString)
                    ?? Self.dateFormatterWithoutFractionalSeconds.date(from: dateString) else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unable to parse ISO8601 date")
            }

            return date
        }
    }
}

public extension MastodonDecoder {
    static let dateFormatter: ISO8601DateFormatter = {
        let dateFormatter = ISO8601DateFormatter()

        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        return dateFormatter
    }()

    static let dateFormatterWithoutFractionalSeconds: ISO8601DateFormatter = {
        let dateFormatter = ISO8601DateFormatter()

        dateFormatter.formatOptions = [.withInternetDateTime]

        return dateFormatter
    }()
}
