// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

public struct MastodonError: Error, Codable {
    public let error: String
}

extension MastodonError: LocalizedError {
    public var errorDescription: String? { error }
}
